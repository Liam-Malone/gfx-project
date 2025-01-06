const std = @import("std");
const builtin = @import("builtin");

const wl_msg = @import("wl_msg");
const wl = @import("wayland");
const dmab = @import("linux-dmabuf-v1");
const xdg = @import("xdg-shell");
const xdgd = @import("xdg-decoration-unstable-v1");

const wl_log = std.log.scoped(.wayland);
const Header = wl_msg.Header;

const vk = @import("vulkan");

const Drm = @import("Drm.zig");

const Arena = @import("Arena.zig");
const GraphicsContext = @import("GraphicsContext.zig");

const app_log = std.log.scoped(.app);

// TODO: Remove all `try` usage from main()
pub fn main() !void {
    const return_val: void = exit: {
        var arena: *Arena = .init(.default);
        defer arena.release();

        // Creating application state
        var state: State = state: {

            //  Create Basic Wayland State
            const wl_state: State.Wayland = wl_state: {
                const socket: std.net.Stream = connect_display(arena) catch |err| {
                    app_log.err("Failed to connect to wayland socket with error: {s}\nExiting program now", .{@errorName(err)});
                    break :exit err;
                };
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

                var wl_event_it: EventIt(4096) = .init(socket);

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
                                        if (std.mem.eql(u8, global.interface, wl.Seat.name)) {
                                            wl_seat_opt = interface_registry.bind(wl.Seat, sock_writer, global) catch |err| nil: {
                                                app_log.err("Failed to bind compositor with error: {s}", .{@errorName(err)});
                                                break :nil null;
                                            };
                                        } else if (std.mem.eql(u8, global.interface, wl.Compositor.name)) {
                                            compositor_opt = interface_registry.bind(wl.Compositor, sock_writer, global) catch |err| nil: {
                                                app_log.err("Failed to bind compositor with error: {s}", .{@errorName(err)});
                                                break :nil null;
                                            };
                                        } else if (std.mem.eql(u8, global.interface, xdg.WmBase.name)) {
                                            xdg_wm_base_opt = interface_registry.bind(xdg.WmBase, sock_writer, global) catch |err| nil: {
                                                app_log.err("Failed to bind xdg_wm_base with error: {s}", .{@errorName(err)});
                                                break :nil null;
                                            };
                                        } else if (std.mem.eql(u8, global.interface, xdgd.DecorationManagerV1.name)) {
                                            xdg_decoration_opt = interface_registry.bind(xdgd.DecorationManagerV1, sock_writer, global) catch |err| nil: {
                                                app_log.err("Failed to bind zxdg__decoration_manager with error: {s}", .{@errorName(err)});
                                                break :nil null;
                                            };
                                        } else if (std.mem.eql(u8, global.interface, dmab.LinuxDmabufV1.name)) {
                                            dmabuf_opt = interface_registry.bind(dmab.LinuxDmabufV1, sock_writer, global) catch |err| nil: {
                                                app_log.err("Failed to bind linux_dmabuf with error: {s}", .{@errorName(err)});
                                                break :nil null;
                                            };
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

                try xdg_toplevel.set_app_id(sock_writer, .{ .app_id = "simple-client" });
                try xdg_toplevel.set_title(sock_writer, .{ .title = "Simple Client" });

                try wl_surface.commit(sock_writer, .{});
                const decoration_toplevel = try interface_registry.register(xdgd.ToplevelDecorationV1);
                try xdg_decoration_manager.get_toplevel_decoration(sock_writer, .{ .id = decoration_toplevel.id, .toplevel = xdg_toplevel.id });

                break :wl_state .{
                    .wl_socket = socket,
                    .display = display,
                    .registry = registry,
                    .compositor = compositor,
                    .interface_registry = interface_registry,
                    .seat = wl_seat,
                    .xdg_wm_base = xdg_wm_base,
                    .decoration_manager = xdg_decoration_manager,
                    .dmabuf = dmabuf,

                    .wl_ev_iter = wl_event_it,
                    .sock_writer = sock_writer,
                    .wl_surface = wl_surface,
                    .wl_buffers = undefined,
                    .xdg_surface = xdg_surface,
                    .xdg_toplevel = xdg_toplevel,
                    .decoration_toplevel = decoration_toplevel,
                };
            };

            break :state .{
                .wayland = wl_state,
                .running = true,
                .gfx_format = undefined,
                .graphics_context = undefined,
                .width = 800,
                .height = 600,
            };
        };

        defer state.deinit();
        // Looping wl_event handler thread
        app_log.debug("Spawning Wayland Event Handler Thread", .{});
        const wl_ev_thread = std.Thread.spawn(.{}, handle_wl_events, .{&state}) catch |err| {
            app_log.err("Wayland Event Thread Spawn Failed :: {s}", .{@errorName(err)});
            break :exit err;
        };
        defer wl_ev_thread.join();

        while (!state.wayland.xdg_surface_acked) {
            // Wait for initial xdg_surface config ack
        }
        const feedback = state.wayland.interface_registry.register(dmab.LinuxDmabufFeedbackV1) catch |err| break :exit err;

        state.wayland.dmabuf.get_surface_feedback(state.wayland.sock_writer, .{
            .id = feedback.id,
            .surface = state.wayland.wl_surface.id,
        }) catch |err| break :exit err;

        app_log.debug("Initializing Vulkan State", .{});
        state.graphics_context = vk_state: {
            // Shader loading
            var vert_buf: []u8 = arena.push(u8, 1072);
            const vert_file = std.fs.cwd().openFile("build/shaders/vert.spv", .{ .mode = .read_only }) catch |err| {
                app_log.err("File Open Err :: {s}", .{@errorName(err)});
                state.deinit();
                break :exit err;
            };
            defer vert_file.close();

            const vert_bytes = vert_file.readAll(vert_buf) catch |err| {
                app_log.err("File Read Err :: {s}", .{@errorName(err)});
                state.deinit();
                break :exit err;
            };

            const vert_spv: [*]const u32 = @ptrCast(@alignCast(vert_buf[0..vert_bytes]));

            var frag_buf: []u8 = arena.push(u8, 564);
            const frag_file = std.fs.cwd().openFile("build/shaders/frag.spv", .{ .mode = .read_only }) catch |err| {
                app_log.err("File Open Err :: {s}", .{@errorName(err)});
                state.deinit();
                break :exit err;
            };
            defer frag_file.close();

            const frag_bytes = frag_file.readAll(frag_buf) catch |err| {
                app_log.err("File Read Err :: {s}", .{@errorName(err)});
                state.deinit();
                break :exit err;
            };

            const frag_spv: [*]const u32 = @ptrCast(@alignCast(frag_buf[0..frag_bytes]));

            const screen_width: u32 = @intCast(state.width);
            const screen_height: u32 = @intCast(state.height);

            // Create Vulkan Graphics Context
            app_log.debug("Creating Graphics Context", .{});
            var graphics_context = graphics_context: {
                break :graphics_context GraphicsContext.init(
                    arena,
                    "Simple Window",
                    .{
                        .width = screen_width,
                        .height = screen_height,
                        .depth = 1,
                    },
                    .r8g8b8a8_unorm,
                    false,
                );
            } catch |err| {
                app_log.err("Vulkan Graphics Context creation failed with error: {s}", .{@errorName(err)});
                break :exit error.VulkanInitializationFailed;
            };

            const vk_dev = graphics_context.dev;

            const vert = vk_dev.createShaderModule(&.{
                .code_size = vert_bytes,
                .p_code = vert_spv,
            }, null) catch |err| break :exit err;
            defer vk_dev.destroyShaderModule(vert, null);

            const frag = vk_dev.createShaderModule(&.{
                .code_size = frag_bytes,
                .p_code = frag_spv,
            }, null) catch |err| break :exit err;
            defer vk_dev.destroyShaderModule(frag, null);

            const pipeline_create_res = graphics_context.create_pipelines(&[_]vk.ShaderModule{ vert, frag }, &[_][*:0]const u8{ "main", "main" }) catch |err| break :exit err;
            app_log.debug("Pipeline Creation Returned Code: {s}", .{@tagName(pipeline_create_res)});

            graphics_context.create_framebuffers() catch |err| {
                app_log.err("Failed to Create Initial Vulkan Framebuffers :: {s}", .{@errorName(err)});
                break :exit err;
            };

            for (graphics_context.cmd_bufs, 0..) |cmd_buf, idx| {
                try vk_dev.wrapper.beginCommandBuffer(cmd_buf, &.{
                    .flags = .{},
                });

                const clear_value = [_]vk.ClearValue{.{
                    .color = .{
                        .float_32 = [_]f32{ 1.0, 1.0, 1.0, 1.0 },
                    },
                }};

                vk_dev.wrapper.cmdBeginRenderPass(cmd_buf, &.{
                    .render_pass = graphics_context.render_pass,
                    .framebuffer = graphics_context.framebuffers[idx],
                    .render_area = .{
                        .offset = .{
                            .x = 0,
                            .y = 0,
                        },
                        .extent = .{
                            .width = screen_width,
                            .height = screen_height,
                        },
                    },
                    .clear_value_count = 1,
                    .p_clear_values = &clear_value,
                }, .@"inline");

                vk_dev.wrapper.cmdEndRenderPass(cmd_buf);
                vk_dev.wrapper.endCommandBuffer(cmd_buf) catch |err| break :exit err;
            }

            app_log.debug("Initial Queue Submission", .{});
            vk_dev.wrapper.queueSubmit(graphics_context.graphics_queue.handle, 1, &[_]vk.SubmitInfo{
                .{
                    .command_buffer_count = 1,
                    .p_command_buffers = graphics_context.cmd_bufs.ptr,
                },
            }, .null_handle) catch |err| break :exit err;

            app_log.info("Initial Render Dimensions: {d}x{d}", .{ state.width, state.height });
            // Return constructed state
            break :vk_state graphics_context;
        };

        state.wayland.wl_buffers[0] = state.create_buffer(
            state.graphics_context.mem_fds[0],
            state.gfx_format.wl_format,
        ) catch |err| break :exit err;

        state.wayland.wl_buffers[1] = state.create_buffer(
            state.graphics_context.mem_fds[1],
            state.gfx_format.wl_format,
        ) catch |err| break :exit err;

        state.wayland.wl_surface.commit(state.wayland.sock_writer, .{}) catch |err| break :exit err;

        state.wayland.wl_surface.attach(state.wayland.sock_writer, .{
            .buffer = state.wayland.wl_buffers[0].id,
            .x = 0,
            .y = 0,
        }) catch |err| break :exit err;

        state.wayland.wl_surface.commit(state.wayland.sock_writer, .{}) catch |err| break :exit err;

        var red_val: f32 = 0.0;
        var blu_val: f32 = 0.0;
        var step: f32 = 0.01;
        var cur_frame_idx: usize = 0;
        var prev_time: i64 = std.time.milliTimestamp();
        while (state.running) : (cur_frame_idx = (cur_frame_idx + 1) % state.graphics_context.images.len) {
            const time = std.time.milliTimestamp();

            if (time - prev_time > 32) {
                red_val += step;
                blu_val += step;
                if (red_val >= 1.0 or red_val <= 0.0) {
                    step = -step;
                }

                prev_time = time;

                const vk_dev = state.graphics_context.dev;
                vk_dev.wrapper.queueWaitIdle(state.graphics_context.graphics_queue.handle) catch |err| break :exit err;

                const cmd_buf = &state.graphics_context.cmd_bufs[cur_frame_idx];
                const graphics_queue = state.graphics_context.graphics_queue;

                const clear_value = [_]vk.ClearValue{
                    .{
                        .color = .{
                            .float_32 = [_]f32{ red_val, 0.3, blu_val, 1.0 },
                        },
                    },
                };

                vk_dev.wrapper.beginCommandBuffer(cmd_buf.*, &.{
                    .flags = .{},
                }) catch |err| break :exit err;

                vk_dev.wrapper.cmdBeginRenderPass(cmd_buf.*, &.{
                    .render_pass = state.graphics_context.render_pass,
                    .framebuffer = state.graphics_context.framebuffers[cur_frame_idx],
                    .render_area = .{
                        .offset = .{
                            .x = 0,
                            .y = 0,
                        },
                        .extent = .{
                            .width = @intCast(state.width),
                            .height = @intCast(state.height),
                        },
                    },
                    .clear_value_count = 1,
                    .p_clear_values = &clear_value,
                }, .@"inline");

                vk_dev.wrapper.cmdEndRenderPass(cmd_buf.*);
                vk_dev.wrapper.endCommandBuffer(cmd_buf.*) catch |err| break :exit err;

                if (state.running) {
                    vk_dev.wrapper.queueSubmit(graphics_queue.handle, 1, &[_]vk.SubmitInfo{
                        .{
                            .command_buffer_count = 1,
                            .p_command_buffers = &[_]vk.CommandBuffer{cmd_buf.*},
                        },
                    }, .null_handle) catch |err| break :exit err;

                    state.wayland.wl_surface.damage(state.wayland.sock_writer, .{
                        .x = 0,
                        .y = 0,
                        .width = state.width,
                        .height = state.height,
                    }) catch |err| break :exit err;

                    state.wayland.wl_surface.attach(state.wayland.sock_writer, .{
                        .buffer = state.wayland.wl_buffers[0].id,
                        .x = 0,
                        .y = 0,
                    }) catch |err| break :exit err;
                    state.wayland.wl_surface.commit(state.wayland.sock_writer, .{}) catch |err| break :exit err;
                }
            }
        }
    } catch |err| { // program err exit path
        app_log.err("Program exiting due to error: {s}", .{@errorName(err)});
        std.process.exit(1);
    };

    // program err-free exit path
    return return_val;
}

const State = struct {
    const Wayland = struct {
        wl_socket: std.net.Stream,
        display: wl.Display,
        registry: wl.Registry,
        compositor: wl.Compositor,
        interface_registry: InterfaceRegistry,
        seat: wl.Seat,
        xdg_wm_base: xdg.WmBase,
        decoration_manager: xdgd.DecorationManagerV1,
        dmabuf: dmab.LinuxDmabufV1,

        wl_ev_iter: EventIt(4096),
        sock_writer: std.net.Stream.Writer,
        wl_surface: wl.Surface,
        wl_buffers: [2]wl.Buffer,
        xdg_surface: xdg.Surface,
        xdg_toplevel: ?xdg.Toplevel,
        decoration_toplevel: xdgd.ToplevelDecorationV1,
        xdg_surface_acked: bool = false,
        socket_closed: bool = false,
    };
    const GfxFormat = struct {
        vk_format: vk.Format,
        wl_format: Drm.Format,
    };

    wayland: Wayland,
    gfx_format: GfxFormat,
    graphics_context: GraphicsContext,
    width: i32,
    height: i32,
    running: bool,

    pub fn deinit(state: *State) void {
        // Wayland Deinit
        {
            const wl_state = &state.wayland;
            defer wl_state.interface_registry.deinit();
            if (!wl_state.socket_closed) {
                defer wl_state.socket_closed = true;
                defer wl_state.wl_socket.close();

                for (wl_state.wl_buffers, 0..) |buf, idx| {
                    buf.destroy(wl_state.sock_writer, .{}) catch |err| {
                        wl_log.err("Failed to send destroy signal to wl_buffer[{d}]:: Error: {s}", .{ idx, @errorName(err) });
                    };
                }

                if (wl_state.xdg_toplevel) |tl| tl.destroy(wl_state.sock_writer, .{}) catch |err| {
                    wl_log.err("Failed to send release message to xdg_toplevel:: Error: {s}", .{@errorName(err)});
                };

                wl_state.decoration_toplevel.destroy(wl_state.sock_writer, .{}) catch |err| {
                    wl_log.err("Failed to send release message to xdg_decoration_toplevel:: Error: {s}", .{@errorName(err)});
                };

                wl_state.decoration_manager.destroy(wl_state.sock_writer, .{}) catch |err| {
                    wl_log.err("Failed to send release message to xdg_decoration_manager:: Error: {s}", .{@errorName(err)});
                };
                wl_state.xdg_surface.destroy(wl_state.sock_writer, .{}) catch |err| {
                    wl_log.err("Failed to send release message to xdg_surface:: Error: {s}", .{@errorName(err)});
                };

                wl_state.wl_surface.destroy(wl_state.sock_writer, .{}) catch |err| {
                    wl_log.err("Failed to send destroy message to wl_surface:: Error: {s}", .{@errorName(err)});
                };

                wl_state.xdg_wm_base.destroy(wl_state.sock_writer, .{}) catch |err| {
                    wl_log.err("Failed to send destroy message to xdg_wm_base:: Error: {s}", .{@errorName(err)});
                };

                wl_state.seat.release(wl_state.sock_writer, .{}) catch |err| {
                    wl_log.err("Failed to send release message to wl_seat:: Error: {s}", .{@errorName(err)});
                };
            }
        }
        // Vulkan deinit
        {
            defer state.graphics_context.deinit();
        }
    }

    pub fn create_buffer(state: *State, fd: std.posix.fd_t, format: Drm.Format) !wl.Buffer {
        const dmabuf_params = try state.wayland.interface_registry.register(dmab.LinuxBufferParamsV1);
        defer {
            state.wayland.interface_registry.remove(dmabuf_params);
            dmabuf_params.destroy(state.wayland.sock_writer, .{}) catch |err| {
                wl_log.err("Failed to Destroy DMABuf Params Object of id {d} :: {s}", .{
                    dmabuf_params.id,
                    @errorName(err),
                });
            };
        }

        try state.wayland.dmabuf.create_params(state.wayland.sock_writer, .{
            .params_id = dmabuf_params.id,
        });
        try dmabuf_params.add(state.wayland.sock_writer, .{
            .fd = fd,
            .plane_idx = 0,
            .offset = 0,
            .stride = @intCast(state.width * 4),
            .modifier_hi = Drm.Modifier.linear.hi(),
            .modifier_lo = Drm.Modifier.linear.lo(),
        });

        const wl_buffer = try state.wayland.interface_registry.register(wl.Buffer);
        errdefer state.wayland.interface_registry.remove(wl_buffer);

        try dmabuf_params.create_immed(state.wayland.sock_writer, .{
            .buffer_id = wl_buffer.id,
            .width = @intCast(state.width),
            .height = @intCast(state.height),
            .format = @intFromEnum(format),
            .flags = .{},
        });

        return wl_buffer;
    }
};

fn handle_wl_events(state: *State) void {
    var wl_state = &state.wayland;
    const event_iterator = &wl_state.wl_ev_iter;

    loop: while (state.running) {
        const ev = event_iterator.next() catch |err| {
            app_log.err("Wayland Event Thread Encountered Fatal Error: {any}", .{err});
            wl_state.socket_closed = true;
            state.running = false;
            break :loop;
        } orelse Event.nil;
        const interface = state.wayland.interface_registry.get(ev.header.id) orelse .nil_ev;
        _ = res: {
            switch (interface) {
                .nil_ev => {
                    // nil event handle
                },
                .xdg_wm_base => {
                    const action_opt: ?xdg.WmBase.Event = xdg.WmBase.Event.parse(ev.header.op, ev.data) catch null;
                    if (action_opt) |action|
                        switch (action) {
                            .ping => |ping| {
                                wl_state.xdg_wm_base.pong(wl_state.sock_writer, .{
                                    .serial = ping.serial,
                                }) catch |err| break :res err;
                            },
                        };
                },
                .xdg_surface => {
                    const action_opt: ?xdg.Surface.Event = xdg.Surface.Event.parse(ev.header.op, ev.data) catch null;
                    if (action_opt) |action|
                        switch (action) {
                            .configure => |configure| {
                                wl_state.xdg_surface.ack_configure(wl_state.sock_writer, .{ .serial = configure.serial }) catch |err| break :res err;
                                if (!state.wayland.xdg_surface_acked) state.wayland.xdg_surface_acked = true;
                                app_log.info("Acked configure for xdg_surface", .{});
                            },
                        };
                },
                .xdg_toplevel => {
                    const action_opt: ?xdg.Toplevel.Event = xdg.Toplevel.Event.parse(ev.header.op, ev.data) catch null;
                    if (action_opt) |action|
                        switch (action) {
                            .configure => |configure| {
                                if (configure.width > state.width or configure.height > state.height) {
                                    app_log.info("Resizing Window :: {d}x{d} -> {d}x{d}", .{
                                        state.width,
                                        state.height,
                                        configure.width,
                                        configure.height,
                                    });

                                    state.width = configure.width;
                                    state.height = configure.height;

                                    // TODO: Rebuild Swapchain to render to new window size
                                }
                            },
                            .close => { //  Empty struct, nothing to capture
                                app_log.info("Toplevel Received Close Signal", .{});
                                wl_state.xdg_toplevel.?.destroy(wl_state.sock_writer, .{}) catch |err| break :res err;
                                wl_state.xdg_toplevel = null;
                                state.running = false;
                                break;
                            },
                            else => {
                                log_unused_event(interface, ev) catch |err| {
                                    wl_log.warn("Failed to log event from Interface :: {s}", .{@tagName(interface)});
                                    break :res err;
                                };
                            },
                        };
                },
                .dmabuf_feedback => {
                    const feedback = dmab.LinuxDmabufFeedbackV1.Event.parse(ev.header.op, ev.data) catch |err| break :res err;

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
                                    app_log.err("DMABuf Feedback :: Failed to Map Supported Formats Table :: {s}", .{@errorName(err)});
                                    break :res err;
                                };
                                defer std.posix.munmap(table_data);

                                state.gfx_format.wl_format = .abgr8888;
                            }
                        },
                        else => {
                            log_unused_event(interface, ev) catch |err| break :res err;
                        },
                    }
                },
                else => {
                    log_unused_event(interface, ev) catch |err| break :res err;
                },
            }
        } catch |err| {
            app_log.err("Wayland Event Thread Encountered Error: {s}", .{@errorName(err)});
        };
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
    wl_buffer,
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
            wl.Buffer => .wl_buffer,
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
    const IndexFreeQueue = struct {
        buf: [QueueSize]u32 = [_]u32{0} ** QueueSize,
        first: usize = 0,
        last: usize = 0,

        const QueueSize = 32;

        pub fn push(q: *IndexFreeQueue, idx: u32) void {
            q.buf[(q.last % QueueSize)] = idx;
            q.last += 1;
        }
        pub fn next(q: *IndexFreeQueue) ?u32 {
            const res = blk: {
                if (q.buf[(q.first % QueueSize)] == 0) {
                    break :blk null;
                } else {
                    defer q.first += 1;
                    defer q.buf[(q.first % QueueSize)] = 0;
                    break :blk q.buf[(q.first % QueueSize)];
                }
            };
            return res;
        }
    };
    const InterfaceMap = std.AutoHashMap(u32, InterfaceType);

    idx: u32,
    elems: InterfaceMap,
    registry: wl.Registry,
    free_list: IndexFreeQueue = .{},

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
        const idx = if (self.free_list.next()) |freed_id|
            freed_id
        else blk: {
            defer self.idx += 1;
            break :blk self.idx;
        };

        try self.registry.bind(writer, .{
            .name = params.name,
            .id_interface = params.interface,
            .id_interface_version = params.version,
            .id = idx,
        });

        try self.elems.put(idx, try .from_type(T));
        return .{
            .id = idx,
        };
    }

    pub fn remove(self: *InterfaceRegistry, obj: anytype) void {
        self.free_list.push(obj.id);
        _ = self.elems.remove(obj.id);
    }

    pub fn register(self: *InterfaceRegistry, comptime T: type) !T {
        const idx = if (self.free_list.next()) |freed_id|
            freed_id
        else blk: {
            defer self.idx += 1;
            break :blk self.idx;
        };

        app_log.info("Registering Interface: {s}, with id: {d}", .{ @typeName(T), idx });

        try self.elems.put(idx, try .from_type(T));
        return .{
            .id = idx,
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
            const ev = try wl.Seat.Event.parse(event.header.op, event.data);
            switch (ev) {
                .name => |name| {
                    app_log.debug("Unused wl_seat event: wl.Seat Name {s}", .{name.name});
                },
                .capabilities => |capabilities| {
                    app_log.debug(
                        "Unused wl_seat event: wl.Seat Capabilities: pointer {any}, keyboard: {any}, touch: {any}",
                        .{
                            capabilities.capabilities.pointer,
                            capabilities.capabilities.keyboard,
                            capabilities.capabilities.touch,
                        },
                    );
                },
            }
        },
        .wl_surface => {
            app_log.debug("Unused event: {any}", .{try wl.Surface.Event.parse(event.header.op, event.data)});
        },
        .wl_buffer => {
            app_log.debug("Unused event: {any}", .{try wl.Buffer.Event.parse(event.header.op, event.data)});
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
            app_log.info("Header Size :: {d}", .{Header.Size});
            app_log.info("DMABuf Feedback: Header :: op={d}, size={d}", .{ event.header.op, event.header.msg_size });
            app_log.debug("Unused event: {any}, with no fd", .{try dmab.LinuxDmabufFeedbackV1.Event.parse(event.header.op, event.data)});
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
        fn load_events(iter: *Iterator) !void {
            if (receive_cmsg(iter.stream.handle, &iter.fd_buf)) |fd| {
                const idx = iter.fd_queue.write % FdQueue.Len;
                iter.fd_queue.data[idx] = fd;
                iter.fd_queue.write += 1;
            }

            iter.buf.shift();

            const bytes_read: usize = try iter.stream.read(iter.buf.data[iter.buf.end..]);
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
        pub fn next(iter: *Iterator) !?Event {
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
                        wl_log.err("  Event Iterator :: {s}", .{@errorName(err)});
                        return err;
                    };
                } else {
                    return null;
                }
            }
        }

        pub fn next_fd(iter: *Iterator) ?std.posix.fd_t {
            if (iter.fd_queue.read == iter.fd_queue.write)
                return null;

            defer iter.fd_queue.read += 1;
            return iter.fd_queue.data[iter.fd_queue.read];
        }
        pub fn peek_fd(iter: *Iterator) ?std.posix.fd_t {
            if (iter.fd_queue.read == iter.fd_queue.write)
                return null;

            return iter.fd_queue.data[iter.fd_queue.read];
        }
    };
}

