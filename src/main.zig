const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;

const xdg = @import("xdg_shell");
const wl = @import("wayland");
const wl_msg = @import("wl_msg");
const wl_log = std.log.scoped(.wayland);
const Header = wl_msg.Header;

pub fn main() !void {
    const return_val: anyerror!void = exit: {
        const stdout = std.io.getStdOut().writer();
        stdout.print("Hello, Wayland!\n", .{}) catch |err| {
            std.log.err("Failed to write to stdout with err: {s}", .{@errorName(err)});
        };

        const arena_backer: Allocator = std.heap.page_allocator;
        var arena: Arena = .init(arena_backer);
        defer arena.deinit();
        const arena_allocator: Allocator = arena.allocator();

        const socket: std.net.Stream = connect_display(arena_allocator) catch |err| {
            std.log.err("Failed to connect to wayland socket with error: {s}\nExiting program now", .{@errorName(err)});
            break :exit err;
        };
        defer socket.close();
        const sock_writer = socket.writer();

        const display: wl.Display = .{ .id = 1 };
        const registry: wl.Registry = .{ .id = 2 };
        display.get_registry(socket.writer(), .{
            .registry = registry.id,
        }) catch |err| {
            std.log.err("Failed to establish registry with error: {s}\nExiting program", .{@errorName(err)});
            break :exit err;
        };

        var interface_registry: InterfaceRegistry = InterfaceRegistry.init(arena_allocator, registry) catch |err| {
            std.log.err("Failed to initialize Wayland Interface Registry. Program Cannot Proceed :: {s}", .{@errorName(err)});
            break :exit err;
        };
        defer interface_registry.deinit();

        // bind interfaces
        var wl_seat_opt: ?wl.Seat = null;
        var wl_shm_opt: ?wl.Shm = null;
        var compositor_opt: ?wl.Compositor = null;
        var xdg_wm_base_opt: ?xdg.WmBase = null;

        var wl_event_it: EventIt(4096) = .init(socket);
        wl_event_it.load_events() catch |err| {
            std.log.err("Failed to load events from socket :: {s}", .{@errorName(err)});
        };

        // Register desired interfaces
        while (wl_event_it.next() catch |err| blk: {
            switch (err) {
                error.RemoteClosed, error.StreamClosed, error.BrokenPipe => {
                    std.log.err("Wayland Socket Disconnected. Program Cannot Proceed :: {s}", .{@errorName(err)});
                    break :exit err;
                },
                else => {
                    std.log.err("Event retrieval failed with err: {s}", .{@errorName(err)});
                },
            }
            break :blk Event.nil;
        }) |ev| {
            const interface: InterfaceType = interface_registry.get(ev.header.id) orelse blk: {
                std.log.warn("Recived response for unknown interface: {d}", .{ev.header.id});
                break :blk .nil_ev;
            };
            switch (interface) {
                .nil_ev => {}, // Do nothing, this is invalid
                .display => {
                    const response_opt = wl.Display.Event.parse(ev.header.op, ev.data) catch |err| blk: {
                        std.log.err("Failed to parse wl_display event with err: {s}", .{@errorName(err)});
                        break :blk null;
                    };
                    if (response_opt) |response|
                        switch (response) {
                            .err => |err| log_display_err(err),
                            .delete_id => {
                                std.log.warn("Unexpected object delete during binding phase", .{});
                            },
                        };
                },
                .registry => {
                    const action_opt = wl.Registry.Event.parse(ev.header.op, ev.data) catch |err| blk: {
                        std.log.err("Failed to parse wl_registry event with err: {s}", .{@errorName(err)});
                        break :blk null;
                    };
                    if (action_opt) |action|
                        switch (action) {
                            .global => |global| {
                                const desired_interfaces = enum {
                                    nil_opt,
                                    wl_seat,
                                    wl_shm,
                                    wl_compositor,
                                    xdg_wm_base,
                                };
                                const interface_name = std.meta.stringToEnum(desired_interfaces, global.interface) orelse blk: {
                                    std.log.debug("Unused interface: {s}", .{global.interface});
                                    break :blk .nil_opt;
                                };
                                switch (interface_name) {
                                    .nil_opt => {}, // do nothing,
                                    .wl_seat => wl_seat_opt = interface_registry.bind(wl.Seat, sock_writer, global) catch |err| nil: {
                                        std.log.err("Failed to bind compositor with error: {s}", .{@errorName(err)});
                                        break :nil null;
                                    },
                                    .wl_shm => wl_shm_opt = try interface_registry.bind(wl.Shm, sock_writer, global),
                                    .wl_compositor => compositor_opt = interface_registry.bind(wl.Compositor, sock_writer, global) catch |err| nil: {
                                        std.log.err("Failed to bind compositor with error: {s}", .{@errorName(err)});
                                        break :nil null;
                                    },
                                    .xdg_wm_base => xdg_wm_base_opt = interface_registry.bind(xdg.WmBase, sock_writer, global) catch |err| nil: {
                                        std.log.err("Failed to bind xdg_wm_base with error: {s}", .{@errorName(err)});
                                        break :nil null;
                                    },
                                }
                            },
                            .global_remove => {
                                std.log.warn("No registry to remove global from", .{});
                            },
                        };
                },
                else => {
                    log_unused_event(interface, ev) catch |err| {
                        std.log.err("Failed to log unused event with err: {s}", .{@errorName(err)});
                    };
                },
            }
        }

        const compositor: wl.Compositor = compositor_opt orelse {
            wl_log.err("Fatal error encountered, program cannot continue. Error: {s}", .{@errorName(error.NoWaylandCompositor)});
            break :exit error.NoWaylandCompositor;
        };
        const xdg_wm_base: xdg.WmBase = xdg_wm_base_opt orelse {
            wl_log.err("Fatal error encountered, program cannot continue. Error: {s}", .{@errorName(error.NoXdgWmBase)});
            break :exit error.NoXdgWmBase;
        };

        // TODO: Add err handling
        const wl_seat: wl.Seat = wl_seat_opt orelse break :exit error.NoWaylandSeat;
        const wl_shm: wl.Shm = wl_shm_opt orelse break :exit error.NoShm;

        const wl_surface: wl.Surface = try interface_registry.register(wl.Surface);
        try compositor.create_surface(sock_writer, .{ .id = wl_surface.id });

        const xdg_surface = try interface_registry.register(xdg.Surface);
        try xdg_wm_base.get_xdg_surface(sock_writer, .{
            .id = xdg_surface.id,
            .surface = wl_surface.id,
        });
        const xdg_toplevel = try interface_registry.register(xdg.Toplevel);
        try xdg_surface.get_toplevel(sock_writer, .{ .id = xdg_toplevel.id });
        std.debug.print("XDG Toplevel id: {d}\n", .{xdg_toplevel.id});

        try wl_surface.commit(sock_writer, .{});

        const shm_buf_width = 960;
        const shm_buf_height = 540;
        const shm_buf_stride = shm_buf_width * 4;
        const shm_buf_size = shm_buf_stride * shm_buf_height;
        const shm_fd = try std.posix.memfd_create("Zig-Wire Wayland", 0);
        try std.posix.ftruncate(shm_fd, shm_buf_size);

        const data = try std.posix.mmap(
            null,
            shm_buf_size,
            std.posix.PROT.READ | std.posix.PROT.WRITE,
            .{ .TYPE = .SHARED },
            shm_fd,
            0,
        );

        // hack until @ptrCast + slice len change is implemented
        {
            const data_u32: [*]u32 = @ptrCast(data);

            for (0..shm_buf_height) |y| {
                for (0..shm_buf_width) |x| {
                    if ((x + y / 8 * 8) % 16 < 8) {
                        data_u32[y * shm_buf_width + x] = 0xFF666666;
                    } else {
                        data_u32[y * shm_buf_width + x] = 0xFFEEEEEE;
                    }
                }
            }
        }
        // create shm pool
        // delay these until after ACK-ing configurations
        const shm_pool: wl.ShmPool = try interface_registry.register(wl.ShmPool);
        const wl_buffer: wl.Buffer = try interface_registry.register(wl.Buffer);

        var state: State = .{
            .display = display,
            .registry = registry,
            .compositor = compositor,
            .interface_registry = interface_registry,
            .seat = wl_seat,
            .shm = wl_shm,
            .xdg_wm_base = xdg_wm_base,

            .sock_writer = sock_writer,
            .shm_pool = shm_pool,
            .wl_buffer = wl_buffer,
            .wl_surface = wl_surface,
            .xdg_surface = xdg_surface,
            .xdg_toplevel = xdg_toplevel,
            .config_acked = false,
            .running = true,
        };

        var attached = false;
        var unmapped = false;

        // Looping wl_event handler thread
        const ev_thread = std.Thread.spawn(.{}, handle_wl_events, .{ &state, &wl_event_it }) catch |err| {
            std.log.err("Event thread died with err: {s}", .{@errorName(err)});

            break :exit err;
        };

        // main loop
        while (state.running) {
            if (state.config_acked and !attached) {
                attached = true;
                std.debug.print("looping again\n", .{});

                try wl_shm.create_pool(sock_writer, .{ .id = shm_pool.id, .fd = shm_fd, .size = shm_buf_size });
                try shm_pool.create_buffer(sock_writer, .{
                    .id = wl_buffer.id,
                    .offset = 0,
                    .width = shm_buf_width,
                    .height = shm_buf_height,
                    .stride = shm_buf_stride,
                    .format = .xrgb8888,
                });

                if (!unmapped) {
                    std.posix.munmap(data);
                    unmapped = true;
                }

                try wl_surface.attach(sock_writer, .{
                    .buffer = wl_buffer.id,
                    .x = 0,
                    .y = 0,
                });
                try wl_surface.commit(sock_writer, .{});
            }
        }
        ev_thread.join();
    };

    return return_val;
}

