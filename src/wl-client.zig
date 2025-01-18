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

const msg = @import("wl-msg.zig");

const log = std.log.scoped(.@"wayland-client");

const Client = @This();

pub const nil: Client = .{
    // Client arena
    .arena = undefined,

    // Base Wayland Connection
    .socket = -1,
    .connection = undefined,

    // Required Wayland Global Objects
    .display = undefined,
    .registry = undefined,
    .compositor = undefined,
    .seat = undefined,
    .wm_base = undefined,
    .decorations = undefined,
    .dmabuf = undefined,

    // Windows
    .surfaces = undefined,

    // Display/Graphics formats
    .gfx_format = undefined,
    .format_mod_pairs = undefined,
    .supported_format_mod_pairs = undefined,

    // Input devices
    .keyboard = undefined, // Keyboard/OtherDevice input
    .pointer = undefined, // Mouse/Trackpad input
    .touch = undefined, // Touchscreen input

    .should_exit = false,

    // Wayland event handling
    .ev_thread = undefined,
};

// Arena for longer-lived allocations
arena: *Arena,

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

// Display/Graphics formats
gfx_format: Drm.Format,
format_mod_pairs: []FormatModPair,
supported_format_mod_pairs: []FormatModPair,

// Input devices
keyboard: wl.Keyboard, // Keyboard/OtherDevice input
pointer: wl.Pointer, // Mouse/Trackpad input
touch: wl.Touch, // Touchscreen input

should_exit: bool = false,
// Wayland event handling
ev_thread: std.Thread,

pub var ev_iter: Event.iter(4096) = undefined;

pub fn init(arena: *Arena) *Client {
    const alloc = arena.allocator();
    const connection = open_connection: {
        const xdg_runtime_dir = std.posix.getenv("XDG_RUNTIME_DIR") orelse return @constCast(&Client.nil);
        const wayland_display = std.posix.getenv("WAYLAND_DISPLAY") orelse return @constCast(&Client.nil);

        const sock_path = std.mem.join(alloc, "/", &[_][]const u8{ xdg_runtime_dir, wayland_display }) catch return @constCast(&Client.nil);
        break :open_connection std.net.connectUnixSocket(sock_path) catch return @constCast(&Client.nil);
    };

    const display: wl.Display = .{ .id = 1 };
    const connection_writer = connection.writer();

    interface.registry = interface.Registry.init(alloc, display) catch return @constCast(&Client.nil);
    _ = display.get_registry(connection_writer, .{}) catch return @constCast(&Client.nil);

    var compositor_opt: ?wl.Compositor = null;
    var seat_opt: ?wl.Seat = null;
    var wm_base_opt: ?xdg.WmBase = null;
    var decorations_opt: ?xdgd.DecorationManagerV1 = null;
    var dmabuf_opt: ?dmab.LinuxDmabufV1 = null;

    ev_iter = .init(connection);
    ev_iter.load_events() catch |err| {
        log.err("Failed to load wayland events with err :: {s}", .{@errorName(err)});
        return @constCast(&Client.nil);
    };

    // Bind interfaces
    while (ev_iter.next() catch return @constCast(&Client.nil)) |ev| {
        if (interface.registry.get(ev.header.id)) |registry_interface| {
            if (registry_interface != .wl_registry) {
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
                            log.err("Failed to bind zxdg_decoration_manager with error: {s}", .{@errorName(err)});
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
                    log.warn("Unexpected global remove event during interface bind stage", .{});
                },
            };
        }
    }

    const wl_compositor = compositor_opt orelse {
        log.err("Failed to bind wl_compositor, cannot continue", .{});
        return @constCast(&Client.nil);
    };
    const wl_seat = seat_opt orelse {
        log.err("Failed to bind wl_compositor, cannot continue", .{});
        return @constCast(&Client.nil);
    };
    const xdg_wm_base = wm_base_opt orelse {
        log.err("Failed to bind wl_compositor, cannot continue", .{});
        return @constCast(&Client.nil);
    };
    const xdg_decorations = decorations_opt orelse {
        log.err("Failed to bind wl_compositor, cannot continue", .{});
        return @constCast(&Client.nil);
    };
    const linux_dmabuf = dmabuf_opt orelse {
        log.err("Failed to bind wl_compositor, cannot continue", .{});
        return @constCast(&Client.nil);
    };

    const wl_keyboard = wl_seat.get_keyboard(connection_writer, .{}) catch |err| {
        log.err("Failed to write wl_seat.get_keyboard() request with err :: {s}", .{@errorName(err)});
        return @constCast(&Client.nil);
    };
    const wl_pointer = wl_seat.get_pointer(connection_writer, .{}) catch |err| {
        log.err("Failed to write wl_seat.get_pointer() request with err :: {s}", .{@errorName(err)});
        return @constCast(&Client.nil);
    };
    const wl_touch = wl_seat.get_touch(connection_writer, .{}) catch |err| {
        log.err("Failed to write wl_seat.get_touch() request with err :: {s}", .{@errorName(err)});
        return @constCast(&Client.nil);
    };

    const client_ptr = arena.create(Client);
    client_ptr.* = .{
        // Arena
        .arena = arena,

        // Base Wayland Connection
        .socket = connection.handle,
        .connection = connection,

        // Global Wayland Objects
        .display = display,
        .registry = &interface.registry,
        .compositor = wl_compositor,
        .seat = wl_seat,
        .wm_base = xdg_wm_base,
        .decorations = xdg_decorations,
        .dmabuf = linux_dmabuf,

        // Windows
        .surfaces = undefined,
        .focused_surface = 0,

        // Graphics/Display formats
        .gfx_format = undefined,
        .format_mod_pairs = undefined,
        .supported_format_mod_pairs = undefined,

        // Inputs
        .keyboard = wl_keyboard,
        .pointer = wl_pointer,
        .touch = wl_touch,

        // Event-Handling
        .ev_thread = undefined,
    };

    const initial_surface: *Surface = arena.create(Surface);
    initial_surface.* = .init(.{
        .app_id = "simple-client",
        .surface_title = "Simple Client",
        .client = client_ptr,
        .compositor = wl_compositor,
        .wm_base = xdg_wm_base,
        .decoration_manager = xdg_decorations,
        .dims = .{ .x = 800, .y = 600 },
    });

    var surfaces: std.ArrayList(*Surface) = .init(arena.allocator());
    surfaces.append(initial_surface) catch {
        log.err("Failed to add initial surface to surfaces list", .{});
    };
    client_ptr.surfaces = surfaces;

    const ev_thread = std.Thread.spawn(.{}, ev_handle_thread, .{client_ptr}) catch |err| {
        log.err("Wayland Event Thread Spawn Failed :: {s}", .{@errorName(err)});
        return @constCast(&Client.nil);
    };

    client_ptr.ev_thread = ev_thread;

    return client_ptr;
}

