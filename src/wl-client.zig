const std = @import("std");

const Drm = @import("Drm.zig");
const Arena = @import("Arena.zig");
const interface = @import("wl-interface.zig");
const GraphicsContext = @import("GraphicsContext.zig");

const BufCount = GraphicsContext.BufferCount;

const protocols = @import("generated/protocols.zig");
const wl = protocols.wayland;
const xdg = protocols.xdg_shell;
const dmab = protocols.linux_dmabuf_v1;
const xdgd = protocols.xdg_decoration_unstable_v1;

const msg = @import("wl-msg");

const log = std.log.scoped(.@"wayland-client");

const Client = @This();

pub const nil: Client = .{
    .socket = -1,
    .connection = undefined,
    .display = undefined,
    .registry = undefined,
    .compositor = undefined,
    .interface = undefined,

    .surfaces = undefined,
    .ev_iter = undefined,
};

// Base wayland connection
socket: std.posix.fd_t,
connection: std.net.Stream,

// Required interfaces (Global objects)
display: wl.Display,
registry: *interface.Registry,
compositor: wl.Compositor,
seat: wl.Seat,
wm_base: xdg.WmBase,
decorations: xdgd.DecorationManagerV1,
dmabuf: dmab.LinuxDmabufV1,

// Windows
surfaces: std.ArrayList(*Surface),
focused_surface: usize = 0,
gfx_format: Drm.Format,

// Wayland event handling
ev_iter: Event.iter(2048),
ev_thread: std.Thread,

pub fn init(arena: *Arena) Client {
    const connection = open_connection: {
        const xdg_runtime_dir = std.posix.getenv("XDG_RUNTIME_DIR") orelse return .nil;
        const wayland_display = std.posix.getenv("WAYLAND_DISPLAY") orelse return .nil;

        const sock_path = std.mem.join(arena.allocator(), "/", &[_][]const u8{ xdg_runtime_dir, wayland_display }) catch return .nil;
        break :open_connection std.net.connectUnixSocket(sock_path) catch return .nil;
    };

    const display: wl.Display = .{ .id = 1 };
    const connection_writer = connection.writer();
    interface.registry = .init(arena.allocator(), connection_writer, display); // calls 'get_resitry'

    var compositor_opt: ?wl.Compositor = null;
    var seat_opt: ?wl.Seat = null;
    var wm_base_opt: ?xdg.WmBase = null;
    var decorations_opt: ?xdgd.DecorationManagerV1 = null;
    var dmabuf_opt: ?dmab.LinuxDmabufV1 = null;

    var ev_iter: Event.iter(2048) = .init(connection);
    ev_iter.load_events() catch |err| {
        log.err("Failed to load wayland events with err :: {s}", .{@errorName(err)});
        return .nil;
    };
    // Bind interfaces
    while (ev_iter.next() catch return .nil) |ev| {
        const interface_opt = interface.registry.get(ev.header.id) orelse null;
        if (interface_opt) |registry_interface| {
            if (@TypeOf(registry_interface) != wl.Registry) {
                continue;
            }
            const action_opt = wl.Registry.Event.parse(ev.header.op, ev.data) catch null;
            if (action_opt) |action| switch (action) {
                .global => |global| {
                    if (std.mem.eql(u8, global.interface, wl.Seat.name)) {
                        seat_opt = interface.registry.bind(wl.Seat, connection_writer, global) catch |err| nil: {
                            log.err("Failed to bind compositor with error: {s}", .{@errorName(err)});
                            break :nil null;
                        };
                    } else if (std.mem.eql(u8, global.interface, wl.Compositor.name)) {
                        compositor_opt = interface.registry.bind(wl.Compositor, connection_writer, global) catch |err| nil: {
                            log.err("Failed to bind compositor with error: {s}", .{@errorName(err)});
                            break :nil null;
                        };
                    } else if (std.mem.eql(u8, global.interface, xdg.WmBase.name)) {
                        wm_base_opt = interface.registry.bind(xdg.WmBase, connection_writer, global) catch |err| nil: {
                            log.err("Failed to bind xdg_wm_base with error: {s}", .{@errorName(err)});
                            break :nil null;
                        };
                    } else if (std.mem.eql(u8, global.interface, xdgd.DecorationManagerV1.name)) {
                        decorations_opt = interface.registry.bind(xdgd.DecorationManagerV1, connection_writer, global) catch |err| nil: {
                            log.err("Failed to bind zxdg__decoration_manager with error: {s}", .{@errorName(err)});
                            break :nil null;
                        };
                    } else if (std.mem.eql(u8, global.interface, dmab.LinuxDmabufV1.name)) {
                        dmabuf_opt = interface.registry.bind(dmab.LinuxDmabufV1, connection_writer, global) catch |err| nil: {
                            log.err("Failed to bind linux_dmabuf with error: {s}", .{@errorName(err)});
                            break :nil null;
                        };
                    }
                },
                .global_remove => {
                    log.warn("Unexpected global remove event", .{});
                },
            };
        }
    }

    const wl_compositor = compositor_opt orelse {
        log.err("Failed to bind wl_compositor, cannot continue", .{});
        return .nil;
    };
    const wl_seat = seat_opt orelse {
        log.err("Failed to bind wl_compositor, cannot continue", .{});
        return .nil;
    };
    const xdg_wm_base = wm_base_opt orelse {
        log.err("Failed to bind wl_compositor, cannot continue", .{});
        return .nil;
    };
    const xdg_decorations = decorations_opt orelse {
        log.err("Failed to bind wl_compositor, cannot continue", .{});
        return .nil;
    };
    const linux_dmabuf = dmabuf_opt orelse {
        log.err("Failed to bind wl_compositor, cannot continue", .{});
        return .nil;
    };

    var surfaces: std.ArrayList(*Surface) = .init(arena.allocator());
    var client: Client = .{
        .socket = connection.handle,
        .connection = connection,
        .display = display,
        .registry = &interface.registry,
        .compositor = wl_compositor,
        .seat = wl_seat,
        .wm_base = xdg_wm_base,
        .decorations = xdg_decorations,
        .dmabuf = linux_dmabuf,

        .surfaces = undefined,
        .focused_surface = 0,
        .ev_iter = ev_iter,
        .ev_thread = undefined,
    };

    const initial_surface: *Surface = arena.create(Surface);
    initial_surface.* = .init(.{
        .app_id = "simple-client",
        .surface_title = "Simple Client",
        .client = &client,
        .compositor = wl_compositor,
        .wm_base = xdg_wm_base,
        .decoration_manager = xdg_decorations,
        .dims = .{ .x = 800, .y = 600 },
    });

    surfaces.append(initial_surface) catch {
        log.err("Failed to add initial surface to surfaces list", .{});
    };

    const ev_thread = std.Thread.spawn(.{}, ev_handle_thread, .{&client}) catch |err| {
        log.err("Wayland Event Thread Spawn Failed :: {s}", .{@errorName(err)});
        return .nil;
    };
    client.surfaces = surfaces;
    client.ev_thread = ev_thread;

    while (!client.surfaces.items[client.focused_surface].flags.acked) {} // wait for ev thread to ack config
    return client;
}