const cmsg = wl_msg.cmsg;
const SCM_RIGHTS = 0x01;
fn receive_cmsg(socket: std.posix.socket_t, buf: []u8) ?std.posix.fd_t {
    var cmsg_buf: [cmsg(std.posix.fd_t).Size * 12]u8 = undefined;

    var iov = [_]std.posix.iovec{
        .{
            .base = buf.ptr,
            .len = buf.len,
        },
    };

    var msg: std.posix.msghdr = .{
        .name = null,
        .namelen = 0,
        .iov = &iov,
        .iovlen = 1,
        .control = &cmsg_buf,
        .controllen = cmsg_buf.len,
        .flags = 0,
    };

    const rc: usize = std.os.linux.recvmsg(socket, &msg, std.os.linux.MSG.PEEK | std.os.linux.MSG.DONTWAIT);

    const res = res: {
        if (@as(isize, @bitCast(rc)) < 0) {
            const err = std.posix.errno(rc);
            wl_log.err("recvmsg failed with err: {s}", .{@tagName(err)});
            break :res null;
        } else {
            const cmsg_t = cmsg(std.posix.fd_t);
            const cmsg_size = cmsg_t.Size - cmsg_t.Padding;
            var offset: usize = 0;
            while (offset + cmsg_size <= msg.controllen) {
                const ctrl_buf: [*]u8 = @ptrCast(msg.control.?);
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
