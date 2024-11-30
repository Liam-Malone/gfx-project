const std = @import("std");
const builtin = @import("builtin");

const wl_msg = @import("wl_msg");
const wl = @import("wayland");
const dmab = @import("dmabuf");
const xdg = @import("xdg_shell");
const xdgd = @import("xdg_decoration");

const wl_log = std.log.scoped(.wayland);
const Header = wl_msg.Header;

const vk = @import("vulkan");

const Arena = @import("Arena.zig");

const app_log = std.log.scoped(.app);

// TODO: Remove all `try` usage from main()
pub fn main() !void {
    const return_val: void = exit: {
        var arena: *Arena = .init(.default);
        defer arena.release();

        std.debug.print("sizeof(Arena) = {d}\n", .{@sizeOf(Arena)});
        const socket: std.net.Stream = connect_display(arena) catch |err| {
            app_log.err("Failed to connect to wayland socket with error: {s}\nExiting program now", .{@errorName(err)});
            break :exit err;
        };
        defer socket.close();
        const sock_writer = socket.writer();

        const display: wl.Display = .{ .id = 1 };
        const registry: wl.Registry = .{ .id = 2 };
        display.get_registry(socket.writer(), .{
            .registry = registry.id,
        }) catch |err| {
            app_log.err("Failed to establish registry with error: {s}\nExiting program", .{@errorName(err)});
            break :exit err;
        };

        var interface_registry: InterfaceRegistry = InterfaceRegistry.init(arena, registry) catch |err| {
            app_log.err("Failed to initialize Wayland Interface Registry. Program Cannot Proceed :: {s}", .{@errorName(err)});
            break :exit err;
        };
        defer interface_registry.deinit();

        var wl_event_it: EventIt(4096) = .init(socket);

        // Creating application state
        var state: State = state: {

            //  Create Basic Wayland State
            const wl_state: State.Wayland = wl_state: {
                var wl_seat_opt: ?wl.Seat = null;
                var compositor_opt: ?wl.Compositor = null;
                var xdg_wm_base_opt: ?xdg.WmBase = null;
                var dmabuf_opt: ?dmab.LinuxDmabufV1 = null;
                var xdg_decoration_opt: ?xdgd.DecorationManagerV1 = null;
                wl_event_it.load_events() catch |err| {
                    app_log.err("Failed to load events from socket :: {s}", .{@errorName(err)});
                    break :exit err;
                };

                // Register desired interfaces
                while (wl_event_it.next() catch |err| break :exit err) |ev| {
                    const interface: InterfaceType = interface_registry.get(ev.header.id) orelse blk: {
                        app_log.warn("Recived response for unknown interface: {d}", .{ev.header.id});
                        break :blk .nil_ev;
                    };
                    switch (interface) {
                        .nil_ev => {}, // Do nothing, this is invalid
                        .display => {
                            const response_opt = wl.Display.Event.parse(ev.header.op, ev.data) catch |err| blk: {
                                app_log.err("Failed to parse wl_display event with err: {s}", .{@errorName(err)});
                                break :blk null;
                            };
                            if (response_opt) |response|
                                switch (response) {
                                    .@"error" => |err| log_display_err(err),
                                    .delete_id => {
                                        app_log.warn("Unexpected object delete during binding phase", .{});
                                    },
                                };
                        },
                        .registry => {
                            const action_opt = wl.Registry.Event.parse(ev.header.op, ev.data) catch |err| blk: {
                                app_log.err("Failed to parse wl_registry event with err: {s}", .{@errorName(err)});
                                break :blk null;
                            };
                            if (action_opt) |action|
                                switch (action) {
                                    .global => |global| {
                                        const desired_interfaces = enum {
                                            nil_opt,
                                            wl_seat,
                                            wl_compositor,
                                            xdg_wm_base,
                                            zxdg_decoration_manager_v1,
                                            zwp_linux_dmabuf_v1,
                                        };
                                        const interface_name = std.meta.stringToEnum(desired_interfaces, global.interface) orelse blk: {
                                            app_log.debug("Unused interface: {s}", .{global.interface});
                                            break :blk .nil_opt;
                                        };
                                        switch (interface_name) {
                                            .nil_opt => {}, // do nothing,
                                            .wl_seat => wl_seat_opt = interface_registry.bind(wl.Seat, sock_writer, global) catch |err| nil: {
                                                app_log.err("Failed to bind compositor with error: {s}", .{@errorName(err)});
                                                break :nil null;
                                            },
                                            .wl_compositor => compositor_opt = interface_registry.bind(wl.Compositor, sock_writer, global) catch |err| nil: {
                                                app_log.err("Failed to bind compositor with error: {s}", .{@errorName(err)});
                                                break :nil null;
                                            },
                                            .xdg_wm_base => xdg_wm_base_opt = interface_registry.bind(xdg.WmBase, sock_writer, global) catch |err| nil: {
                                                app_log.err("Failed to bind xdg_wm_base with error: {s}", .{@errorName(err)});
                                                break :nil null;
                                            },
                                            .zxdg_decoration_manager_v1 => xdg_decoration_opt = interface_registry.bind(xdgd.DecorationManagerV1, sock_writer, global) catch |err| nil: {
                                                app_log.err("Failed to bind zxdg__decoration_manager with error: {s}", .{@errorName(err)});
                                                break :nil null;
                                            },
                                            .zwp_linux_dmabuf_v1 => dmabuf_opt = interface_registry.bind(dmab.LinuxDmabufV1, sock_writer, global) catch |err| nil: {
                                                app_log.err("Failed to bind linux_dmabuf with error: {s}", .{@errorName(err)});
                                                break :nil null;
                                            },
                                        }
                                    },
                                    .global_remove => {
                                        app_log.warn("No registry to remove global from", .{});
                                    },
                                };
                        },
                        else => {
                            log_unused_event(interface, ev) catch |err| {
                                app_log.err("Failed to log unused event with err: {s}", .{@errorName(err)});
                            };
                        },
                    }
                }

                const compositor: wl.Compositor = compositor_opt orelse {
                    const err = error.NoWaylandCompositor;
                    wl_log.err("Fatal error encountered, program cannot continue. Error: {s}", .{@errorName(err)});
                    break :exit err;
                };

                const xdg_wm_base: xdg.WmBase = xdg_wm_base_opt orelse {
                    const err = error.NoXdgWmBase;
                    wl_log.err("Fatal error encountered, program cannot continue. Error: {s}", .{@errorName(err)});
                    break :exit err;
                };

                const xdg_decoration_manager = xdg_decoration_opt orelse {
                    const err = error.NoXdgDecorationManager;
                    wl_log.err("Fatal error encountered, program cannot continue. Error: {s}", .{@errorName(err)});
                    break :exit err;
                };

                const wl_seat: wl.Seat = wl_seat_opt orelse {
                    const err = error.NoWaylandSeat;
                    wl_log.err("Fatal Error encountered, program cannot continue. Error: {s}", .{@errorName(err)});
                    break :exit err;
                };

                const dmabuf: dmab.LinuxDmabufV1 = dmabuf_opt orelse {
                    const err = error.NoDmabuf;
                    wl_log.err("Fatal Error encountered, program cannot continue. Error: {s}", .{@errorName(err)});
                    break :exit err;
                };

                const wl_surface: wl.Surface = try interface_registry.register(wl.Surface);
                try compositor.create_surface(sock_writer, .{ .id = wl_surface.id });

                const xdg_surface = try interface_registry.register(xdg.Surface);
                try xdg_wm_base.get_xdg_surface(sock_writer, .{
                    .id = xdg_surface.id,
                    .surface = wl_surface.id,
                });

                const xdg_toplevel = try interface_registry.register(xdg.Toplevel);
                try xdg_surface.get_toplevel(sock_writer, .{ .id = xdg_toplevel.id });

                try wl_surface.commit(sock_writer, .{});

                const decoration_toplevel = try interface_registry.register(xdgd.ToplevelDecorationV1);
                try xdg_decoration_manager.get_toplevel_decoration(sock_writer, .{ .id = decoration_toplevel.id, .toplevel = xdg_toplevel.id });
                break :wl_state .{
                    .display = display,
                    .registry = registry,
                    .compositor = compositor,
                    .interface_registry = interface_registry,
                    .seat = wl_seat,
                    .xdg_wm_base = xdg_wm_base,
                    .decoration_manager = xdg_decoration_manager,
                    .dmabuf = dmabuf,

                    .sock_writer = sock_writer,
                    .wl_surface = wl_surface,
                    .xdg_surface = xdg_surface,
                    .xdg_toplevel = xdg_toplevel,
                    .decoration_toplevel = decoration_toplevel,
                };
            };

            // Create Vulkan Instance
            {
                // TODO
            }

            break :state .{
                .wayland = wl_state,
                .vulkan = .{},
                .running = true,
            };
        };

        defer state.deinit();
        // Looping wl_event handler thread
        const ev_thread = std.Thread.spawn(.{}, handle_wl_events, .{ &state, &wl_event_it }) catch |err| {
            app_log.err("Event thread died with err: {s}", .{@errorName(err)});
            break :exit err;
        };

        // main loop
        while (state.running) {
            // Do stuff
        }
        ev_thread.join();
    } catch |err| { // program err exit path
        app_log.err("Program exiting due to error: {s}", .{@errorName(err)});
        std.process.exit(1);
    };

    // program err-free exit path
    return return_val;
}

