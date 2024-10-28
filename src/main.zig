const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;

const wayland = @import("wayland.zig");
const wl_log = std.log.scoped(.Wayland);
const wl_msg = @import("wl_msg.zig");

const Header = wl_msg.Header;

/// Connect To Wayland Display
///
/// Assumes Arena Allocator -- does not manage own memory
fn connect_display(arena: Allocator) !std.net.Stream {
    const xdg_runtime_dir = std.posix.getenv("XDG_RUNTIME_DIR") orelse return error.NoXdgRuntime;
    const wayland_display = std.posix.getenv("WAYLAND_DISPLAY") orelse return error.NoWaylandDisplay;

    const display_path = try std.fs.path.join(arena, &.{ xdg_runtime_dir, wayland_display });
    wl_log.info("  Connect Display :: Attempting to connect to Wayland display at: {s}\n", .{display_path});
    const socket = try std.net.connectUnixSocket(display_path);
    return socket;
}

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

                const data_end = iter.buf.start + header.msg_size;

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
            .msg_size = GetRegistryMessage.Size,
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

    const write_data = struct {
        name: u32,
        interface: []const u8,
        version: u32,
        id: u32,
    };
    const msg: write_data = .{
        .name = global.name,
        .interface = sentinel_str[0 .. sentinel_str.len + 1],
        .version = global.version,
        .id = id,
    };
    try wl_write(writer, msg, wayland.ObjectIDs.registry, wayland.OpCodes.registry_bind);

    // const msg_size = Header.Size + 12 + round_up(4 + global.interface.len, 4);
    // var bytes_written: usize = 0;

    // const header: Header = .{
    //     .id = wayland.ObjectIDs.registry,
    //     .op = wayland.OpCodes.registry_bind,
    //     .msg_size = @intCast(msg_size),
    // };

    // try writer.writeStruct(header);
    // bytes_written += Header.Size;
    // bytes_written += try writer.write(std.mem.asBytes(&global.name));
    // bytes_written += try write_str(writer, sentinel_str[0 .. sentinel_str.len + 1]);
    // bytes_written += try writer.write(std.mem.asBytes(&global.version));
    // bytes_written += try writer.write(std.mem.asBytes(&id));
    // std.debug.assert(bytes_written == msg_size);
}

/// wl_compositor::create_surface:
///
fn compositor_create_surface(writer: std.net.Stream.Writer, id: u32, new_id: u32) !void {
    const msg_size = Header.Size + 4;

    const header: Header = .{
        .id = id,
        .op = wayland.OpCodes.compositor_create_surface,
        .msg_size = msg_size,
    };

    try writer.writeStruct(header);
    const endian = builtin.cpu.arch.endian();
    try writer.writeInt(u32, new_id, endian);
    wl_log.info("  wl_compositor@{d}::create_surface: wl_surface: {d}", .{ id, new_id });
}

fn xdg_wm_base_get_xdg_surface(writer: std.net.Stream.Writer, id: u32, new_id: u32, wl_surface: u32) !void {
    const msg_size = Header.Size + 4;

    const header: Header = .{
        .id = id,
        .op = wayland.OpCodes.xdg_wm_base_get_xdg_surface,
        .msg_size = msg_size,
    };

    try writer.writeStruct(header);
    try writer.writeInt(u32, new_id, builtin.cpu.arch.endian());
    try writer.writeInt(u32, wl_surface, builtin.cpu.arch.endian());
    wl_log.info("  xdg_wm_base@{d}::get_xdg_surface: xdg_surface: {d}", .{ id, new_id });
}

fn xdg_surface_get_toplevel(writer: std.net.Stream.Writer, id: u32, new_id: u32) !void {
    const msg_size = Header.Size + 4;

    const header: Header = .{
        .id = id,
        .op = wayland.OpCodes.xdg_surface_get_toplevel,
        .msg_size = msg_size,
    };

    try writer.writeStruct(header);
    try writer.writeInt(u32, new_id, builtin.cpu.arch.endian());
    wl_log.info("  xdg_surface@{d}::get_toplevel: xdg_toplevel: {d}", .{ id, new_id });
}

