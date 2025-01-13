const std = @import("std");
const builtin = @import("builtin");
const vk = @import("vulkan");
const Drm = @import("Drm.zig");

const GraphicsContext = @import("GraphicsContext.zig");
const Arena = @import("Arena.zig");

const WlClient = @import("wl-client.zig");
const protocols = @import("generated/protocols.zig");
const dmab = protocols.linux_dmabuf_v1;

const log = std.log.scoped(.app);

// TODO: Remove all `try` usage from main()
pub fn main() !void {
    const return_val: void = exit: {
        var arena: *Arena = .init(.default);
        defer arena.release();

        // Creating application state
        var state: State = state: {
            const client: *WlClient = .init(arena);
            break :state .{
                .client = client,
                .vk_format = undefined,
                .graphics_context = undefined,
            };
        };
        defer state.deinit();

        var focused_surface: *WlClient.Surface = state.client.surfaces.items[state.client.focused_surface];

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
            const screen_height: u32 = @intCast(focused_surface.dims.x);

            // Create Vulkan Graphics Context
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

            vk_dev.wrapper.queueSubmit(graphics_context.graphics_queue.handle, 1, &[_]vk.SubmitInfo{
                .{
                    .command_buffer_count = 1,
                    .p_command_buffers = graphics_context.cmd_bufs.ptr,
                },
            }, .null_handle) catch |err| break :exit err;

            log.info("Initial Render Dimensions: {d}x{d}", .{ focused_surface.dims.x, focused_surface.dims.y });
            // Return constructed state
            break :vk_state graphics_context;
        };
        log.info("Vulkan Initialized", .{});

        try focused_surface.init_buffers(state.graphics_context.mem_fds);

        // Actual vulkan learning
        {
            // Triangle vertices
            const vertices = [_]Vertex{
                .{ .pos = .{ 0, -0.5 }, .color = .{ 1, 0, 0 } }, // Left
                .{ .pos = .{ 0.5, 0.5 }, .color = .{ 0, 1, 0 } }, // Top
                .{ .pos = .{ -0.5, 0.5 }, .color = .{ 0, 0, 1 } }, // Right
            };

            const buf = try state.graphics_context.dev.createBuffer(&.{
                .size = @sizeOf(@TypeOf(vertices)),
                .usage = .{ .transfer_dst_bit = true, .vertex_buffer_bit = true },
                .sharing_mode = .exclusive,
            }, null);
            defer state.graphics_context.dev.destroyBuffer(buf, null);
        }

        var red_val: f32 = 0.0;
        var blu_val: f32 = 0.0;
        var step: f32 = 0.01;
        var cur_frame_idx: usize = 0;
        var prev_time: i64 = std.time.milliTimestamp();
        while (state.client.socket != -1) : (cur_frame_idx = (cur_frame_idx + 1) % state.graphics_context.images.len) {
            const time = std.time.milliTimestamp();

            if (time - prev_time > @divFloor(std.time.ms_per_s, state.fps_target)) {
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
                            .width = @intCast(focused_surface.dims.x),
                            .height = @intCast(focused_surface.dims.y),
                        },
                    },
                    .clear_value_count = 1,
                    .p_clear_values = &clear_value,
                }, .@"inline");

                vk_dev.wrapper.cmdEndRenderPass(cmd_buf.*);
                vk_dev.wrapper.endCommandBuffer(cmd_buf.*) catch |err| break :exit err;

                {
                    vk_dev.wrapper.queueSubmit(graphics_queue.handle, 1, &[_]vk.SubmitInfo{
                        .{
                            .command_buffer_count = 1,
                            .p_command_buffers = &[_]vk.CommandBuffer{cmd_buf.*},
                        },
                    }, .null_handle) catch |err| break :exit err;

                    focused_surface.wl_surface.damage(state.client.connection.writer(), .{
                        .x = 0,
                        .y = 0,
                        .width = focused_surface.dims.x,
                        .height = focused_surface.dims.y,
                    }) catch |err| break :exit err;

                    focused_surface.wl_surface.attach(state.client.connection.writer(), .{
                        .buffer = focused_surface.buffers[0].id,
                        .x = 0,
                        .y = 0,
                    }) catch |err| break :exit err;
                    focused_surface.wl_surface.commit(state.client.connection.writer(), .{}) catch |err| break :exit err;
                }
            } else {
                const fps_delay = @divFloor(std.time.ms_per_s, state.fps_target) - (time - prev_time);
                std.time.sleep(@intCast(fps_delay * std.time.ns_per_ms));
            }
        }
    } catch |err| { // program err exit path
        log.err("Program exiting due to error: {s}", .{@errorName(err)});
        std.process.exit(1);
    };

    // program err-free exit path
    return return_val;
}

const Vertex = struct {
    const binding_description = vk.VertexInputBindingDescription{
        .binding = 0,
        .stride = @sizeOf(Vertex),
        .input_rate = .vertex,
    };

    const attribute_description = [_]vk.VertexInputAttributeDescription{
        .{
            .binding = 0,
            .location = 0,
            .format = .r32g32_sfloat,
            .offset = @offsetOf(Vertex, "pos"),
        },
        .{
            .binding = 0,
            .location = 1,
            .format = .r32g32b32_sfloat,
            .offset = @offsetOf(Vertex, "color"),
        },
    };

    pos: [2]f32,
    color: [3]f32,
};

const State = struct {
    client: *WlClient,
    vk_format: vk.Format,
    graphics_context: GraphicsContext,
    fps_target: i32 = 60,

    pub fn deinit(state: *State) void {
        state.client.deinit();
        state.graphics_context.deinit();
    }
};

test "Arena" {
    _ = Arena;
}
test "Wayland Client Tests" {
    _ = WlClient;
}