const State = struct {
    const Wayland = struct {
        display: wl.Display,
        registry: wl.Registry,
        compositor: wl.Compositor,
        interface_registry: InterfaceRegistry,
        seat: wl.Seat,
        xdg_wm_base: xdg.WmBase,
        decoration_manager: xdgd.DecorationManagerV1,
        dmabuf: dmab.LinuxDmabufV1,

        sock_writer: std.net.Stream.Writer,
        wl_surface: wl.Surface,
        xdg_surface: xdg.Surface,
        xdg_toplevel: xdg.Toplevel,
        decoration_toplevel: xdgd.ToplevelDecorationV1,
    };
    const Vulkan = struct {};

    wayland: Wayland,
    vulkan: Vulkan,
    running: bool,

    pub fn deinit(state: *State) void {
        {
            var wl_state = state.wayland;
            wl_state.xdg_wm_base.destroy(wl_state.sock_writer, .{}) catch |err| {
                wl_log.err("Failed to send destroy message to xdg_wm_base:: Error: {s}", .{@errorName(err)});
            };

            wl_state.decoration_manager.destroy(wl_state.sock_writer, .{}) catch |err| {
                wl_log.err("Failed to send release message to xdg_decoration_manager:: Error: {s}", .{@errorName(err)});
            };

            wl_state.wl_surface.destroy(wl_state.sock_writer, .{}) catch |err| {
                wl_log.err("Failed to send destroy message to wl_surface:: Error: {s}", .{@errorName(err)});
            };

            wl_state.xdg_surface.destroy(wl_state.sock_writer, .{}) catch |err| {
                wl_log.err("Failed to send release message to xdg_surface:: Error: {s}", .{@errorName(err)});
            };

            wl_state.xdg_toplevel.destroy(wl_state.sock_writer, .{}) catch |err| {
                wl_log.err("Failed to send release message to xdg_toplevel:: Error: {s}", .{@errorName(err)});
            };

            wl_state.decoration_toplevel.destroy(wl_state.sock_writer, .{}) catch |err| {
                wl_log.err("Failed to send release message to xdg_decoration_toplevel:: Error: {s}", .{@errorName(err)});
            };

            wl_state.decoration_manager.destroy(wl_state.sock_writer, .{}) catch |err| {
                wl_log.err("Failed to send destroy message to xdg_decoration_manager:: Error: {s}", .{@errorName(err)});
            };

            wl_state.seat.release(wl_state.sock_writer, .{}) catch |err| {
                wl_log.err("Failed to send release message to wl_seat:: Error: {s}", .{@errorName(err)});
            };
        }
    }
};

