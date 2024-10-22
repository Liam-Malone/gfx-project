const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;

const wayland = @import("wayland.zig");
const wl_log = std.log.scoped(.Wayland);

/// Connect To Wayland Display
///
/// Assumes Arena Allocator -- does not manage own memory
fn connect_display(arena: Allocator) !std.net.Stream {
    const xdg_runtime_dir = std.posix.getenv("XDG_RUNTIME_DIR") orelse return error.NoXdgRuntime;
    const wayland_display = std.posix.getenv("WAYLAND_DISPLAY") orelse return error.NoWaylandDisplay;

    const display_path = try std.fs.path.join(arena, &.{ xdg_runtime_dir, wayland_display });
    wl_log.info("  Connect Display :: Attempting to connect to Wayland display at: {s}\n", .{display_path});
    const stream = try std.net.connectUnixSocket(display_path);
    return stream;
}

/// Wayland Wire communication
///
/// 4 Bytes: ID of resource to call methods on
/// 2 Bytes: method opcode
/// 2 Bytes: size of message
/// Follow with any arguments to method
const Header = packed struct {
    id: u32,
    op: u16,
    size: u16,

    const Size: u16 = @sizeOf(Header);
};

/// Wayland Wire Event
///
/// Composed of Header + Data Buffer
const Event = struct {
    header: Header,
    data: []const u8,
};

/// Event Iterator
///
/// Contains Data Stream & Shifting Buffer
const EventIt = struct {
    stream: std.net.Stream,
    buf: ShiftBuf = .{},

    /// Need to solve problem of reading a partial header or partial data stream
    /// Buffer -> [ _ _ _ _ _ ]
    /// Fill =>   [ x y z w x ]
    /// Read Event (xyzw)
    /// Shift =>  [ x _ _ _ _ ]
    /// Fill =>   [ x y z w u ]
    /// Read Event (xyzwu)
    ///
    /// Read into buffer happens from offset pointer
    /// Read from buffer happens from start of buffer
    const ShiftBuf = struct {
        data: [4096]u8 = undefined,
        start: usize = 0,
        end: usize = 0,

        pub fn shift(sb: *ShiftBuf) void {
            std.mem.copyForwards(u8, &sb.data, sb.data[sb.start..]);
            @memset(sb.data[sb.start + 1 ..], 0); // Just in case
            sb.end -= sb.start;
            sb.start = 0;
        }
    };

    pub fn init(stream: std.net.Stream) EventIt {
        return .{
            .stream = stream,
        };
    }

    pub fn load_events(iter: *EventIt) !void {
        wl_log.info("  Event Iterator :: Loading Events", .{});
        iter.buf.shift();
        const bytes_read: usize = try iter.stream.read(iter.buf.data[iter.buf.end..]); // This does not hang
        if (bytes_read == 0) {
            return error.RemoteClosed;
        }
        iter.buf.end += bytes_read;
    }

    pub fn next(iter: *EventIt) !?Event {
        while (true) {
            const buffered_ev = blk: {
                const header_end = iter.buf.start + Header.Size;
                if (header_end > iter.buf.end) {
                    break :blk null;
                }

                const header = std.mem.bytesToValue(Header, iter.buf.data[iter.buf.start..header_end]);

                const data_end = iter.buf.start + header.size;

                if (data_end > iter.buf.end) {
                    if (iter.buf.start == 0) return error.BufTooSmol;
                    break :blk null;
                }
                defer iter.buf.start = data_end;

                break :blk .{
                    .header = header,
                    .data = iter.buf.data[header_end..data_end],
                };
            };

            if (buffered_ev) |ev| return ev;

            const data_in_stream = blk: {
                var poll: [1]std.posix.pollfd = [_]std.posix.pollfd{.{
                    .fd = iter.stream.handle,
                    .events = std.posix.POLL.IN,
                    .revents = 0,
                }};
                const bytes_ready = try std.posix.poll(&poll, 1); // 0 seems to just never read successfully
                wl_log.info("  Event Iterator :: next.poll found {d} bytes ready", .{bytes_ready});
                break :blk bytes_ready > 0;
            };

            if (data_in_stream) {
                iter.load_events() catch |err| {
                    switch (err) {
                        error.RemoteClosed => wl_log.warn("  Event Iterator :: !stream closed! :: {any}", .{err}),
                        else => wl_log.warn("  Event Iterator :: Stream Read Error :: {any}", .{err}),
                    }
                    return null;
                };
            } else {
                return null;
            }
        }
    }
};