pub fn deinit(client: *Client) void {
    client.ev_thread.join();
}

fn ev_handle_thread(client: *Client) void {
    while (client.socket != -1) {
        client.handle_event() catch |err| {
            log.err("Wayland Event Thread Hit Error :: {s}", .{@errorName(err)});
            client.socket = -1;
        };
    }
}

fn handle_event(client: *Client) !void {
    const event_iterator = &client.ev_iter;

    const writer = client.connection.writer();
    const ev_opt = event_iterator.next() catch |err| {
        log.err("Wayland Event Thread Encountered Fatal Error: {s}", .{@errorName(err)});
        return err;
    } orelse blk: {
        std.time.sleep(8 * std.time.ns_per_ms);
        break :blk null;
    };
    if (ev_opt) |ev| {
        const ev_interface = interface.registry.get(ev.header.id) orelse return;
        switch (ev_interface) {
            xdg.WmBase => {
                const action_opt: ?xdg.WmBase.Event = xdg.WmBase.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .ping => |ping| {
                            client.xdg_wm_base.pong(writer, .{
                                .serial = ping.serial,
                            }) catch |err| return err;
                        },
                    };
            },
            xdg.Surface => {
                const action_opt: ?xdg.Surface.Event = xdg.Surface.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .configure => |configure| {
                            client.surfaces.items[client.focused_surface].ack_configure(writer, .{ .serial = configure.serial }) catch |err| return err;
                            if (!client.surfaces.items[client.focused_surface].flags.acked) {
                                log.info("Acked configure for xdg_surface", .{});
                                client.surfaces.items[client.focused_surface].flags.acked = true;
                            }
                        },
                    };
            },
            xdg.Toplevel => {
                const action_opt: ?xdg.Toplevel.Event = xdg.Toplevel.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .configure => |configure| {
                            if (configure.width > client.surfaces.items[client.focused_surface].dims.x or configure.height > client.surfaces.items[client.focused_surface].dims.y) {
                                log.info("Resizing Window :: {d}x{d} -> {d}x{d}", .{
                                    client.surfaces.items[client.focused_surface].dims.x,
                                    client.surfaces.items[client.focused_surface].dims.y,
                                    configure.width,
                                    configure.height,
                                });

                                client.surfaces.items[client.focused_surface].dims.x = configure.width;
                                client.surfaces.items[client.focused_surface].dims.y = configure.height;
                            }
                        },
                        .close => { //  Empty struct, nothing to capture
                            log.info("Toplevel Received Close Signal", .{});
                            client.surfaces.items[client.focused_surface].destroy(writer, .{}) catch |err| return err;
                            client.surfaces.orderedRemove(client.focused_surface);
                            if (client.surfaces.items.len == 0) {
                                client.socket = -1;
                            }
                        },
                        else => {},
                    };
            },
            dmab.LinuxDmabufFeedbackV1 => {
                const feedback = dmab.LinuxDmabufFeedbackV1.Event.parse(ev.header.op, ev.data) catch |err| return err;

                switch (feedback) {
                    .format_table => |table| {
                        if (event_iterator.next_fd()) |fd| {
                            const table_data = std.posix.mmap(
                                null,
                                table.size,
                                std.posix.PROT.READ,
                                .{ .TYPE = .PRIVATE },
                                fd,
                                0,
                            ) catch |err| {
                                log.err("DMABuf Feedback :: Failed to Map Supported Formats Table :: {s}", .{@errorName(err)});
                                return err;
                            };
                            defer std.posix.munmap(table_data);

                            client.gfx_format.wl_format = .abgr8888;
                        }
                    },
                    else => {},
                }
            },
            else => {},
        }
    }
}