fn handle_wl_events(state: *State, event_iterator: *EventIt(4096)) !void {
    var wl_state = state.wayland;
    while (true) {
        const ev = event_iterator.next() catch |err| blk: {
            switch (err) {
                error.RemoteClosed, error.BrokenPipe, error.StreamClosed => {
                    app_log.err("encountered err: {any}", .{err});
                    return err;
                },
                else => {
                    app_log.err("encountered err: {any}", .{err});
                },
            }
            break :blk Event.nil;
        } orelse Event.nil;
        const interface = wl_state.interface_registry.get(ev.header.id) orelse .nil_ev;
        switch (interface) {
            .nil_ev => {
                // nil event handle
            },
            .xdg_wm_base => {
                const action_opt: ?xdg.WmBase.Event = xdg.WmBase.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .ping => |ping| {
                            try wl_state.xdg_wm_base.pong(wl_state.sock_writer, .{
                                .serial = ping.serial,
                            });
                        },
                    };
            },
            .xdg_surface => {
                const action_opt: ?xdg.Surface.Event = xdg.Surface.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .configure => |configure| {
                            try wl_state.xdg_surface.ack_configure(wl_state.sock_writer, .{ .serial = configure.serial });
                        },
                    };
            },
            .xdg_toplevel => {
                const action_opt: ?xdg.Toplevel.Event = xdg.Toplevel.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .configure => |configure| {
                            _ = configure; // compositor can't tell me what to do!!!
                        },
                        .close => { //  Empty struct, nothing to capture
                            app_log.info("server is closing this toplevel", .{});
                            app_log.warn("toplevel close handling not yet fully implemented", .{});
                            state.running = false;
                            break;
                        },
                        else => {
                            try log_unused_event(interface, ev);
                        },
                    };
            },
            else => {
                try log_unused_event(interface, ev);
            },
        }
    }
}