/// Display ID occupies 1 to begin with
/// Wayland IDs are required to always be 1 higher than the previously assigned ID
const WaylandID = struct {
    next_id: u32 = wayland.ObjectIDs.registry,

    pub fn next(self: *WaylandID) u32 {
        defer self.next_id += 1;
        return self.next_id;
    }
};

fn get_registry(stream_writer: std.net.Stream.Writer, new_id: u32) !void {
    const GetRegistryMessage = packed struct {
        header: Header,
        new_id: u32,

        pub const Size = @sizeOf(@This());
    };
    const msg: GetRegistryMessage = .{
        .header = .{
            .id = wayland.ObjectIDs.display,
            .op = wayland.OpCodes.display_get_registry,
            .size = GetRegistryMessage.Size,
        },
        .new_id = new_id,
    };

    const bytes = try stream_writer.write(std.mem.asBytes(&msg));
    std.debug.assert(bytes == GetRegistryMessage.Size);
}

fn registry_bind(stream_writer: std.net.Stream.Writer, name: u32, new_id: u32, version: u32) !void {
    const RegistryBindMsg = packed struct {
        name: u32,
        id: u32,
        version: u32,
        pub const Size: u16 = @sizeOf(@This());
    };

    const msg: RegistryBindMsg = .{
        .name = name,
        .id = new_id,
        .version = version,
    };

    const header: Header = .{
        .id = wayland.ObjectIDs.registry,
        .op = wayland.OpCodes.registry_bind,
        .size = Header.Size + RegistryBindMsg.Size,
    };

    try stream_writer.writeStruct(header);
    try stream_writer.writeStruct(msg);
}

/// Round value up to multiple of secons argument
/// Would like to find a less costly way to do this that actually works
fn round_up(val: anytype, mul: @TypeOf(val)) @TypeOf(val) {
    if (val == 0)
        return 0
    else
        return if (val % mul == 0)
            val
        else
            val + (mul - (val % mul));
}

const MsgParser = struct {
    buf: []const u8,

    pub fn get_u32(mp: *MsgParser) !u32 {
        if (mp.buf.len < 4) {
            return error.InvalidLength;
        }

        const val = std.mem.bytesToValue(u32, mp.buf[0..4]);
        mp.consume(4);
        return val;
    }

    pub fn get_i32(mp: *MsgParser) !i32 {
        return @intCast(try mp.get_u32());
    }

    pub fn get_string(mp: *MsgParser) ![]const u8 {
        if (mp.buf.len < 4) {
            return error.InvalidLength;
        }

        const msg_len = std.mem.bytesToValue(u32, mp.buf[0..4]);
        const rounded_len = round_up(msg_len, 4);
        const consume_len = rounded_len + 4;

        if (consume_len > mp.buf.len) {
            return error.InvalidLength;
        }

        const str = mp.buf[4 .. 4 + msg_len];
        mp.consume(consume_len);
        return str;
    }

    fn consume(mp: *MsgParser, len: usize) void {
        if (mp.buf.len == len) {
            mp.buf = &.{};
        } else {
            mp.buf = mp.buf[len..];
        }
    }
};

fn parse_data_response(comptime T: type, data: []const u8) !T {
    var ret: T = undefined;
    var iter: MsgParser = .{ .buf = data };
    inline for (std.meta.fields(T)) |field| {
        @field(ret, field.name) = switch (field.type) {
            u32 => try iter.get_u32(),
            []const u8 => blk: {
                const str = try iter.get_string();
                break :blk str[0 .. str.len - 1];
            },
            else => @compileLog("Data Parse Not Implemented for field {s} of type {}", .{ field.name, field.type }),
        };
    }
    return ret;
}
const DisplayError = struct {
    obj_id: u32,
    code: u32,
    msg: []const u8,

    fn init(data: []const u8) !DisplayError {
        var it: MsgParser = .{ .buf = data };
        return try .{
            .obj_id = try it.get_u32(),
            .code = try it.get_u32(),
            .msg = try it.get_string(),
        };
    }
};