fn wl_write(writer: anytype, item: anytype, id: u32, op: u16) !void {
    var msg_size: usize = Header.Size;
    inline for (std.meta.fields(@TypeOf(item))) |field| {
        switch (field.type) {
            u32, i32 => msg_size += 4,
            []const u8, [:0]const u8 => msg_size += 4 + round_up(@field(item, field.name).len, 4),
            else => @compileLog("Unsupported field {s} of type {any}", .{ field.name, field.type }),
        }
    }
    const header: Header = .{
        .id = id,
        .op = op,
        .msg_size = @intCast(msg_size),
    };

    try writer.writeStruct(header);

    const endian = builtin.cpu.arch.endian();
    inline for (std.meta.fields(@TypeOf(item))) |field| {
        switch (field.type) {
            u32, i32 => {
                std.debug.print(" field name: {s} ::", .{field.name});
                std.debug.print(" writing int :: {d}\n", .{@field(item, field.name)});
                try writer.writeInt(field.type, @field(item, field.name), endian);
            },
            []const u8, [:0]const u8 => _ = try write_str(writer, @field(item, field.name)),
            else => @compileLog("Unsupported field {s} of type {any}", .{ field.name, field.type }),
        }
    }
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
            else => @compileLog("Data Parse Not Implemented for field {s} of type {any}", .{ field.name, field.type }),
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

const Registry = std.AutoHashMap(u32, RegistryGlobal);

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, Wayland!\n", .{});

    const arena_backer: Allocator = std.heap.page_allocator;
    var arena: Arena = .init(arena_backer);
    defer arena.deinit();
    const arena_allocator: Allocator = arena.allocator();

    const socket = try connect_display(arena_allocator);
    defer socket.close();
    const stream_writer = socket.writer();

    var res_iter: EventIt = .init(socket);

    var id: WaylandID = .{};
    try get_registry(stream_writer, id.next());

    var registry_arena: Arena = .init(arena_backer);
    defer registry_arena.deinit();
    var registry: Registry = .init(registry_arena.allocator());

    // global objects
    var wl_shm_id: u32 = undefined;
    var wl_seat_id: u32 = undefined;
    var wl_compositor_id: u32 = undefined;
    var xdg_wm_base_id: u32 = undefined;

    // interfaces
    var wl_surface_id: u32 = undefined;
    var xdg_surface_id: u32 = undefined;
    var xdg_toplevel_id: u32 = undefined;

    // Bind Registry
    while (try res_iter.next()) |ev| {
        switch (ev.header.id) {
            wayland.ObjectIDs.display => {
                const err: DisplayError = try .init(ev.data);
                wl_log.err("  Main :: Display Error: object id: {d}, errcode: {d}, msg: {s}", .{ err.obj_id, err.code, err.msg });
            },
            wayland.ObjectIDs.registry => {
                switch (ev.header.op) {
                    wayland.Registry.EventGlobal => {
                        const global: RegistryGlobal = try .init(ev.data);

                        if (std.mem.eql(u8, global.interface, "wl_seat")) {
                            wl_seat_id = id.next();
                            wl_log.info("  wl_registry::global -- binding wl_seat with id: {d}\n", .{wl_seat_id});
                            try registry.put(wl_seat_id, global);

                            registry_bind(&arena, stream_writer, global, wl_seat_id) catch |err| {
                                wl_log.err("  wl_registry::global -- failed to bind with err: {any}\n", .{err});
                            };
                        } else if (std.mem.eql(u8, global.interface, "wl_compositor")) {
                            wl_compositor_id = id.next();
                            wl_log.info("  wl_registry::global -- binding compositor with id: {d}\n", .{wl_compositor_id});
                            try registry.put(wl_compositor_id, global);

                            registry_bind(&arena, stream_writer, global, wl_compositor_id) catch |err| {
                                wl_log.err("  wl_registry::global -- failed to bind with err: {any}\n", .{err});
                            };
                        } else if (std.mem.eql(u8, global.interface, "xdg_wm_base")) {
                            xdg_wm_base_id = id.next();
                            wl_log.info("  wl_registry::global -- binding xdg_wm_base with id: {d}\n", .{xdg_wm_base_id});
                            try registry.put(xdg_wm_base_id, global);

                            registry_bind(&arena, stream_writer, global, xdg_wm_base_id) catch |err| {
                                wl_log.err("  wl_registry::global -- failed to bind with err: {any}\n", .{err});
                            };
                        } else if (std.mem.eql(u8, global.interface, "wl_shm")) {
                            wl_shm_id = id.next();
                            wl_log.info("  wl_registry::global -- binding wl_shm with id: {d}\n", .{wl_shm_id});
                            try registry.put(wl_shm_id, global);

                            registry_bind(&arena, stream_writer, global, wl_shm_id) catch |err| {
                                wl_log.err("  wl_registry::global -- failed to bind with err: {any}\n", .{err});
                            };
                        } else {
                            wl_log.warn("  UNUSED INTERFACE   ::   wl_registry::global ==> name: {d}, interface: {s}, version: {d}", .{
                                global.name,
                                global.interface,
                                global.version,
                            });
                        }
                    },
                    wayland.Registry.GlobalRemove => wl_log.warn("  wl_registry::global_remove -- No client registry implemented ", .{}),
                    else => wl_log.warn("  wl_display :: unrecognized registry opcode: {d}", .{ev.header.op}),
                }
            },
            else => {
                wl_log.warn("  Main :: Event Iter :: Unrecognized Header ID: {d}", .{ev.header.id});
            },
        }
    }

    // shm
    const buf_width = 540;
    const buf_height = 360;
    const buf_stride = buf_width * 4;
    const buf_size = buf_stride * buf_height;
    const shm_pool_fd = try std.posix.memfd_create("Ziggified Wayland", 0);
    try std.posix.ftruncate(shm_pool_fd, buf_size);
    const shm_pool_data: []align(4096) u8 = try std.posix.mmap(
        null,
        buf_size,
        std.posix.PROT.READ | std.posix.PROT.WRITE,
        .{ .TYPE = .SHARED },
        shm_pool_fd,
        0,
    );

    // Dirty Hack
    {
        const data_u32: [*]u32 = @ptrCast(shm_pool_data);
        for (0..buf_height / 4) |y| {
            for (0..buf_width / 4) |x| {
                if ((x + y / 8 * 8) % 16 < 8) {
                    data_u32[y * buf_width + x] = 0xFF666666;
                } else {
                    data_u32[y * buf_width + x] = 0xFFEEEEEE;
                }
            }
        }
    }

    // surface
    {
        // create wl_surface
        wl_surface_id = id.next();
        const CD = struct {
            new_id: u32,
        };
        try wl_write(stream_writer, CD{ .new_id = wl_surface_id }, wl_compositor_id, wayland.OpCodes.compositor_create_surface);
        // try compositor_create_surface(stream_writer, wl_compositor_id, wl_surface_id);

        // create xdg_surface
        xdg_surface_id = id.next();

        try writeRequest(socket, xdg_wm_base_id, wayland.OpCodes.xdg_wm_base_get_xdg_surface, &[_]u32{
            // id: new_id<xdg_surface>
            xdg_surface_id,
            // surface: object<wl_surface>
            wl_surface_id,
        });
        // const XDG_surface_data = struct {
        //     new_id: u32,
        //     wl_surface: u32,
        // };
        // const data: XDG_surface_data = .{
        //     .new_id = xdg_surface_id,
        //     .wl_surface = wl_surface_id,
        // };
        // // get xdg_surface
        // try wl_write(stream_writer, data, xdg_wm_base_id, wayland.OpCodes.xdg_wm_base_get_xdg_surface);
        // try xdg_wm_base_get_xdg_surface(stream_writer, xdg_wm_base_id, xdg_surface_id);

        // create xdg_toplevel
        xdg_toplevel_id = id.next();
        try xdg_surface_get_toplevel(stream_writer, xdg_surface_id, xdg_toplevel_id);
    }

    try wl_write(stream_writer, .{}, wl_surface_id, wayland.OpCodes.surface_commit);

    while (try res_iter.next()) |ev| {
        if (ev.header.id == xdg_surface_id) {
            switch (ev.header.op) {
                // https://wayland.app/protocols/xdg-shell#xdg_surface:event:configure
                0 => {
                    const AckRes = struct {
                        val: u32,
                    };
                    const ares: AckRes = try parse_data_response(AckRes, ev.data);
                    // ack config
                    try wl_write(stream_writer, ares, xdg_surface_id, wayland.OpCodes.xdg_surface_ack_configure);
                    // commit
                    try wl_write(stream_writer, .{}, wl_surface_id, wayland.OpCodes.surface_commit);
                    break;
                },
                else => return error.InvalidOpcode,
            }
        } else {
            wl_log.warn("unknown event :: ( id: {d}, opcode: {d}, msg: {s} )", .{ ev.header.id, ev.header.op, ev.data });
        }
    }
    var shm_pool_id: u32 = undefined;
    var buf_id: u32 = undefined;
    {
        shm_pool_id = id.next();
        // create pool
        // try write_shm_create_pool(socket, wl_shm_id, shm_pool_id, shm_pool_fd, buf_size);
        // try wl_write(stream_writer, Data{ .pool_size = buf_size, .fd = @intCast(shm_pool_fd) }, shm_pool_id, wayland.OpCodes.shm_create_pool);
        try writeWlShmRequestCreatePool(socket, wl_shm_id, shm_pool_id, shm_pool_fd, @intCast(buf_size));

        const BufData = struct {
            id: u32,
            width: u32,
            height: u32,
            stride: u32,
            fmt: u32,
        };
        // create buffer
        buf_id = id.next();
        try wl_write(stream_writer, BufData{
            .id = buf_id,
            .width = buf_width,
            .height = buf_height,
            .stride = buf_stride,
            .fmt = wayland.format_xrgb8888,
        }, shm_pool_id, wayland.OpCodes.shm_pool_create_buffer);
    }
    std.posix.munmap(shm_pool_data);

    // surface attach
    const AttachData = struct {
        id: u32,
        x: u32,
        y: u32,
    };
    try wl_write(
        stream_writer,
        AttachData{
            .id = buf_id,
            .x = 0,
            .y = 0,
        },
        wl_surface_id,
        wayland.OpCodes.surface_attach,
    );

    const DamageData = struct {
        xoffset: i32,
        yoffset: i32,
        width: i32,
        height: i32,
    };

    const dmg_data: DamageData = .{
        .xoffset = 0,
        .yoffset = 0,
        .width = buf_width,
        .height = buf_height,
    };
    // write dmg request
    try wl_write(stream_writer, dmg_data, wl_surface_id, 2);

    // surface commit again
    try wl_write(stream_writer, .{}, wl_surface_id, wayland.OpCodes.surface_commit);

    while (true) {
        while (try res_iter.next()) |ev| {
            if (ev.header.id == xdg_surface_id) {
                switch (ev.header.op) {
                    // https://wayland.app/protocols/xdg-shell#xdg_surface:event:configure
                    0 => {
                        const AckRes = struct {
                            val: u32,
                        };
                        const ares: AckRes = try parse_data_response(AckRes, ev.data);
                        // ack config
                        try wl_write(stream_writer, ares, xdg_surface_id, wayland.OpCodes.xdg_surface_ack_configure);
                        // commit
                        try wl_write(stream_writer, .{}, wl_surface_id, wayland.OpCodes.surface_commit);
                        break;
                    },
                    else => return error.InvalidOpcode,
                }
            } else {
                wl_log.warn("unknown event :: ( id: {d}, opcode: {d}, msg: {any} )", .{ ev.header.id, ev.header.op, ev.data });
            }
        }
    }

    try stdout.print("Program Exiting Now!\n", .{});
}