/// Connect To Wayland Display
///
/// Assumes Arena Allocator -- does not manage own memory
fn connect_display(arena: *Arena) !std.net.Stream {
    const xdg_runtime_dir = std.posix.getenv("XDG_RUNTIME_DIR") orelse return error.NoXdgRuntime;
    const wayland_display = std.posix.getenv("WAYLAND_DISPLAY") orelse return error.NoWaylandDisplay;

    const sock_path = join(arena, xdg_runtime_dir, wayland_display, "/");
    return try std.net.connectUnixSocket(sock_path);
}

fn log_display_err(err: wl.Display.Event.Error) void {
    wl_log.err("wl_display::error => object id: {d}, code: {d}, msg: {s}", .{
        err.object_id,
        err.code,
        err.message,
    });
}
fn join(arena: *Arena, left: []const u8, right: []const u8, sep: []const u8) []const u8 {
    const len = left.len + right.len + sep.len;
    const out_buf = arena.push(u8, len);
    @memcpy(out_buf[0..left.len], left);
    @memcpy(out_buf[left.len..][0..sep.len], sep);
    @memcpy(out_buf[left.len + sep.len ..][0..], right);

    return out_buf;
}

// TODO: find a way to auto-gen this maybe?
const InterfaceType = enum {
    nil_ev,
    display,
    registry,
    compositor,
    wl_seat,
    wl_surface,
    wl_callback,
    xdg_wm_base,
    xdg_surface,
    xdg_toplevel,
    xdg_decoration_manager,
    xdg_decoration_toplevel,
    dmabuf,
    dmabuf_params,
    dmabuf_feedback,

    pub fn from_type(comptime T: type) !InterfaceType {
        return switch (T) {
            wl.Seat => .wl_seat,
            wl.Display => .display,
            wl.Registry => .registry,
            wl.Compositor => .compositor,
            wl.Surface => .wl_surface,
            wl.Callback => .wl_callback,

            xdg.WmBase => .xdg_wm_base,
            xdg.Surface => .xdg_surface,
            xdg.Toplevel => .xdg_toplevel,

            xdgd.DecorationManagerV1 => .xdg_decoration_manager,
            xdgd.ToplevelDecorationV1 => .xdg_decoration_toplevel,

            dmab.LinuxDmabufV1 => .dmabuf,
            dmab.LinuxBufferParamsV1 => .dmabuf_params,
            dmab.LinuxDmabufFeedbackV1 => .dmabuf_feedback,

            else => {
                @compileLog("Unsupported interface: {s}", .{@typeName(T)});
                unreachable;
            },
        };
    }
};
const InterfaceRegistry = struct {
    idx: u32,
    elems: InterfaceMap,
    registry: wl.Registry,

    const InterfaceMap = std.AutoHashMap(u32, InterfaceType);

    pub fn init(arena: *Arena, registry: wl.Registry) !InterfaceRegistry {
        var map: InterfaceMap = InterfaceMap.init(arena.allocator());

        try map.put(0, .nil_ev);
        try map.put(1, .display);
        try map.put(registry.id, .registry);

        return .{
            .idx = registry.id + 1,
            .elems = map,
            .registry = registry,
        };
    }

    pub fn deinit(self: *InterfaceRegistry) void {
        self.elems.deinit();
    }

    pub fn get(self: *InterfaceRegistry, idx: u32) ?InterfaceType {
        return self.elems.get(idx);
    }

    pub fn bind(self: *InterfaceRegistry, comptime T: type, writer: anytype, params: wl.Registry.Event.Global) !T {
        defer self.idx += 1;

        try self.registry.bind(writer, .{
            .name = params.name,
            .id_interface = params.interface,
            .id_interface_version = params.version,
            .id = self.idx,
        });

        try self.elems.put(self.idx, try .from_type(T));
        return .{
            .id = self.idx,
        };
    }

    pub fn register(self: *InterfaceRegistry, comptime T: type) !T {
        defer self.idx += 1;

        try self.elems.put(self.idx, try .from_type(T));
        return .{
            .id = self.idx,
        };
    }
};

