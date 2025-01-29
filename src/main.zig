const std = @import("std");
const builtin = @import("builtin");
const vk = @import("vulkan");
const Drm = @import("Drm.zig");
const Event = @import("event.zig");
const input = @import("input.zig");

const GraphicsContext = @import("GraphicsContext.zig");
const Arena = @import("Arena.zig");

const Client = @import("wl-client.zig");
const protocols = @import("generated/protocols.zig");
const dmab = protocols.linux_dmabuf_v1;

const log = std.log.scoped(.app);

// TODO: Remove all `try` usage from main()
pub fn main() !void {
    const return_val: void = exit: {
        var arena: *Arena = .init(.default);
        defer arena.release();

        const ev_queue: *Event.Queue = arena.create(Event.Queue);
        ev_queue.* = .init(arena.push(Event, 2048));
        // Creating application state
        var state: State = state: {
            const client: *Client = .init(.init(.default), ev_queue);
            break :state .{
                .client = client,
                .events = ev_queue,
                .vk_format = undefined,
                .graphics_context = undefined,
                .render_thread = undefined,
            };
        };
        defer state.deinit();

        const focused_surface: *Client.Surface = state.client.surfaces.items[state.client.focused_surface];

        while (!focused_surface.flags.acked) {}
        _ = state.client.dmabuf.get_surface_feedback(state.client.connection.writer(), .{
            .surface = focused_surface.wl_surface.id,
        }) catch |err| break :exit err;

        state.graphics_context = vk_state: {
            // Shader loading
            var vert_buf: []u8 = arena.push(u8, 1072);
            const vert_file = std.fs.cwd().openFile("build/shaders/vert.spv", .{ .mode = .read_only }) catch |err| {
                log.err("File Open Err :: {s}", .{@errorName(err)});
                state.deinit();
                break :exit err;
            };
            defer vert_file.close();

            const vert_bytes = vert_file.readAll(vert_buf) catch |err| {
                log.err("File Read Err :: {s}", .{@errorName(err)});
                state.deinit();
                break :exit err;
            };

            const vert_spv: [*]const u32 = @ptrCast(@alignCast(vert_buf[0..vert_bytes]));

            var frag_buf: []u8 = arena.push(u8, 564);
            const frag_file = std.fs.cwd().openFile("build/shaders/frag.spv", .{ .mode = .read_only }) catch |err| {
                log.err("File Open Err :: {s}", .{@errorName(err)});
                state.deinit();
                break :exit err;
            };
            defer frag_file.close();

            const frag_bytes = frag_file.readAll(frag_buf) catch |err| {
                log.err("File Read Err :: {s}", .{@errorName(err)});
                state.deinit();
                break :exit err;
            };

            const frag_spv: [*]const u32 = @ptrCast(@alignCast(frag_buf[0..frag_bytes]));

            const screen_width: u32 = @intCast(focused_surface.dims.x);
            const screen_height: u32 = @intCast(focused_surface.dims.y);

            var graphics_context = GraphicsContext.init(
                arena,
                state.client,
                "Simple Window",
                .{
                    .width = screen_width,
                    .height = screen_height,
                    .depth = 1,
                },
                .r8g8b8a8_unorm,
                false,
            ) catch |err| {
                log.err("Vulkan Graphics Context creation failed with error: {s}", .{@errorName(err)});
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
            _ = pipeline_create_res;

            graphics_context.create_framebuffers() catch |err| {
                log.err("Failed to Create Initial Vulkan Framebuffers :: {s}", .{@errorName(err)});
                break :exit err;
            };

            log.info("Initial Render Dimensions: {d}x{d}", .{ screen_width, screen_height });
            // Return constructed state
            break :vk_state graphics_context;
        };

        log.info("Vulkan Initialized", .{});

        const render_thread = std.Thread.spawn(.{}, draw_thread, .{&state}) catch |err| {
            log.err("Failed to spawn render thread with err :: {s}", .{@errorName(err)});
            break :exit err;
        };
        log.debug("Render thread spawned", .{});
        state.render_thread = render_thread;

        var prev_time: i64 = std.time.milliTimestamp();
        while (!state.client.should_exit and state.client.socket != -1) {
            const time = std.time.milliTimestamp();

            if (time - prev_time > @divFloor(std.time.ms_per_s, state.tickrate)) {
                prev_time = time;

                // Poll & handle events
                while (state.events.next()) |ev| {
                    switch (ev.type) {
                        .mouse_move => {
                            // TODO: Keep track of mouse position
                        },
                        .mouse_button => {
                            log.debug("Mouse Button Event :: {s} button {s}", .{ @tagName(ev.mouse_button_state), @tagName(ev.mouse_button) });
                            // TODO: Keep track of mouse button states
                        },
                        .keyboard => {
                            // TODO: Move keymap to application-level
                            log.debug("Keyboard Event :: {s} key {s}", .{ @tagName(ev.key), @tagName(ev.key_state) });
                            if (state.client.keymap[@intFromEnum(ev.key)] != ev.key_state)
                                state.client.keymap[@intFromEnum(ev.key)] = ev.key_state;
                        },
                        .surface => switch (ev.surface.type) {
                            .close => {
                                state.client.remove_surface(ev.surface.id);

                                if (state.client.surfaces.items.len == 0) {
                                    state.client.should_exit = true;
                                }
                            },
                            .resize => |size| {
                                // TODO: Implement proper window resizing
                                log.debug("Unused resize event :: new dimensions {{ .x = {d}, .y = {d} }}", .{ size.x, size.y });
                            },
                            .fullscreen => |size| {
                                // TODO: Implement proper fullscreen support
                                log.debug("Unused fullscreen event :: dimensions {{ .x = {d}, .y = {d} }}", .{ size.x, size.y });
                            },
                        },
                        .data => {
                            // TODO: Implement handling for drag 'n drop / file upload / similar
                            log.debug("Unused data event", .{});
                        },
                        .invalid => {
                            // TODO: Ensure `invalid` event never shows up
                            log.debug("WARNING :: received an `invalid` event", .{});
                        },
                    }
                }

                if (state.client.keymap[@intFromEnum(input.Key.q)] == .pressed) {
                    state.client.should_exit = true;
                }
            } else {
                const tick_delay = @divFloor(std.time.ms_per_s, state.tickrate) - (time - prev_time);
                std.time.sleep(@intCast(tick_delay * std.time.ns_per_ms));
            }
        }
    } catch |err| { // program err exit path
        log.err("Program exiting due to error: {s}", .{@errorName(err)});
        std.process.exit(1);
    };

    // program err-free exit path
    return return_val;
}

fn draw_thread(state: *State) void {
    var ctx: DrawContext = .{
        .red_val = 0.1,
        .blu_val = 0.3,
        .gre_val = 0.1,
        .step = 0.01,
        .idx = 0,
        .swapchain = state.graphics_context.swapchain,
        .prev_time = std.time.milliTimestamp(),
    };

    // main render loop
    while (!state.client.should_exit and state.client.socket != -1) {
        draw(state, &ctx) catch |err| {
            log.err("Draw thread encountered fatal error :: {s}", .{@errorName(err)});
            state.client.should_exit = true;
        };
    }
    log.debug("Draw thread has completed execution", .{});
}

fn draw(state: *State, ctx: *DrawContext) !void {
    const focused_surface = state.client.surfaces.items[state.client.focused_surface];

    const time = std.time.milliTimestamp();

    if (!state.client.should_exit) {
        if (time - ctx.prev_time > @divFloor(std.time.ms_per_s, state.fps_target)) {
            ctx.prev_time = time;

            ctx.red_val -= ctx.step;
            ctx.blu_val += ctx.step;
            ctx.gre_val -= ctx.step;
            if (ctx.red_val >= 1.0 or ctx.red_val <= 0.0)
                ctx.step = -ctx.step;

            const vk_dev = state.graphics_context.dev;
            try vk_dev.wrapper.queueWaitIdle(state.graphics_context.graphics_queue.handle);

            const cmd_buf = &state.graphics_context.cmd_bufs[ctx.idx];
            const graphics_queue = state.graphics_context.graphics_queue;

            const clear_value = [_]vk.ClearValue{
                .{
                    .color = .{
                        .float_32 = [_]f32{ ctx.red_val, ctx.gre_val, ctx.blu_val, 1.0 },
                    },
                },
            };

            try vk_dev.wrapper.beginCommandBuffer(cmd_buf.*, &.{
                .flags = .{},
            });

            vk_dev.wrapper.cmdBeginRenderPass(cmd_buf.*, &.{
                .render_pass = state.graphics_context.render_pass,
                .framebuffer = state.graphics_context.framebuffers[ctx.idx],
                .render_area = .{
                    .offset = .{
                        .x = 0,
                        .y = 0,
                    },
                    .extent = .{
                        .width = @intCast(focused_surface.dims.x),
                        .height = @intCast(focused_surface.dims.y),
                    },
                },
                .clear_value_count = 1,
                .p_clear_values = &clear_value,
            }, .@"inline");

            vk_dev.wrapper.cmdEndRenderPass(cmd_buf.*);
            try vk_dev.wrapper.endCommandBuffer(cmd_buf.*);

            try vk_dev.wrapper.queueSubmit(graphics_queue.handle, 1, &[_]vk.SubmitInfo{
                .{
                    .command_buffer_count = 1,
                    .p_command_buffers = &.{cmd_buf.*},
                },
            }, ctx.swapchain.sync.in_flight_fences[ctx.idx]);

            // Present & prep next image
            try ctx.swapchain.present(state.client.connection.writer(), focused_surface.wl_surface);
            // ctx.idx = try ctx.swapchain.acquire_next(state.graphics_context.dev);
        } else {
            const fps_delay = @divFloor(std.time.ms_per_s, state.fps_target) - (time - ctx.prev_time);
            std.time.sleep(@intCast(fps_delay * std.time.ns_per_ms));
        }
    }
}

const DrawContext = struct {
    red_val: f32,
    blu_val: f32,
    gre_val: f32,
    step: f32,
    idx: usize,
    swapchain: *GraphicsContext.Swapchain,
    prev_time: i64,
};

const State = struct {
    client: *Client,
    vk_format: vk.Format,
    graphics_context: GraphicsContext,
    events: *Event.Queue,
    render_thread: std.Thread,
    fps_target: i32 = 60,
    tickrate: i32 = 60,

    pub fn deinit(state: *State) void {
        state.render_thread.join();
        log.debug("completed render_thread join", .{});

        state.graphics_context.deinit();
        log.debug("completed graphics_context deinit", .{});

        state.client.deinit();
        log.debug("completed client deinit", .{});

        log.debug("completed state deinit, exiting", .{});
    }
};

test "Arena" {
    _ = Arena;
}
test "Wayland Client Tests" {
    _ = Client;
}