pub fn log_display_err(err: wl.Display.Event.Error) void {
    log.err("wl_display::error => object id: {d}, code: {d}, msg: {s}", .{
        err.object_id,
        err.code,
        err.message,
    });
}

const Event = struct {
    header: msg.Header,
    data: []const u8,

    pub const nil: Event = .{
        .header = .{
            .id = 0,
            .op = 0,
            .msg_size = 0,
        },
        .data = &.{},
    };

    pub fn eql(ev_1: *const Event, ev_2: *const Event) bool {
        return (std.mem.eql(u8, std.mem.asBytes(&ev_1.header), std.mem.asBytes(&ev_2.header)) and std.mem.eql(u8, ev_1.data, ev_2.data));
    }

    /// Iterator over Wayland events
    pub fn iter(comptime buf_size: comptime_int) type {
        return struct {
            /// Read into buffer happens from offset pointer
            /// Read from buffer happens from start of buffer
            const ShiftBuf = struct {
                data: [buf_size]u8 = undefined,
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

            const FdQueue = struct {
                data: [Len]std.posix.fd_t = undefined,
                read: usize = 0,
                write: usize = 0,
                pub const Len = 64;
            };

            const Iterator = @This();

            stream: std.net.Stream,
            buf: ShiftBuf = .{},
            fd_queue: FdQueue = .{},
            fd_buf: [FdQueue.Len * @sizeOf(std.posix.fd_t)]u8 = undefined,

            pub fn init(stream: std.net.Stream) Iterator {
                return .{
                    .stream = stream,
                };
            }

            /// Calls `.shift()` on data buffer, and reads in new bytes from stream
            fn load_events(it: *Iterator) !void {
                if (receive_cmsg(it.stream.handle, &it.fd_buf)) |fd| {
                    const idx = it.fd_queue.write % FdQueue.Len;
                    it.fd_queue.data[idx] = fd;
                    it.fd_queue.write += 1;
                }

                it.buf.shift();

                const bytes_read: usize = try it.stream.read(it.buf.data[it.buf.end..]);
                it.buf.end += bytes_read;
            }

            /// Get next stored message from buffer
            ///
            /// When the buffer is filled, the follwing call to `.next()` will
            /// overwrite all messages that have already been read.
            ///
            /// See: `ShiftBuf.shift()`
            pub fn next(it: *Iterator) !?Event {
                while (true) {
                    const buffered_ev: ?Event = blk: {
                        const header_end = it.buf.start + msg.Header.Size;
                        if (header_end > it.buf.end) {
                            break :blk null;
                        }

                        const header = std.mem.bytesToValue(msg.Header, it.buf.data[it.buf.start..header_end]);

                        const data_end = it.buf.start + header.msg_size;

                        if (data_end > it.buf.end) {
                            std.log.err("data too big: {d} ... end: {d}", .{ data_end, it.buf.end });
                            if (it.buf.start == 0) {
                                return error.BufTooSmol;
                            }

                            break :blk null;
                        }
                        defer it.buf.start = data_end;

                        break :blk .{
                            .header = header,
                            .data = it.buf.data[header_end..data_end],
                        };
                    };

                    if (buffered_ev) |ev| return ev;

                    const data_in_stream = blk: {
                        var poll: [1]std.posix.pollfd = [_]std.posix.pollfd{.{
                            .fd = it.stream.handle,
                            .events = std.posix.POLL.IN,
                            .revents = 0,
                        }};
                        const bytes_ready = std.posix.poll(&poll, 0) catch |err| poll_blk: {
                            log.warn("  Event Iterator :: Socket Poll Error :: {s}", .{@errorName(err)});
                            break :poll_blk 0;
                        };
                        break :blk bytes_ready > 0;
                    };

                    if (data_in_stream) {
                        it.load_events() catch |err| {
                            log.err("  Event Iterator :: {s}", .{@errorName(err)});
                            return err;
                        };
                    } else {
                        return null;
                    }
                }
            }

            pub fn next_fd(it: *Iterator) ?std.posix.fd_t {
                if (it.fd_queue.read == it.fd_queue.write)
                    return null;

                defer it.fd_queue.read += 1;
                return it.fd_queue.data[it.fd_queue.read];
            }
            pub fn peek_fd(it: *Iterator) ?std.posix.fd_t {
                if (it.fd_queue.read == it.fd_queue.write)
                    return null;

                return it.fd_queue.data[it.fd_queue.read];
            }
        };
    }
};

const cmsg = msg.cmsg;
const SCM_RIGHTS = 0x01;
fn receive_cmsg(socket: std.posix.socket_t, buf: []u8) ?std.posix.fd_t {
    var cmsg_buf: [cmsg(std.posix.fd_t).Size * 12]u8 = undefined;

    var iov = [_]std.posix.iovec{
        .{
            .base = buf.ptr,
            .len = buf.len,
        },
    };

    var message: std.posix.msghdr = .{
        .name = null,
        .namelen = 0,
        .iov = &iov,
        .iovlen = 1,
        .control = &cmsg_buf,
        .controllen = cmsg_buf.len,
        .flags = 0,
    };

    const rc: usize = std.os.linux.recvmsg(socket, &message, std.os.linux.MSG.PEEK | std.os.linux.MSG.DONTWAIT);

    const res = res: {
        if (@as(isize, @bitCast(rc)) < 0) {
            const err = std.posix.errno(rc);
            log.err("recvmsg failed with err: {s}", .{@tagName(err)});
            break :res null;
        } else {
            const cmsg_t = cmsg(std.posix.fd_t);
            const cmsg_size = cmsg_t.Size - cmsg_t.Padding;
            var offset: usize = 0;
            while (offset + cmsg_size <= message.controllen) {
                const ctrl_buf: [*]u8 = @ptrCast(message.control.?);
                const ctrl_msg: *align(1) cmsg(std.posix.fd_t) = @ptrCast(@alignCast(ctrl_buf[offset..][0..64]));

                if (ctrl_msg.type == std.posix.SOL.SOCKET and ctrl_msg.level == SCM_RIGHTS)
                    break :res ctrl_msg.data;
            }
            offset += 1;
        }
        break :res null;
    };

    return res;
}

const Vec2I32 = struct {
    x: i32,
    y: i32,

    pub const zero: Vec2I32 = .{ .x = 0, .y = 0 };
};

pub const Surface = struct {
    pub const Flags = packed struct {
        acked: bool = false,
        closed: bool = false,
        focused: bool = true,
    };

    flags: Flags = .{},
    Client: *Client,
    id: []const u8,
    title: []const u8,
    wl_surface: wl.Surface,
    xdg_surface: xdg.Surface,
    toplevel: xdg.Toplevel,
    decorations: xdgd.ToplevelDecorationV1,
    buffers: [BufCount]wl.Buffer,
    cur_buf: usize,
    dims: Vec2I32,
    pos: Vec2I32,
    fps_target: i32 = 60,

    pub const nil: Surface = .{
        .wl_surface = .{ .id = 0 },
        .xdg_surface = .{ .id = 0 },
        .toplevel = .{ .id = 0 },
        .decorations = .{ .id = 0 },
        .buffers = undefined,
        .cur_buf = 0,
        .dims = .zero,
        .pos = .zero,
        .fps_target = 0,
    };

    const init_params = struct {
        client: *Client,
        app_id: ?[]const u8 = null,
        surface_title: ?[]const u8 = null,
        compositor: wl.Compositor,
        wm_base: xdg.WmBase,
        decoration_manager: xdgd.DecorationManagerV1,
        buffers: ?[BufCount]wl.Buffer = null,
        dims: ?Vec2I32 = null,
        pos: ?Vec2I32 = null,
        fps_target: ?i32 = null,
    };

    pub fn init(
        params: init_params,
    ) Surface {
        const writer = params.client.connection.writer();
        const wl_surface = params.compositor.create_surface(writer, .{}) catch |err| {
            log.err("Failed to create new surface due to err :: {s}", .{@errorName(err)});
            return .nil;
        };

        const xdg_surface = params.wm_base.get_xdg_surface(writer, .{ .surface = wl_surface.id }) catch |err| {
            log.err("failed to create new xdg_surface due to err :: {s}", .{@errorName(err)});
            wl_surface.destroy(writer, .{}) catch |derr| {
                log.err("Failed to send destroy message for wl_surface with err :: {s}", .{@errorName(derr)});
            };
            return .nil;
        };

        const xdg_toplevel = xdg_surface.get_toplevel(writer, .{}) catch |err| {
            log.err("failed to create new xdg_toplevel due to err :: {s}", .{@errorName(err)});
            wl_surface.destroy(writer, .{}) catch |derr| {
                log.err("Failed to send destroy message for wl_surface with err :: {s}", .{@errorName(derr)});
            };
            xdg_surface.destroy(writer, .{}) catch |derr| {
                log.err("Failed to send destroy message for xdg_surface with err :: {s}", .{@errorName(derr)});
            };
            return .nil;
        };

        if (params.app_id) |id| xdg_toplevel.set_app_id(writer, .{ .app_id = id }) catch |err| {
            log.warn("Failed to set app_id due to err: {s}", .{@errorName(err)});
        };
        if (params.surface_title) |title| xdg_toplevel.set_title(writer, .{ .title = title }) catch |err| {
            log.warn("Failed to set toplevel title due to err: {s}", .{@errorName(err)});
        };

        wl_surface.commit(writer, .{}) catch |err| {
            log.warn("Failed to commit wl_surface due to err: {s}", .{@errorName(err)});
        };

        const decorations = params.decoration_manager.get_toplevel_decoration(writer, .{ .toplevel = xdg_toplevel.id }) catch |err| {
            log.err("Failed to create toplevel_decorations due to err :: {s}", .{@errorName(err)});
            wl_surface.destroy(writer, .{}) catch |derr| {
                log.err("Failed to send destroy message for wl_surface with err :: {s}", .{@errorName(derr)});
            };
            xdg_surface.destroy(writer, .{}) catch |derr| {
                log.err("Failed to send destroy message for xdg_surface with err :: {s}", .{@errorName(derr)});
            };
            xdg_toplevel.destroy(writer, .{}) catch |derr| {
                log.err("Failed to send destroy message for xdg_toplevel with err :: {s}", .{@errorName(derr)});
            };
            return .nil;
        };

        return .{
            .client = params.client,
            .id = params.app_id orelse "",
            .title = params.surface_title orelse "",
            .wl_surface = wl_surface,
            .xdg_surface = xdg_surface,
            .decorations = decorations,
            .buffers = params.buffers orelse undefined,
            .cur_buf = 0,
            .dims = params.dims orelse .zero,
            .pos = params.pos orelse .zero,
            .fps_target = params.fps_target orelse 60,
        };
    }

    pub fn init_buffers(
        surface: *Surface,
        fd: [BufCount]std.posix.fd_t,
    ) !void {
        for (0..BufCount) |idx| {
            const buffer = create_buffer(surface, fd[idx], surface.client.gfx_format, surface.dims);
            if (buffer.id != 0) surface.buffers[idx] = buffer else return error.FailedToCreateBuffer;
        }

        surface.wl_surface.attach(surface.client.connection.writer(), .{
            .buffer = surface.buffers[0],
            .x = 0,
            .y = 0,
        }) catch return error.FailedToAttachBuffer;
        surface.wl_surface.commit(surface.client.connection.writer(), .{}) catch return error.FailedToCommitSurface;
    }

    fn create_buffer(
        surface: *Surface,
        fd: std.posix.fd_t,
        format: Drm.Format,
        dims: Vec2I32,
    ) wl.Buffer {
        const writer = surface.client.connection.writer();

        const dmabuf_params_opt = surface.client.dmabuf.create_params(surface.writer, .{}) catch |err| nil: {
            log.err("Failed to create linux_dmabuf_params due to err :: {s}", .{@errorName(err)});
            break :nil null;
        };

        const wl_buffer = if (dmabuf_params_opt) |dmabuf_params| buffer: {
            defer dmabuf_params.destroy(writer, .{}) catch |err| {
                log.err("Failed to destroy linux_dmabuf_params due to err :: {s}", .{@errorName(err)});
            };

            dmabuf_params.add(writer, .{
                .fd = fd,
                .plane_idx = 0,
                .offset = 0,
                .stride = @intCast(dims.x * 4),
                .modifier_hi = Drm.Modifier.linear.hi(),
                .modifier_lo = Drm.Modifier.linear.lo(),
            }) catch |err| {
                log.err("Failed to add data to linux_dmabuf_params due to err :: {s}", .{@errorName(err)});
                break :buffer .{ .id = 0 };
            };

            const wl_buffer = dmabuf_params.create_immed(writer, .{
                .width = @intCast(dims.x),
                .height = @intCast(dims.y),
                .format = @intFromEnum(format),
                .flags = .{},
            }) catch |err| {
                log.err("Failed to create wl_buffer due to err :: {s}", .{@errorName(err)});
                break :buffer .{ .id = 0 };
            };

            break :buffer wl_buffer;
        } else buffer: {
            break :buffer .{ .id = 0 };
        };
        return wl_buffer;
    }
};

// TESTS
const testing = std.testing;

test "Event Comparisons" {
    const ev: Event = .nil;
    const ev2: Event = .nil;

    const sim_ev_data = "wl_compositor";
    const sim_ev: Event = .{
        .header = .{
            .id = 2, // always the Registry ID
            .op = 0, // global announce op
            .msg_size = sim_ev_data.len,
        },
        .data = sim_ev_data,
    };
    try testing.expect(ev.eql(&ev2));
    try testing.expect(!ev.eql(&sim_ev));
    try testing.expect(sim_ev.eql(&sim_ev));
}

test "Event Iter" {
    const registry: wl.Registry = .{ .id = 2 };

    const sim_ev_str: [:0]const u8 = "wl_compositor";
    const len = 20;
    var sim_ev_data: [len]u8 = undefined;
    const strlen: u32 = sim_ev_str.len;
    const strlen_bytes = std.mem.asBytes(&strlen);

    @memset(&sim_ev_data, 0);
    @memcpy(sim_ev_data[0..4], strlen_bytes);
    @memcpy(sim_ev_data[4 .. 4 + sim_ev_str.len], sim_ev_str);

    const nil_ev: Event = .nil;
    const registry_global = 0;
    const header: msg.Header = .{
        .id = registry.id,
        .op = registry_global, // global announce op
        .msg_size = msg.Header.Size + sim_ev_data.len,
    };
    const sim_ev: Event = .{
        .header = header,
        .data = &sim_ev_data,
    };

    var sim_ev_bytes: [msg.Header.Size + len]u8 = undefined;
    @memcpy(sim_ev_bytes[0..msg.Header.Size], std.mem.asBytes(&header));
    @memcpy(sim_ev_bytes[msg.Header.Size..][0..], &sim_ev_data);

    const iter_buf_len = 256;
    var buf_data: [iter_buf_len]u8 = undefined;
    @memcpy(buf_data[0..sim_ev_bytes.len], &sim_ev_bytes);

    var iter: Event.iter(iter_buf_len) = .{
        .stream = undefined,
        .buf = .{
            .data = buf_data,
            .end = sim_ev_bytes.len,
        },
    };

    const ev = try iter.next() orelse return error.EventIterFailedToReadEvent;

    try testing.expect(sim_ev.eql(&ev));
    try testing.expect(!sim_ev.eql(&nil_ev));
}
