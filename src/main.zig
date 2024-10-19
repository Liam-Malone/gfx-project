const std = @import("std");

const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const posix = std.posix;
const fs = std.fs;

const wl_log = std.log.scoped(.Wayland);

const wayland = @import("wayland.zig");

fn connect_socket(arena: Allocator) !posix.socket_t {
    const xdg_runtime_dir = posix.getenv("XDG_RUNTIME_DIR") orelse return error.NoXdgRuntime;
    const wayland_display = posix.getenv("WAYLAND_DISPLAY") orelse return error.NoWaylandDisplay;

    const display_socket_path = try fs.path.join(arena, &.{ xdg_runtime_dir, wayland_display });
    defer arena.free(display_socket_path);
    const socket = try posix.socket(posix.system.AF.UNIX, posix.system.SOCK.STREAM, 0);

    var sock_path: [108]u8 = undefined;
    @memset(&sock_path, 0);
    if (display_socket_path.len > sock_path.len) {
        return error.SocketPathTooLong;
    }

    @memcpy(sock_path[0..display_socket_path.len], display_socket_path);

    const socket_addr: posix.system.sockaddr.un = .{
        .path = sock_path,
    };

    wl_log.info("Attempting to connect to socket: {s}\n", .{socket_addr.path});

    try posix.connect(socket, @ptrCast(&socket_addr), @sizeOf(@TypeOf(socket_addr)));
    return socket;
}

// Wayland Wire communication
//
// 4 Bytes: ID of resource to call methods on
// 2 Bytes: method opcode
// 2 Bytes: size of message
// Arguments to method, if any
const Header = packed struct {
    id: u32,
    op: u16,
    size: u16,
};

const RegistryMember = struct {
    id: u32,
    version: u32,
    name: []const u8,
};
const Registry = struct {
    map: std.AutoHashMap(u32, RegistryMember),

    pub fn init(arena: Allocator) !Registry {
        var reg: Registry = .{ .map = .init(arena) };
        reg.map.put(0, .{
            .id = 1,
            .version = 1,
        });
        return reg;
    }
};

const WaylandID = struct {
    next_id: u32 = 2,

    pub fn next(self: *WaylandID) u32 {
        const ret = self.next_id;
        self.next_id += 1;
        return ret;
    }
};

fn get_registry(socket: posix.socket_t, new_id: u32) !void {
    const GetRegistryMessage = struct {
        header: Header,
        new_id: u32,
    };

    const msg: GetRegistryMessage = .{
        .header = .{
            .id = wayland.wl_display_get_registry_opcode,
            .op = wayland.wl_display_get_registry_opcode,
            .size = @sizeOf(GetRegistryMessage),
        },
        .new_id = new_id,
    };
    _ = try posix.write(socket, std.mem.asBytes(&msg));
}

fn round_up(val: anytype, mul: @TypeOf(val)) @TypeOf(val) {
    return ((val - 1 / mul + 1) * mul);
}

const MsgParser = struct {
    buf: []const u8,

    pub fn getU32(mp: *MsgParser) !u32 {
        if (mp.buf.len < @sizeOf(u32)) {
            return error.InvalidLength;
        }

        const val = std.mem.bytesAsValue(u32, mp.buf[0..4]).*;
        mp.consume(4);
        return val;
    }
    pub fn getString(mp: *MsgParser) ![]const u8 {
        if (mp.buf.len < @sizeOf(u32)) {
            return error.InvalidLength;
        }

        const msg_len = std.mem.bytesAsValue(u32, &mp.buf).*;
        const consume_len = @sizeOf(u32) + msg_len;
        if (consume_len > mp.buf.len) {
            return error.InvalidLength;
        }
        const str = mp.buf[4..];
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

const WlEventIt = struct {
    buf: []const u8,

    pub const WlEvent = struct {
        header: Header,
        data: []const u8,
    };
    pub fn next(iter: *WlEventIt) ?WlEvent {
        const HeaderSize = @sizeOf(Header);

        if (iter.buf.len < HeaderSize) {
            return null;
        }

        const header = std.mem.bytesAsValue(Header, iter.buf[0..HeaderSize]);
        if (iter.buf.len < header.size) {
            return null;
        }

        const data = iter.buf[HeaderSize..header.size];
        iter.consume(header.size);

        return .{
            .header = header.*,
            .data = data,
        };
    }
    fn consume(iter: *WlEventIt, len: usize) void {
        if (iter.buf.len == len) {
            iter.buf = &.{};
        } else {
            iter.buf = iter.buf[len..];
        }
    }
};

fn display_event_handle(ev: WlEventIt.WlEvent) !void {
    switch (ev.header.op) {
        0 => {
            const err: DisplayError = try .init(ev.data);
            wl_log.warn("wl_display :: Error: object: {d}, code: {d}, msg: {s}", .{
                err.obj_id,
                err.code,
                err.msg,
            });
        },
        1 => {
            wl_log.warn("wl_display :: delete id -- unhandled", .{});
        },
        else => {
            wl_log.warn("wl_display :: unrecognized ev opcode: {d}", .{ev.header.op});
        },
    }
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, Wayland!\n", .{});

    const arena_backer: Allocator = std.heap.page_allocator;
    var arena = Arena.init(arena_backer);
    defer arena.deinit();
    const arena_allocator: Allocator = arena.allocator();

    const socket = try connect_socket(arena_allocator);

    var id = WaylandID{};
    try get_registry(socket, id.next());

    var buf: [2048]u8 = undefined;
    @memset(&buf, 0);
    const res_len = try posix.read(socket, &buf);
    var res_iter: WlEventIt = .{
        .buf = buf[0..res_len],
    };

    while (res_iter.next()) |ev| {
        try stdout.print("  :: Header: {any}\n", .{ev.header});
        switch (ev.header.id) {
            1 => try display_event_handle(ev),
            2 => {
                const ProtocolRegData = struct {
                    id: u32,
                    version: u32,
                    protocol_name: []const u8,
                };

                const str_buf = ev.data[@sizeOf(u64)..];
                var str_len: usize = str_buf.len;
                for (str_buf, 0..) |char, idx| {
                    if (char == 0) {
                        str_len = idx;
                        break;
                    }
                }

                const data: ProtocolRegData = .{
                    .id = std.mem.bytesAsValue(u32, ev.data[0..@sizeOf(u32)]).*,
                    .version = std.mem.bytesAsValue(u32, ev.data[@sizeOf(u32)..@sizeOf(u64)]).*,
                    .protocol_name = str_buf[0..str_len],
                };

                if (std.mem.eql(u8, "wl_seat", data.protocol_name)) {
                    try stdout.print("\n\nHit wl_seat\n\n", .{});
                }
                try stdout.print("  :: Data: registery id = {d}, protocol name = {s}, version = {d}\n\n", .{
                    data.id,
                    data.protocol_name,
                    data.version,
                });
            },
            else => {},
        }
    }
}