const State = struct {
    display: wl.Display,
    registry: wl.Registry,
    compositor: wl.Compositor,
    interface_registry: InterfaceRegistry,
    seat: wl.Seat,
    shm: wl.Shm,
    xdg_wm_base: xdg.WmBase,

    sock_writer: std.net.Stream.Writer,
    shm_pool: wl.ShmPool,
    wl_buffer: wl.Buffer,
    wl_surface: wl.Surface,
    xdg_surface: xdg.Surface,
    xdg_toplevel: xdg.Toplevel,
    config_acked: bool,
    running: bool,
};

fn handle_wl_events(state: *State, event_iterator: *EventIt(4096)) !void {
    while (true) {
        const ev = event_iterator.next() catch |err| blk: {
            switch (err) {
                error.RemoteClosed, error.BrokenPipe, error.StreamClosed => {
                    std.log.err("encountered err: {any}", .{err});
                    return err;
                },
                else => {
                    std.log.err("encountered err: {any}", .{err});
                },
            }
            break :blk Event.nil;
        } orelse Event.nil;
        const interface = state.interface_registry.get(ev.header.id) orelse .nil_ev;
        switch (interface) {
            .nil_ev => {
                // nil event handle
            },
            .xdg_wm_base => {
                const action_opt: ?xdg.WmBase.Event = xdg.WmBase.Event.parse(ev.header.op, ev.data) catch null;
                if (action_opt) |action|
                    switch (action) {
                        .ping => |ping| {
                            try state.xdg_wm_base.pong(state.sock_writer, .{
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
                            try state.xdg_surface.ack_configure(state.sock_writer, .{ .serial = configure.serial });
                            state.config_acked = true;
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
                            std.log.warn("toplevel close handling not yet implemented", .{});
                            std.log.info("server is closing this toplevel", .{});
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
fn connect_display(arena: Allocator) !std.net.Stream {
    const xdg_runtime_dir = std.posix.getenv("XDG_RUNTIME_DIR") orelse return error.NoXdgRuntime;
    const wayland_display = std.posix.getenv("WAYLAND_DISPLAY") orelse return error.NoWaylandDisplay;

    const socket_path = try std.fs.path.join(arena, &.{ xdg_runtime_dir, wayland_display });
    defer arena.free(socket_path);
    return try std.net.connectUnixSocket(socket_path);
}

fn log_display_err(err: wl.Display.Event.Error) void {
    wl_log.err("wl_display::error => object id: {d}, code: {d}, msg: {s}", .{
        err.object_id,
        err.code,
        err.message,
    });
}

// TODO: find a way to auto-gen this maybe?
const InterfaceType = enum {
    nil_ev,
    display,
    registry,
    compositor,
    wl_seat,
    wl_shm,
    wl_shm_pool,
    wl_surface,
    wl_buffer,
    wl_callback,
    xdg_wm_base,
    xdg_surface,
    xdg_toplevel,

    pub fn from_type(comptime T: type) !InterfaceType {
        return switch (T) {
            wl.Seat => .wl_seat,
            wl.Shm => .wl_shm,
            wl.ShmPool => .wl_shm_pool,
            wl.Display => .display,
            wl.Registry => .registry,
            wl.Compositor => .compositor,
            wl.Surface => .wl_surface,
            wl.Buffer => .wl_buffer,
            wl.Callback => .wl_callback,

            xdg.WmBase => .xdg_wm_base,
            xdg.Surface => .xdg_surface,
            xdg.Toplevel => .xdg_toplevel,

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

    pub fn init(arena: Allocator, registry: wl.Registry) !InterfaceRegistry {
        var map: InterfaceMap = InterfaceMap.init(arena);

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
        .nil_ev => std.log.debug("Encountered unused nil event", .{}),
        .display => {
            const parsed = try wl.Display.Event.parse(event.header.op, event.data);
            switch (parsed) {
                .err => |err| log_display_err(err),
                else => {
                    std.log.debug("Unused event: {any}", .{parsed});
                },
            }
        },
        .registry => {
            std.log.debug("Unused event: {any}", .{try wl.Registry.Event.parse(event.header.op, event.data)});
        },
        .wl_seat => {
            std.log.debug("Unused event: {any}", .{try wl.Seat.Event.parse(event.header.op, event.data)});
        },
        .wl_shm => {
            std.log.debug("Unused event: {any}", .{try wl.Shm.Event.parse(event.header.op, event.data)});
        },
        .wl_shm_pool => {
            // doesn't exist
        },
        .wl_surface => {
            std.log.debug("Unused event: {any}", .{try wl.Surface.Event.parse(event.header.op, event.data)});
        },
        .compositor => {
            std.log.debug("Unused compositor event", .{});
        },
        .wl_callback => {
            std.log.debug("Unused event: {any}", .{try wl.Callback.Event.parse(event.header.op, event.data)});
        },
        .wl_buffer => {
            std.log.debug("Unused event: {any}", .{try wl.Buffer.Event.parse(event.header.op, event.data)});
        },
        .xdg_wm_base => {
            std.log.debug("Unused event: {any}", .{try xdg.WmBase.Event.parse(event.header.op, event.data)});
        },
        .xdg_surface => {
            std.log.debug("Unused event: {any}", .{try xdg.Surface.Event.parse(event.header.op, event.data)});
        },
        .xdg_toplevel => {
            std.log.debug("Unused event: {any}", .{try xdg.Toplevel.Event.parse(event.header.op, event.data)});
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
                    break :blk bytes_ready > 0;
                };

                if (data_in_stream) {
                    iter.load_events() catch |err| {
                        switch (err) {
                            error.RemoteClosed => {
                                wl_log.warn("  Event Iterator :: !STREAM CLOSED! :: {any}", .{err});
                                return err;
                            },
                            error.BrokenPipe => {
                                wl_log.warn("  Event Iterator :: !PIPE BROKE! :: {any}", .{err});
                                return err;
                            },
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
}