const RegID = struct {
    id: u32,
};

fn write_shm_create_pool(writer: std.net.Stream, wl_shm_id: u32, new_id: u32, fd: std.posix.fd_t, fd_len: i32) !void {
    const message = [_]u32{
        // id: new_id<wl_shm_pool>
        new_id,
        // size: int
        @intCast(fd_len),
    };
    // If you're paying close attention, you'll notice that our message only has two parameters in it, despite the
    // documentation calling for 3: wl_shm_pool_id, fd, and size. This is because `fd` is sent in the control message,
    // and so not included in the regular message body.

    // Create the message header as usual
    const message_bytes = std.mem.sliceAsBytes(&message);
    const header = Header{
        .id = wl_shm_id,
        .op = wayland.OpCodes.shm_create_pool,
        .msg_size = @sizeOf(Header) + @as(u16, @intCast(message_bytes.len)),
    };
    const header_bytes = std.mem.asBytes(&header);

    // we'll be using `std.posix.sendmsg` to send a control message, so we may as well use the vectorized
    // IO to send the header and the message body while we're at it.
    const msg_iov = [_]std.posix.iovec_const{
        .{
            .base = header_bytes.ptr,
            .len = header_bytes.len,
        },
        .{
            .base = message_bytes.ptr,
            .len = message_bytes.len,
        },
    };

    // Send the file descriptor through a control message

    // This is the control message! It is not a fixed size struct. Instead it varies depending on the message you want to send.
    // C uses macros to define it, here we make a comptime function instead.
    const control_message = cmsg(std.posix.fd_t){
        .level = std.posix.SOL.SOCKET,
        .type = 0x01, // value of SCM_RIGHTS
        .data = fd,
    };
    const control_message_bytes = std.mem.asBytes(&control_message);

    const socket_message = std.posix.msghdr_const{
        .name = null,
        .namelen = 0,
        .iov = &msg_iov,
        .iovlen = msg_iov.len,
        .control = control_message_bytes.ptr,
        // This is the size of the control message in bytes
        .controllen = control_message_bytes.len,
        .flags = 0,
    };

    const bytes_sent = try std.posix.sendmsg(writer.handle, &socket_message, 0);
    if (bytes_sent < header_bytes.len + message_bytes.len) {
        return error.ConnectionClosed;
    }
}