fn log_unused_event(interface: InterfaceType, event: Event) !void {
    switch (interface) {
        .nil_ev => app_log.debug("Encountered unused nil event", .{}),
        .display => {
            const parsed = try wl.Display.Event.parse(event.header.op, event.data);
            switch (parsed) {
                .@"error" => |err| log_display_err(err),
                else => {
                    app_log.debug("Unused event: {any}", .{parsed});
                },
            }
        },
        .registry => {
            app_log.debug("Unused event: {any}", .{try wl.Registry.Event.parse(event.header.op, event.data)});
        },
        .wl_seat => {
            app_log.debug("Unused event: {any}", .{try wl.Seat.Event.parse(event.header.op, event.data)});
        },
        .wl_surface => {
            app_log.debug("Unused event: {any}", .{try wl.Surface.Event.parse(event.header.op, event.data)});
        },
        .compositor => unreachable, // wl_compositor has no events
        .wl_callback => {
            app_log.debug("Unused event: {any}", .{try wl.Callback.Event.parse(event.header.op, event.data)});
        },
        .xdg_wm_base => {
            app_log.debug("Unused event: {any}", .{try xdg.WmBase.Event.parse(event.header.op, event.data)});
        },
        .xdg_surface => {
            app_log.debug("Unused event: {any}", .{try xdg.Surface.Event.parse(event.header.op, event.data)});
        },
        .xdg_toplevel => {
            app_log.debug("Unused event: {any}", .{try xdg.Toplevel.Event.parse(event.header.op, event.data)});
        },
        .xdg_decoration_manager => unreachable, // xdg_decoration_manager has no events
        .xdg_decoration_toplevel => {
            app_log.debug("Unused event: {any}", .{try xdgd.ToplevelDecorationV1.Event.parse(event.header.op, event.data)});
        },
        .dmabuf => {
            app_log.debug("Unused event: {any}", .{try dmab.LinuxDmabufV1.Event.parse(event.header.op, event.data)});
        },
        .dmabuf_params => {
            app_log.debug("Unused event: {any}", .{try dmab.LinuxBufferParamsV1.Event.parse(event.header.op, event.data)});
        },
        .dmabuf_feedback => {
            app_log.debug("Unused event: {any}", .{try dmab.LinuxDmabufFeedbackV1.Event.parse(event.header.op, event.data)});
        },
    }
}

