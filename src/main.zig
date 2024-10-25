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

/// Wayland Wire Communication Header
///
/// 4 Bytes: ID of resource to call methods on
/// 2 Bytes: method opcode
/// 2 Bytes: size of message
/// Follow with any arguments to method
const Header = packed struct {
    id: u32,
    op: u16,
    size: u16,

    pub const Size: u16 = @sizeOf(Header);
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

    /// This solves the problem of reading a partial header or partial data stream
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

        /// Remove already used bytes to allow space for next data read
        /// Any incomplete data is moved to the front, and all other bytes are zeroed out
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

    /// Calls `.shift()` on data buffer, and reads in new bytes from stream
    fn load_events(iter: *EventIt) !void {
        wl_log.info("  Event Iterator :: Loading Events", .{});
        iter.buf.shift();
        const bytes_read: usize = try iter.stream.read(iter.buf.data[iter.buf.end..]); // This does not hang
        if (bytes_read == 0) {
            return error.RemoteClosed;
        }
        iter.buf.end += bytes_read;
    }

    /// Get next message from stored buffer
    /// When the buffer is filled, the follwing call to `.next()` will overwrite all messages that have already been read
    ///
    /// See: `ShiftBuf.shift()`
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

/// Request the server to provide us the list of items in the registry
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

/// Bind registry objects with server
///
///   Message Contains:
///    -  Header:           Header
///    -  Object's name:    u32
///    -  Interface:        string (contains u32 at start to tell length, and padding to 32-bit alignment after)
///    -  Desired Version:  u32
///    -  ID to Bind:       u32
///
///   Message Size:
///    -  Header.Size
///    -  sizeof(u32) x 3
///    -  sizeof(padded str + sizeof(u32))
///
fn registry_bind(arena: *Arena, writer: std.net.Stream.Writer, global: RegistryGlobal, id: u32) !void {
    const alloc = arena.allocator();
    const sentinel_str = try alloc.dupeZ(u8, global.interface);
    defer alloc.free(sentinel_str);

    const msg_size = Header.Size + 12 + round_up(4 + global.interface.len, 4);
    var bytes_written: usize = 0;

    const header: Header = .{
        .id = wayland.ObjectIDs.registry,
        .op = wayland.OpCodes.registry_bind,
        .size = @intCast(msg_size),
    };

    try writer.writeStruct(header);
    bytes_written += Header.Size;
    bytes_written += try writer.write(std.mem.asBytes(&global.name));
    bytes_written += try write_str(writer, sentinel_str[0 .. sentinel_str.len + 1]);
    bytes_written += try writer.write(std.mem.asBytes(&global.version));
    bytes_written += try writer.write(std.mem.asBytes(&id));
    std.debug.print("Bytes Written: {d}  :: Bytes to write: {d}\n", .{ bytes_written, msg_size });
    std.debug.assert(bytes_written == msg_size);
}

fn wl_write(writer: std.io.Writer, item: anytype, id: u32, op: u32) !void {
    var msg_size: usize = Header.Size;
    inline for (std.meta.fields(@TypeOf(item))) |field| {
        switch (field.type) {
            u32, i32 => msg_size += 4,
            []const u8, [:0]const u8 => msg_size += round_up(@field(item, field.name).len, 4),
            else => @compileLog("Unsupported field {s} of type {}", .{ field.name, field.type }),
        }
    }
    const header: Header = .{
        .id = id,
        .op = op,
        .size = @intCast(msg_size),
    };

    try writer.writeStruct(header);

    const endian = builtin.cpu.arch.endian();
    inline for (std.meta.fields(@TypeOf(item))) |field| {
        switch (field.type) {
            .int => try writer.writeInt(@TypeOf(field), @field(item, field.name), endian),
            .pointer => try writer.write_str(writer, @field(item, field.name)),
            else => @compileLog("Unsupported field {s} of type {}", .{ field.name, field.type }),
        }
    }
    try writer.writeInt(u32, id, endian);
}

fn write_str(stream_writer: std.net.Stream.Writer, str: []const u8) !usize {
    const to_write: u32 = @intCast(round_up(4 + str.len, 4));
    try stream_writer.writeInt(u32, @intCast(str.len), builtin.cpu.arch.endian());
    try stream_writer.writeAll(str);
    const written = 4 + str.len;
    try stream_writer.writeByteNTimes(0, to_write - written);

    return to_write;
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

    pub fn get_string_sentinel(mp: *MsgParser) ![:0]const u8 {
        if (mp.buf.len < 4) {
            return error.InvalidLength;
        }

        const msg_len = std.mem.bytesToValue(u32, mp.buf[0..4]);
        const rounded_len = round_up(msg_len, 4);
        const consume_len = rounded_len + 4;

        if (consume_len > mp.buf.len) {
            return error.InvalidLength;
        }

        var buf = @constCast(mp.buf);
        buf[4 + msg_len + 1] = 0;
        const str = mp.buf[4 .. 4 + msg_len :0];
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
            [:0]const u8 => try iter.get_string_sentinel(),
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

    pub fn init(data: []const u8) !RegistryGlobal {
        return try parse_data_response(RegistryGlobal, data);
    }
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
    while (try res_iter.next()) |ev| {
        switch (ev.header.id) {
            wayland.ObjectIDs.display => {
                const err: DisplayError = try .init(ev.data);
                wl_log.err("  Main :: Display Error: object id: {d}, errcode: {d}, msg: {s}", .{ err.obj_id, err.code, err.msg });
            },
            wayland.ObjectIDs.registry => {
                switch (ev.header.op) {
                    0 => {
                        const global: RegistryGlobal = try .init(ev.data);
                        wl_log.info("  wl_registry::global ==> name: {d}, interface: {s}, version: {d}", .{
                            global.name,
                            global.interface,
                            global.version,
                        });

                        if (std.mem.eql(u8, global.interface, "wl_seat")) {
                            wl_seat_id = id.next();
                            wl_log.info("  wl_registry::global -- binding wl_seat with id: {d}\n", .{wl_seat_id});

                            registry_bind(&arena, stream_writer, global, wl_seat_id) catch |err| {
                                wl_log.err("  wl_registry::global -- failed to bind with err: {}\n", .{err});
                            };
                        } else if (std.mem.eql(u8, global.interface, "wl_compositor")) {
                            wl_compositor_id = id.next();
                            wl_log.info("  wl_registry::global -- binding compositor with id: {d}\n", .{wl_compositor_id});

                            registry_bind(&arena, stream_writer, global, wl_compositor_id) catch |err| {
                                wl_log.err("  wl_registry::global -- failed to bind with err: {}\n", .{err});
                            };
                        } else if (std.mem.eql(u8, global.interface, "xdg_wm_base")) {
                            xdg_wm_base_id = id.next();
                            wl_log.info("  wl_registry::global -- binding xdg_wm_base with id: {d}\n", .{xdg_wm_base_id});

                            registry_bind(&arena, stream_writer, global, xdg_wm_base_id) catch |err| {
                                wl_log.err("  wl_registry::global -- failed to bind with err: {}\n", .{err});
                            };
                        } else if (std.mem.eql(u8, global.interface, "wl_shm")) {
                            wl_shm_id = id.next();
                            wl_log.info("  wl_registry::global -- binding wl_shm with id: {d}\n", .{wl_shm_id});

                            registry_bind(&arena, stream_writer, global, wl_shm_id) catch |err| {
                                wl_log.err("  wl_registry::global -- failed to bind with err: {}\n", .{err});
                            };
                        }
                    },
                    1 => wl_log.warn("  wl_registry::global_remove uninmplemented handler", .{}),
                    else => wl_log.warn("  wl_display :: unrecognized ev opcode: {d}", .{ev.header.op}),
                }
            },
            else => wl_log.warn("  Main :: Event Iter :: Urecognized Header ID: {d}", .{ev.header.id}),
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
