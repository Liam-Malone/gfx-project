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

    const Size = @sizeOf(Header);
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
            @memset(sb.data[sb.start..], 0); // Just in case
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
        wl_log.info("Event Iterator :: Loading Events", .{});
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
                    wl_log.warn("  Event Iterator :: Partial header encountered", .{});
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

const GetRegistryMessage = packed struct {
    header: Header,
    new_id: u32,

    pub const Size: usize = @sizeOf(GetRegistryMessage);
};
fn get_registry(stream_writer: std.net.Stream.Writer, new_id: u32) !void {
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

fn round_up(val: anytype, mul: @TypeOf(val)) @TypeOf(val) {
    return if (val == 0) 0 else ((val - 1 / mul + 1) * mul);
}

const MsgParser = struct {
    buf: []const u8,

    pub fn getU32(mp: *MsgParser) !u32 {
        if (mp.buf.len < 4) {
            return error.InvalidLength;
        }

        const val = std.mem.bytesToValue(u32, mp.buf[0..4]);
        mp.consume(4);
        return val;
    }
    pub fn getString(mp: *MsgParser) ![]const u8 {
        if (mp.buf.len < 4) {
            return error.InvalidLength;
        }

        const msg_len = std.mem.bytesToValue(u32, mp.buf[0..4]);
        const consume_len = 4 + msg_len;
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
            u32 => try iter.getU32(),
            []const u8 => try iter.getString(),
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
            .obj_id = try it.getU32(),
            .code = try it.getU32(),
            .msg = try it.getString(),
        };
    }
};

const RegistryGlobal = struct {
    name: u32,
    interface: []const u8,
    version: u32,
};

fn registry_global_handle(ev: Event) !void {
    switch (ev.header.op) {
        0 => {
            const global: RegistryGlobal = try parse_data_response(RegistryGlobal, ev.data);
            wl_log.info("  wl_registry::global ==> name: {d}, interface: {s}, version: {d}\n", .{
                global.name,
                global.interface,
                global.version,
            });
        },
        1 => wl_log.warn("  wl_registry::global_remove uninmplemented handler", .{}),
        else => wl_log.warn("  wl_display :: unrecognized ev opcode: {d}", .{ev.header.op}),
    }
}

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

    while (try res_iter.next()) |ev| {
        try stdout.print("  Main :: Header: ID -> {d}, OpCode -> {d}, size -> {d}\n", .{ ev.header.id, ev.header.op, ev.header.size });
        switch (ev.header.id) {
            wayland.ObjectIDs.display => {
                const err: DisplayError = try .init(ev.data);
                wl_log.err("  Main :: Display Error: object id: {d}, errcode: {d}, msg: {s}", .{ err.obj_id, err.code, err.msg });
            },
            wayland.ObjectIDs.registry => {
                try registry_global_handle(ev);
            },
            else => wl_log.warn("  Main :: Event Iter :: Urecognized Header ID: {d}", .{ev.header.id}),
        }
    }

    try stdout.print("Program Exiting Now!\n", .{});
}
