const std = @import("std");

const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const posix = std.posix;
const fs = std.fs;

const wl_log = std.log.scoped(.Wayland);

const wayland = @import("wayland.zig");

fn connect_display(arena: Allocator) !std.net.Stream {
    const xdg_runtime_dir = posix.getenv("XDG_RUNTIME_DIR") orelse return error.NoXdgRuntime;
    const wayland_display = posix.getenv("WAYLAND_DISPLAY") orelse return error.NoWaylandDisplay;

    const display_path = try fs.path.join(arena, &.{ xdg_runtime_dir, wayland_display });
    defer arena.free(display_path);
    wl_log.info("Attempting to connect to Wayland display at: {s}\n", .{display_path});
    const stream = try std.net.connectUnixSocket(display_path);
    return stream;
}

// Wayland Wire communication
//
// 4 Bytes: ID of resource to call methods on
// 2 Bytes: method opcode
// 2 Bytes: size of message
// Arguments to method, if any
const Header = packed struct(u64) {
    id: u32,
    op: u16,
    size: u16,

    const Size = @sizeOf(Header);
};

const Event = struct {
    header: Header,
    data: []const u8,
};

const EventIt = struct {
    stream: std.net.Stream,
    buf: ShiftBuf = .{},

    // Need to solve problem of reading a partial header or partial data stream
    // Buffer -> [ _ _ _ _ _ ]
    // Fill =>   [ x y z w x ]
    // Shift =>  [ x _ _ _ _ ]
    // Fill =>   [ x y z w u ]
    //
    // Read into buffer happens into offset pointer
    // Read from buffer happend from start of buffer
    const ShiftBuf = struct {
        data: [4096]u8 = undefined,
        start: usize = 0,
        end: usize = 0,

        pub fn shift(sb: *ShiftBuf) void {
            std.mem.copyForwards(u8, &sb.data, sb.data[sb.start..]);
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
        iter.buf.shift();
        const bytes_read: usize = try iter.stream.read(iter.buf.data[iter.buf.end..]);
        if (bytes_read == 0) {
            return error.RemoteClosed;
        }
        iter.buf.end += bytes_read;
    }

    pub fn next(iter: *EventIt) !?Event {
        while (true) {
            const buffered_ev = blk: {
                const header_end = iter.buf.start + Header.Size;
                if (header_end > iter.buf.end) break :blk null;

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
                var poll: [1]std.posix.pollfd = [1]std.posix.pollfd{.{
                    .fd = iter.stream.handle,
                    .events = std.posix.POLL.IN,
                    .revents = 0,
                }};
                const bytes_ready = try std.posix.poll(&poll, 1); // 0 seems to just never read successfully
                break :blk bytes_ready != 0;
            };

            if (data_in_stream) {
                iter.load_events() catch |err| {
                    wl_log.warn("!stream closed! :: {any}", .{err});
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
        const ret = self.next_id;
        self.next_id += 1;
        return ret;
    }
};

fn get_registry(stream: std.net.Stream, new_id: u32) !void {
    const GetRegistryMessage = struct {
        header: Header,
        new_id: u32,
    };

    const msg: GetRegistryMessage = .{
        .header = .{
            .id = new_id,
            .op = 2,
            .size = @sizeOf(GetRegistryMessage),
        },
        .new_id = new_id,
    };

    const bytes = try stream.writer().write(std.mem.asBytes(&msg));
    std.debug.assert(bytes == @sizeOf(GetRegistryMessage));
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
            wl_log.warn("wl_registry::global uninmplemented handler", .{});
            const global: RegistryGlobal = try parse_data_response(RegistryGlobal, ev.data);
            wl_log.info("wl_registry::global ==> name: {d}, interface: {s}, version: {d}", .{
                global.name,
                global.interface,
                global.version,
            });
        },
        1 => wl_log.warn("wl_registry::global_remove uninmplemented handler", .{}),
        else => wl_log.warn("wl_display :: unrecognized ev opcode: {d}", .{ev.header.op}),
    }
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, Wayland!\n", .{});

    const arena_backer: Allocator = std.heap.page_allocator;
    var arena = Arena.init(arena_backer);
    defer arena.deinit();
    const arena_allocator: Allocator = arena.allocator();

    const stream = try connect_display(arena_allocator);
    defer stream.close();

    var id = WaylandID{};
    try get_registry(stream, id.next());

    var res_iter: EventIt = .{
        .stream = stream,
    };

    while (try res_iter.next()) |ev| {
        try stdout.print("  :: Header: ID -> {d}, OpCode -> {d}, size -> {d}\n", .{ ev.header.id, ev.header.op, ev.header.size });
        try registry_global_handle(ev);
    }
}