fn cmsg(comptime T: type) type {
    const padding_size = (@sizeOf(T) + @sizeOf(c_long) - 1) & ~(@as(usize, @sizeOf(c_long)) - 1);
    return packed struct {
        len: c_ulong = @sizeOf(@This()) - padding_size,
        level: c_int,
        type: c_int,
        data: T,
        _padding: std.meta.Int(.unsigned, 8 * padding_size) = 0,
    };
}

//---------------------------------------------------------------------------------
// taken from 00_client_connect.zig
pub fn writeWlShmRequestCreatePool(socket: std.net.Stream, wl_shm_id: u32, next_id: u32, fd: std.posix.fd_t, fd_len: i32) !void {
    const wl_shm_pool_id = next_id;

    const message = [_]u32{
        // id: new_id<wl_shm_pool>
        wl_shm_pool_id,
        // size: int
        @intCast(fd_len),
    };
    // If you're paying close attention, you'll notice that our message only has two parameters in it, despite the
    // documentation calling for 3: wl_shm_pool_id, fd, and size. This is because `fd` is sent in the control message,
    // and so not included in the regular message body.

    // Create the message header as usual
    const message_bytes = std.mem.sliceAsBytes(&message);
    const header = Header{
        .id = wl_shm_id,
        .op = wayland.OpCodes.shm_create_pool,
        .msg_size = @sizeOf(Header) + @as(u16, @intCast(message_bytes.len)),
    };
    const header_bytes = std.mem.asBytes(&header);

    // we'll be using `std.posix.sendmsg` to send a control message, so we may as well use the vectorized
    // IO to send the header and the message body while we're at it.
    const msg_iov = [_]std.posix.iovec_const{
        .{
            .base = header_bytes.ptr,
            .len = header_bytes.len,
        },
        .{
            .base = message_bytes.ptr,
            .len = message_bytes.len,
        },
    };

    // Send the file descriptor through a control message

    // This is the control message! It is not a fixed size struct. Instead it varies depending on the message you want to send.
    // C uses macros to define it, here we make a comptime function instead.
    const control_message = cmsg(std.posix.fd_t){
        .level = std.posix.SOL.SOCKET,
        .type = 0x01, // value of SCM_RIGHTS
        .data = fd,
    };
    const control_message_bytes = std.mem.asBytes(&control_message);

    const socket_message = std.posix.msghdr_const{
        .name = null,
        .namelen = 0,
        .iov = &msg_iov,
        .iovlen = msg_iov.len,
        .control = control_message_bytes.ptr,
        // This is the size of the control message in bytes
        .controllen = control_message_bytes.len,
        .flags = 0,
    };

    const bytes_sent = try std.posix.sendmsg(socket.handle, &socket_message, 0);
    if (bytes_sent < header_bytes.len + message_bytes.len) {
        return error.ConnectionClosed;
    }
}
/// Handles creating a header and writing the request to the socket.
pub fn writeRequest(socket: std.net.Stream, object_id: u32, opcode: u16, message: []const u32) !void {
    const message_bytes = std.mem.sliceAsBytes(message);
    const header = Header{
        .id = object_id,
        .op = opcode,
        .msg_size = @sizeOf(Header) + @as(u16, @intCast(message_bytes.len)),
    };

    try socket.writeAll(std.mem.asBytes(&header));
    try socket.writeAll(message_bytes);
}

//---------------------------------------------------------------------------------

// Next Steps:
// - [x] Create Registry Globals For Following Interfaces:
//      - [x] wl_shm
//      - [x] wl_compositor
//      - [x] xdg_wm_base
//      - [x] wl_seat
// - [ ] wl_display rountrip
// - [ ] Get Compositor Surface
// - [ ] Get Xdg_Surface
// - [ ] Get Toplevel of Xdg_Surface
//     - [ ] Set Toplevel Title
// - [ ] Commit Compositor Surface
// - [ ] memmap data over to display
//
//
// Mid-Term Goals:
// - [ ] XML Parser/Generator for Protocols
//      - [ ] Generate reasonable Structs / Enums / "Methods"
//      - [ ] Output "description" fields as Doc-Strings
// - [ ] Figure out DMA Buffering and Presentation Time
// - [ ] Vulkan Graphics Context
//
//
// Longer-Term Goals:
// - [ ] Input handling (mouse/keyboard only at first)
// - [ ] Multi-threading:
//     - [ ] Input thread
//     - [ ] Render thread
//     - [ ] Core application on main thread
// - [ ] Multi-buffering (Ideally Triple)
//