const RegistryGlobal = struct {
    name: u32,
    interface: []const u8,
    version: u32,
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, Wayland!\n", .{});

    const arena_backer: Allocator = std.heap.page_allocator;
    var arena: Arena = .init(arena_backer);
    defer arena.deinit();
    const arena_allocator: Allocator = arena.allocator();

    const stream = try connect_display(arena_allocator);
    defer stream.close();
    const stream_writer = stream.writer();

    var res_iter: EventIt = .init(stream);

    var id: WaylandID = .{};
    try get_registry(stream_writer, id.next());

    var wl_shm_id: u32 = undefined;
    var wl_seat_id: u32 = undefined;
    var wl_compositor_id: u32 = undefined;
    var xdg_wm_base_id: u32 = undefined;
    // Bind Registry
    {
        while (try res_iter.next()) |ev| {
            switch (ev.header.id) {
                wayland.ObjectIDs.display => {
                    const err: DisplayError = try .init(ev.data);
                    wl_log.err("  Main :: Display Error: object id: {d}, errcode: {d}, msg: {s}", .{ err.obj_id, err.code, err.msg });
                },
                wayland.ObjectIDs.registry => {
                    switch (ev.header.op) {
                        0 => {
                            const global: RegistryGlobal = try parse_data_response(RegistryGlobal, ev.data);
                            wl_log.info("  wl_registry::global ==> name: {d}, interface: {s}, version: {d}", .{
                                global.name,
                                global.interface,
                                global.version,
                            });

                            if (std.mem.eql(u8, global.interface, "wl_seat")) {
                                wl_seat_id = id.next();
                                try registry_bind(stream_writer, global.name, wl_seat_id, 7);
                                wl_log.info("  wl_registry::global -- bound wl_seat with id: {d}\n", .{wl_seat_id});
                            } else if (std.mem.eql(u8, global.interface, "wl_compositor")) {
                                wl_compositor_id = id.next();
                                try registry_bind(stream_writer, global.name, wl_compositor_id, 5);
                                wl_log.info("  wl_registry::global -- bound compositor with id: {d}\n", .{wl_compositor_id});
                            } else if (std.mem.eql(u8, global.interface, "xdg_wm_base")) {
                                xdg_wm_base_id = id.next();
                                try registry_bind(stream_writer, global.name, xdg_wm_base_id, 6);
                                wl_log.info("  wl_registry::global -- bound xdg_wm_base with id: {d}\n", .{xdg_wm_base_id});
                            } else if (std.mem.eql(u8, global.interface, "wl_shm")) {
                                wl_shm_id = id.next();
                                try registry_bind(stream_writer, global.name, wl_shm_id, 1);
                                wl_log.info("  wl_registry::global -- bound wl_shm with id: {d}\n", .{wl_shm_id});
                            }
                        },
                        1 => wl_log.warn("  wl_registry::global_remove uninmplemented handler", .{}),
                        else => wl_log.warn("  wl_display :: unrecognized ev opcode: {d}", .{ev.header.op}),
                    }
                },
                else => wl_log.warn("  Main :: Event Iter :: Urecognized Header ID: {d}", .{ev.header.id}),
            }
        }
    }

    try stdout.print("Program Exiting Now!\n", .{});
}

// Next Steps:
// - [ ] Create Registry Globals For Following Interfaces:
//       - [ ] wl_shm
//       - [ ] wl_compositor
//       - [ ] xdg_wm_base
//       - [ ] wl_seat
// - [ ] Get Compositor Surface
// - [ ] Get Xdg_Surface
// - [ ] Get Toplevel of Xdg_Surface
//       - [ ] Set Toplevel Title
// - [ ] Commit Compositor Surface
// - [ ] memmap data over to display
// - [ ] XML Parser/Generator for Protocols
//       - [ ] Generate reasonable Structs / Enums / "Methods"
//       - [ ] Output "description" fields as Doc-Strings