const Event = struct {
    header: Header,
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
};
/// Event Iterator
///
/// Contains Data Stream & Shifting Buffer
fn EventIt(comptime buf_size: comptime_int) type {
    return struct {
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
        const Iterator = @This();

        pub fn init(stream: std.net.Stream) Iterator {
            return .{
                .stream = stream,
            };
        }

        /// Calls `.shift()` on data buffer, and reads in new bytes from stream
        fn load_events(iter: *Iterator) !void {
            wl_log.info("  Event Iterator :: Loading Events", .{});
            iter.buf.shift();
            const bytes_read: usize = try iter.stream.read(iter.buf.data[iter.buf.end..]); // This does not hang
            if (bytes_read == 0) {
                return error.RemoteClosed;
            }
            iter.buf.end += bytes_read;
        }

        const IteratorErrors = error{
            StreamClosed,
            BrokenPipe,
            BufTooSmol,
            RemoteClosed,
            SystemResources,
            Unexpected,
            NetworkSubsystemFailed,
            InputOutput,
            AccessDenied,
            OperationAborted,
            LockViolation,
            WouldBlock,
            ConnectionResetByPeer,
            ProcessNotFound,
            ConnectionTimedOut,
            IsDir,
            NotOpenForReading,
            SocketNotConnected,
            Canceled,
        };
        /// Get next message from stored buffer
        /// When the buffer is filled, the follwing call to `.next()` will overwrite all messages that have already been read
        ///
        /// See: `ShiftBuf.shift()`
        pub fn next(iter: *Iterator) IteratorErrors!?Event {
            while (true) {
                const buffered_ev: ?Event = blk: {
                    const header_end = iter.buf.start + Header.Size;
                    if (header_end > iter.buf.end) {
                        break :blk null;
                    }

                    const header = std.mem.bytesToValue(Header, iter.buf.data[iter.buf.start..header_end]);

                    const data_end = iter.buf.start + header.msg_size;

                    if (data_end > iter.buf.end) {
                        std.log.err("data too big: {d} ... end: {d}", .{ data_end, iter.buf.end });
                        if (iter.buf.start == 0) {
                            return error.BufTooSmol;
                        }

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
                    const bytes_ready = std.posix.poll(&poll, 0) catch |err| poll_blk: {
                        wl_log.warn("  Event Iterator :: Socket Poll Error :: {s}", .{@errorName(err)});
                        break :poll_blk 0;
                    };
                    break :blk bytes_ready > 0;
                };

                if (data_in_stream) {
                    iter.load_events() catch |err| {
                        switch (err) {
                            error.RemoteClosed => {
                                wl_log.warn("  Event Iterator :: {s}", .{@errorName(err)});
                                return err;
                            },
                            error.BrokenPipe => {
                                wl_log.warn("  Event Iterator :: {s}", .{@errorName(err)});
                                return err;
                            },
                            else => wl_log.warn("  Event Iterator :: {s}", .{@errorName(err)}),
                        }
                        return null;
                    };
                } else {
                    return null;
                }
            }
        }
    };
}

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
    const header: Header = .{
        .id = registry.id,
        .op = registry_global, // global announce op
        .msg_size = Header.Size + sim_ev_data.len,
    };
    const sim_ev: Event = .{
        .header = header,
        .data = &sim_ev_data,
    };

    var sim_ev_bytes: [Header.Size + len]u8 = undefined;
    @memcpy(sim_ev_bytes[0..Header.Size], std.mem.asBytes(&header));
    @memcpy(sim_ev_bytes[Header.Size..][0..], &sim_ev_data);

    const iter_buf_len = 256;
    var buf_data: [iter_buf_len]u8 = undefined;
    @memcpy(buf_data[0..sim_ev_bytes.len], &sim_ev_bytes);

    var iter: EventIt(iter_buf_len) = .{
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

test "Arena" {
    _ = Arena;
}