pub fn deinit(client: *Client) void {
    // At exit:
    // - Close connection
    // - Free client arena
    defer {
        client.registry.deinit();
        client.connection.close();
        client.socket = -1;
        client.arena.release();
    }

    client.ev_thread.join();
    // Release input devices
    if (client.socket != -1) {
        const writer = client.connection.writer();
        client.keyboard.release(writer, .{}) catch |err| {
            log.err("wl_keyboard release failed with err :: {s}", .{@errorName(err)});
        };
        client.pointer.release(writer, .{}) catch |err| {
            log.err("wl_pointer release failed with err :: {s}", .{@errorName(err)});
        };
        client.touch.release(writer, .{}) catch |err| {
            log.err("wl_touch release failed with err :: {s}", .{@errorName(err)});
        };
    }

    // Destroy all surfaces
    {
        for (client.surfaces.items) |surface| {
            surface.destroy();
        }
        client.surfaces.deinit();
    }
}

fn ev_handle_thread(client: *Client) void {
    while (!client.should_exit and client.socket != -1) {
        client.handle_event() catch |err| {
            log.err("Wayland Event Thread Hit Error :: {s}", .{@errorName(err)});
            client.should_exit = true;
        };
    }
}

fn handle_event(client: *Client) !void {
    const event_iterator = &ev_iter;

    const writer = client.connection.writer();
    const ev_opt = try event_iterator.next() orelse blk: {
        std.time.sleep(1_000_000);
        break :blk null;
    };
    if (ev_opt) |ev| {
        const ev_interface = interface.registry.get(ev.header.id) orelse return;
        switch (ev_interface) {
            .wl_display => {
                const action_opt = wl.Display.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .delete_id => |del_id| {
                            log.warn("Compositor acknowledged deletion of ID {d}", .{del_id.id});
                        },
                        .@"error" => |err| {
                            log.err("wl_display::error => object id: {d}, code: {d}, msg: {s}", .{
                                err.object_id,
                                err.code,
                                err.message,
                            });
                        },
                    }
                else
                    log.warn("Failed to parse event for wl_display", .{});
            },
            .wl_seat => {
                const action_opt = wl.Seat.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .name => |name| {
                            log.info("wl_seat name :: {s}", .{name.name});
                        },
                        .capabilities => |capabilities| {
                            log.info("wl_seat capabilities :: pointer : {s}, keyboard : {s}, touch : {s}", .{
                                if (capabilities.capabilities.pointer) "true" else "false",
                                if (capabilities.capabilities.keyboard) "true" else "false",
                                if (capabilities.capabilities.touch) "true" else "false",
                            });
                        },
                    }
                else
                    log.warn("Failed to parse event for wl_seat", .{});
            },
            .wl_keyboard => {
                const kb_ev_opt = wl.Keyboard.Event.parse(ev.header.op, ev.data) catch null;
                if (kb_ev_opt) |kb_ev|
                    switch (kb_ev) {
                        .keymap => |keymap| {
                            const format = keymap.format;

                            if (event_iterator.next_fd()) |fd| {
                                const keymap_data = std.posix.mmap(
                                    null,
                                    keymap.size,
                                    std.posix.PROT.READ,
                                    .{ .TYPE = .PRIVATE },
                                    fd,
                                    0,
                                ) catch |err| {
                                    log.err("zwp_linux_dmabuf_feedback_v1 :: Failed to map format table :: {s}", .{@errorName(err)});
                                    return err;
                                };
                                defer std.posix.munmap(keymap_data);
                                log.debug("wl_keyboard :: Received keymap of size {d} for format: {s}", .{ keymap.size, @tagName(format) });
                            }
                        },
                        else => {
                            log.info("Unused wl_keyboard event :: Header = {{ .id = {d}, .opcode = {d}, .size = {d} }}", .{
                                ev.header.id,
                                ev.header.op,
                                ev.header.msg_size,
                            });
                        },
                    }
                else
                    log.warn("Failed to parse event for wl_keyboard", .{});
            },
            .wl_surface => {
                const action_opt = wl.Surface.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .enter => log.info("wl_surface :: gained focus", .{}),
                        .leave => log.info("wl_surface :: lost focus", .{}),
                        .preferred_buffer_scale => log.info("wl_surface :: received preferred buffer scale", .{}),
                        .preferred_buffer_transform => log.info("wl_surface :: received preferred buffer transform", .{}),
                    }
                else
                    log.warn("Failed to parse event for wl_surface", .{});
            },
            .xdg_wm_base => {
                const action_opt = xdg.WmBase.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .ping => |ping| {
                            client.wm_base.pong(writer, .{
                                .serial = ping.serial,
                            }) catch |err| return err;
                            log.info("ponged ping from xdg_wm_base :: serial = {d}", .{ping.serial});
                        },
                    }
                else
                    log.warn("Failed to parse event for xdg_wm_base", .{});
            },
            .xdg_surface => {
                const action_opt = xdg.Surface.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .configure => |configure| {
                            const focused_surface = client.surfaces.items[client.focused_surface];
                            focused_surface.xdg_surface.ack_configure(writer, .{
                                .serial = configure.serial,
                            }) catch |err| return err;
                            if (!focused_surface.flags.acked) {
                                log.info("Acked configure for xdg_surface", .{});
                                focused_surface.flags.acked = true;
                            }
                        },
                    }
                else
                    log.warn("Failed to parse event for xdg_surface", .{});
            },
            .xdg_toplevel => {
                const action_opt = xdg.Toplevel.Event.parse(ev.header.op, ev.data) catch null;
                const focused_surface = client.surfaces.items[client.focused_surface];
                if (action_opt) |action|
                    switch (action) {
                        .configure => |configure| {
                            if (configure.width > focused_surface.dims.x or configure.height > focused_surface.dims.y) {
                                log.info("Resizing Window :: {d}x{d} -> {d}x{d}", .{
                                    focused_surface.dims.x,
                                    focused_surface.dims.y,
                                    configure.width,
                                    configure.height,
                                });

                                focused_surface.dims.x = configure.width;
                                focused_surface.dims.y = configure.height;
                            }
                        },
                        .close => {
                            log.info("Toplevel Received Close Signal", .{});
                            focused_surface.destroy();
                            _ = client.surfaces.orderedRemove(client.focused_surface);
                            if (client.surfaces.items.len == 0) {
                                client.should_exit = true;
                            }
                        },
                        else => {
                            log.debug("xdg_toplevel :: Unused Event :: Header = {{ .id = {d}, .opcode = {d}, .size = {d} }}", .{
                                ev.header.id,
                                ev.header.op,
                                ev.header.msg_size,
                            });
                        },
                    }
                else
                    log.warn("Failed to parse event for xdg_toplevel", .{});
            },
            .zxdg_toplevel_decoration_v1 => {
                const action_opt = xdgd.ToplevelDecorationV1.Event.parse(ev.header.op, ev.data) catch null;

                if (action_opt) |action|
                    switch (action) {
                        .configure => |configure| {
                            log.info("Toplevel decoration mode set :: {s}", .{@tagName(configure.mode)});
                        },
                    }
                else
                    log.warn("Failed to parse event for zxdg_toplevel_decoration_v1", .{});
            },
            .zwp_linux_dmabuf_feedback_v1 => {
                const feedback_opt = dmab.LinuxDmabufFeedbackV1.Event.parse(ev.header.op, ev.data) catch null;

                if (feedback_opt) |feedback|
                    switch (feedback) {
                        .done => {
                            log.info("zwp_linux_dmabuf_feedback_v1 :: All feedback received", .{});
                        },
                        .format_table => |table| {
                            if (event_iterator.next_fd()) |fd| {
                                const entry_count = table.size / 16;
                                log.info("zwp_linux_dmabuf_feedback_v1 :: Received format table with {d} entries", .{entry_count});

                                const table_data = std.posix.mmap(
                                    null,
                                    table.size,
                                    std.posix.PROT.READ,
                                    .{ .TYPE = .PRIVATE },
                                    fd,
                                    0,
                                ) catch |err| {
                                    log.err("zwp_linux_dmabuf_feedback_v1 :: Failed to map format table :: {s}", .{@errorName(err)});
                                    return err;
                                };
                                defer std.posix.munmap(table_data);
                                client.format_mod_pairs = client.arena.push(FormatModPair, entry_count);

                                var cur_idx: u16 = 0;
                                var iter = std.mem.window(u8, table_data, 16, 16);
                                while (iter.next()) |pair| : (cur_idx += 1) {
                                    const format: Drm.Format = @enumFromInt(std.mem.bytesToValue(u32, pair[0..4]));
                                    const modifier: Drm.Modifier = @enumFromInt(std.mem.bytesToValue(u64, pair[8..]));
                                    client.format_mod_pairs[cur_idx] = .{ .format = format, .modifier = modifier };
                                }

                                client.gfx_format = .abgr8888;
                            }
                        },
                        .main_device => |main_device| {
                            log.info("zwp_linux_dmabuf_feedback_v1 :: Received main_device: {s}", .{main_device.device});
                        },
                        .tranche_done => {
                            log.info("zwp_linux_dmabuf_feedback_v1 :: tranche_done event received", .{});
                        },
                        .tranche_target_device => |target_device| {
                            log.info("zwp_linux_dmabuf_feedback_v1 :: Received tranche_target_device: {s}", .{target_device.device});
                        },
                        .tranche_formats => |tranche_formats| {
                            const entry_count = tranche_formats.indices.len / 2; // 16-bit entries in array of 8-bit values
                            log.info("zwp_linux_dmabuf_feedback_v1 :: Received supported format+modifier table indices with {d} entries", .{entry_count});

                            client.supported_format_mod_pairs = client.arena.push(FormatModPair, entry_count);

                            var cur_idx: u16 = 0;
                            var iter = std.mem.window(u8, tranche_formats.indices, 2, 2);
                            while (iter.next()) |entry| : (cur_idx += 1) {
                                const idx = std.mem.bytesToValue(u16, entry[0..]);
                                client.supported_format_mod_pairs[cur_idx] = client.format_mod_pairs[idx];
                            }
                        },
                        .tranche_flags => |tranche_flags| {
                            log.info("zwp_linux_dmabuf_feedback_v1 :: Received tranche_flags: scanout = {s}", .{
                                if (tranche_flags.flags.scanout) "true" else "false",
                            });
                        },
                    }
                else
                    log.warn("Failed to parse event for zwp_linux_dmabuf_feedback_v1", .{});
            },
            else => {
                log.warn("Unused event :: Header = {{ .id = {d}, .opcode = {d}, .size = {d} }}", .{
                    ev.header.id,
                    ev.header.op,
                    ev.header.msg_size,
                });
            },
        }
    }
}

const FormatModPair = struct {
    format: Drm.Format,
    modifier: Drm.Modifier,
};

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
                it.buf.end = if (it.buf.end > buf_size) buf_size else it.buf.end;
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
                            log.err("data too big: {d} ... end: {d}", .{ data_end, it.buf.end });
                            if (it.buf.start == 0) {
                                return error.BufTooSmol;
                            }

                            break :blk null;
                        }

                        it.buf.start = data_end;

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

            const cmsg = msg.cmsg;
            const fd_cmsg = cmsg(std.posix.fd_t);
            const SCM_RIGHTS = 0x01;
            fn receive_cmsg(socket: std.posix.socket_t, buf: []u8) ?std.posix.fd_t {
                var cmsg_buf: [fd_cmsg.Size * 12]u8 = undefined;

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

                const rc = std.os.linux.recvmsg(socket, &message, std.os.linux.MSG.PEEK | std.os.linux.MSG.DONTWAIT);

                const res = res: {
                    if (@as(isize, @bitCast(rc)) < 0) {
                        const err = std.posix.errno(rc);
                        log.err("recvmsg failed with err: {s}", .{@tagName(err)});
                        break :res null;
                    } else {
                        const cmsg_size = fd_cmsg.Size;
                        var offset: usize = 0;
                        while (offset + cmsg_size <= message.controllen) {
                            const ctrl_buf: [*]u8 = @ptrCast(message.control.?);
                            const ctrl_msg: *align(1) fd_cmsg = @ptrCast(@alignCast(ctrl_buf[offset..][0..fd_cmsg.Size]));

                            if (ctrl_msg.type == std.posix.SOL.SOCKET and ctrl_msg.level == SCM_RIGHTS)
                                break :res ctrl_msg.data;
                        }
                        offset += 1;
                    }
                    break :res null;
                };

                return res;
            }
        };
    }
};

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
    client: *const Client,
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
        .id = "",
        .title = "",
        .client = &Client.nil,
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
        app_id: ?[:0]const u8 = null,
        surface_title: ?[:0]const u8 = null,
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
            .toplevel = xdg_toplevel,
            .decorations = decorations,
            .buffers = params.buffers orelse undefined,
            .cur_buf = 0,
            .dims = params.dims orelse .zero,
            .pos = params.pos orelse .zero,
            .fps_target = params.fps_target orelse 60,
        };
    }
    pub fn destroy(surface: *Surface) void {
        const writer = surface.client.connection.writer();
        for (surface.buffers) |buf| {
            buf.destroy(writer, .{}) catch |err| {
                log.err("Surface :: deinit() :: failed to send wl_buffer.destroy() message with err :: {s}", .{@errorName(err)});
            };
        }
        surface.decorations.destroy(writer, .{}) catch |err| {
            log.err("Surface :: deinit() :: failed to send xdg_decorations.destroy() message with err :: {s}", .{@errorName(err)});
        };
        surface.toplevel.destroy(writer, .{}) catch |err| {
            log.err("Surface :: deinit() :: failed to send xdg_toplevel.destroy() message with err :: {s}", .{@errorName(err)});
        };
        surface.xdg_surface.destroy(writer, .{}) catch |err| {
            log.err("Surface :: deinit() :: failed to send xdg_surface.destroy() message with err :: {s}", .{@errorName(err)});
        };
        surface.wl_surface.destroy(writer, .{}) catch |err| {
            log.err("Surface :: deinit() :: failed to send wl_surface.destroy() message with err :: {s}", .{@errorName(err)});
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
            .buffer = surface.buffers[surface.cur_buf].id,
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

        const dmabuf_params_opt = surface.client.dmabuf.create_params(writer, .{}) catch |err| nil: {
            log.err("Failed to create linux_dmabuf_params due to err :: {s}", .{@errorName(err)});
            break :nil null;
        };

        const wl_buffer = if (dmabuf_params_opt) |dmabuf_params| buffer: {
            log.debug("Creating wl_buffer :: fd = {d}", .{fd});
            dmabuf_params.add(writer, .{
                .fd = fd,
                .plane_idx = 0,
                .offset = 0,
                .stride = @intCast(dims.x * 4),
                .modifier_hi = Drm.Modifier.linear.hi(),
                .modifier_lo = Drm.Modifier.linear.lo(),
            }) catch |err| {
                log.err("Failed to add data to linux_dmabuf_params due to err :: {s}", .{@errorName(err)});
                break :buffer null;
            };

            log.debug("Creating wl_buffer of dimensions :: {d}x{d}", .{ dims.x, dims.y });
            const wl_buffer = dmabuf_params.create_immed(writer, .{
                .width = @intCast(dims.x),
                .height = @intCast(dims.y),
                .format = @intFromEnum(format),
                .flags = .{},
            }) catch |err| {
                log.err("Failed to create wl_buffer due to err :: {s}", .{@errorName(err)});
                break :buffer null;
            };

            dmabuf_params.destroy(writer, .{}) catch |err| {
                log.err("Failed to destroy linux_dmabuf_params due to err :: {s}", .{@errorName(err)});
            };

            break :buffer wl_buffer;
        } else buffer: {
            break :buffer null;
        };

        if (wl_buffer) |buffer| return buffer else return .{ .id = 0 };
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
