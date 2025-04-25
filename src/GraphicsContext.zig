const GraphicsContext = @This();

const required_device_extensions = [_][*:0]const u8{
    vk.extensions.khr_swapchain.name,
    vk.extensions.khr_external_memory.name,
    vk.extensions.khr_external_memory_fd.name,
    vk.extensions.ext_external_memory_dma_buf.name,
};

const BaseWrapper = vk.BaseWrapper;
const InstanceWrapper = vk.InstanceWrapper;
const DeviceWrapper = vk.DeviceWrapper;

const Instance = vk.InstanceProxy;
const Device = vk.DeviceProxy;

const vkGetInstanceProcAddr = @extern(vk.PfnGetInstanceProcAddr, .{
    .name = "vkGetInstanceProcAddr",
    .library_name = "vulkan",
});

const vkEnumeratePhysicalDevices = @extern(vk.PfnEnumeratePhysicalDevices, .{
    .name = "vkEnumeratePhysicalDevices",
    .library_name = "vulkan",
});

const ImageCount = 2;

allocator: Allocator,
arena: *Arena,

vkb: BaseWrapper,
instance: Instance,

pdev: vk.PhysicalDevice,
props: vk.PhysicalDeviceProperties,
mem_props: vk.PhysicalDeviceMemoryProperties,

dev: Device,
graphics_queue: Queue,
// present_queue: Queue,
swapchain: *Swapchain,

cmd_pool: vk.CommandPool,
cmd_bufs: []vk.CommandBuffer,
render_pass: vk.RenderPass,

pipeline_layout: vk.PipelineLayout = undefined,
pipelines: []vk.Pipeline = undefined,
framebuffers: []vk.Framebuffer = undefined,

// debug_messenger: vk.DebugUtilsMessengerEXT,

pub fn init(
    arena: *Arena,
    surface: *@"wl-client".Surface,
    app_name: [*:0]const u8,
    extent: vk.Extent3D,
    format: vk.Format,
    enable_validation: bool,
) !GraphicsContext {
    const alloc = arena.allocator();
    const vkb = BaseWrapper.load(vkGetInstanceProcAddr);

    const app_info: vk.ApplicationInfo = .{
        .p_application_name = app_name,
        .application_version = @bitCast(vk.makeApiVersion(0, 0, 0, 0)),
        .p_engine_name = app_name,
        .engine_version = @bitCast(vk.makeApiVersion(0, 0, 0, 0)),
        .api_version = @bitCast(vk.API_VERSION_1_3),
    };

    const extension_names = [_][*:0]const u8{
        vk.extensions.khr_surface.name,
    };

    const validation_layers = [_][*:0]const u8{
        "VK_LAYER_KHRONOS_validation",
    };

    const enabled_layers: []const [*:0]const u8 = if (enable_validation) &validation_layers else &.{};

    const vkb_instance = try vkb.createInstance(&.{
        .p_application_info = &app_info,
        .enabled_extension_count = @intCast(extension_names.len),
        .pp_enabled_extension_names = &extension_names,
        .enabled_layer_count = @intCast(enabled_layers.len),
        .pp_enabled_layer_names = enabled_layers.ptr,
    }, null);

    const vki = try alloc.create(InstanceWrapper);
    errdefer alloc.destroy(vki);
    vki.* = .load(vkb_instance, vkb.dispatch.vkGetInstanceProcAddr.?);
    const instance: Instance = .init(vkb_instance, vki);
    errdefer instance.destroyInstance(null);

    // Select a physical device to use
    const selected_device: DeviceCandidate = select_physical_device(alloc, instance, try instance.enumeratePhysicalDevicesAlloc(alloc));
    const physical_device = selected_device.pdev;
    if (physical_device == .null_handle) {
        return error.NoVulkanDevice;
    }
    const props = selected_device.props;

    const graphics_family = graphics_family: {
        const families = try instance.getPhysicalDeviceQueueFamilyPropertiesAlloc(physical_device, alloc);
        defer alloc.free(families);

        for (families, 0..) |properties, i| {
            const family: u32 = @intCast(i);
            if (properties.queue_flags.graphics_bit) {
                break :graphics_family family;
            }
        }

        break :graphics_family null;
    } orelse return error.NoGraphicsQueueFamily;

    // Create logical device
    const device = device: {
        const priority = [_]f32{1};
        const qci = [_]vk.DeviceQueueCreateInfo{
            .{
                .s_type = vk.StructureType.device_queue_create_info,
                .queue_family_index = graphics_family,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            },
        };
        break :device instance.createDevice(physical_device, &.{
            .queue_create_info_count = 1,
            .p_queue_create_infos = &qci,
            .enabled_extension_count = required_device_extensions.len,
            .pp_enabled_extension_names = @ptrCast(&required_device_extensions),
        }, null);
    } catch |err| {
        log.err("Failed to create Vulkan Logical Device with error: {s}", .{@errorName(err)});
        return error.VkDeviceCreationFailed;
    };
    const vkd = try alloc.create(DeviceWrapper);
    vkd.* = .load(device, instance.wrapper.dispatch.vkGetDeviceProcAddr.?);
    const dev = Device.init(device, vkd);
    errdefer dev.destroyDevice(null);

    const graphics_queue: Queue = Queue.init(
        dev,
        graphics_family,
    );

    const sc: *Swapchain = try .init(
        arena,
        surface,
        instance,
        dev,
        physical_device,
        format,
        .{ .width = extent.width, .height = extent.height },
        ImageCount,
    );
    const cmd_pool = try dev.wrapper.createCommandPool(dev.handle, &.{
        .queue_family_index = graphics_queue.family,
        .flags = .{ .reset_command_buffer_bit = true },
    }, null);

    const cmd_bufs = arena.push(vk.CommandBuffer, ImageCount);
    try dev.wrapper.allocateCommandBuffers(dev.handle, &.{
        .command_pool = cmd_pool,
        .level = .primary,
        .command_buffer_count = @intCast(cmd_bufs.len),
    }, @ptrCast(cmd_bufs));

    const render_pass = try dev.wrapper.createRenderPass(dev.handle, &.{
        .attachment_count = 1,
        .p_attachments = &[_]vk.AttachmentDescription{
            .{
                .format = format,
                .samples = .{ .@"1_bit" = true },
                .load_op = .clear,
                .store_op = .store,
                .stencil_load_op = .dont_care,
                .stencil_store_op = .dont_care,
                .initial_layout = .undefined,
                .final_layout = .general,
            },
        },
        .subpass_count = 1,
        .p_subpasses = &.{
            .{
                .pipeline_bind_point = .graphics,
                .color_attachment_count = 1,
                .p_color_attachments = &.{
                    .{
                        .attachment = 0,
                        .layout = .color_attachment_optimal,
                    },
                },
            },
        },
    }, null);

    return .{
        .allocator = alloc,
        .arena = arena,
        .vkb = vkb,
        .instance = instance,
        .pdev = physical_device,
        .props = props,
        .mem_props = instance.getPhysicalDeviceMemoryProperties(physical_device),
        .dev = dev,
        .graphics_queue = graphics_queue,
        .swapchain = sc,

        .cmd_pool = cmd_pool,
        .cmd_bufs = cmd_bufs,
        .render_pass = render_pass,

        .pipeline_layout = undefined,
        .pipelines = undefined,
        .framebuffers = undefined,
    };
}

pub fn deinit(ctx: *GraphicsContext) void {
    defer ctx.instance.destroyInstance(null);
    defer ctx.dev.destroyDevice(null);

    ctx.allocator.destroy(ctx.dev.wrapper);
    ctx.allocator.destroy(ctx.instance.wrapper);
}

fn select_physical_device(arena: Allocator, instance: Instance, devices: []vk.PhysicalDevice) DeviceCandidate {
    var chosen_one: DeviceCandidate = .{
        .pdev = .null_handle,
        .props = undefined,
    };

    var max_score: u32 = 0;

    for (devices) |physical_device| {
        var props12: vk.PhysicalDeviceVulkan12Properties = undefined;
        props12.s_type = .physical_device_vulkan_1_2_properties;
        props12.p_next = null;

        var props2: vk.PhysicalDeviceProperties2 = .{
            .p_next = @ptrCast(&props12),
            .properties = undefined,
        };

        instance.getPhysicalDeviceProperties2(physical_device, &props2);
        const props = props2.properties;

        var score: u32 = 1;

        if (props.device_type == .discrete_gpu)
            score += 1000;

        const propsv = instance.enumerateDeviceExtensionPropertiesAlloc(physical_device, null, arena) catch |err| {
            log.err("Unable to enumerate device extension properties. Error:: {s}", .{@errorName(err)});
            continue;
        };
        defer arena.free(propsv);

        const extensions_supported = ext_support: {
            for (required_device_extensions) |ext| {
                const found_ext = found: {
                    for (propsv) |ext_props| {
                        if (std.mem.eql(u8, std.mem.span(ext), std.mem.sliceTo(&ext_props.extension_name, 0))) {
                            break :found true;
                        }
                    }
                    break :found false;
                };

                if (!found_ext)
                    break :ext_support false;
            }

            break :ext_support true;
        };

        score += props.limits.max_image_dimension_2d;
        if (extensions_supported and (score > max_score)) {
            chosen_one = .{
                .pdev = physical_device,
                .props = props,
            };
            max_score = score;
        }
    }

    return chosen_one;
}

pub fn create_pipelines(
    ctx: *GraphicsContext,
    shaders: []const vk.ShaderModule,
    shader_p_names: []const [*:0]const u8,
) !vk.Result {
    ctx.pipeline_layout = try ctx.dev.wrapper.createPipelineLayout(ctx.dev.handle, &.{}, null);
    ctx.pipelines = ctx.arena.push(vk.Pipeline, 1);
    return try ctx.dev.wrapper.createGraphicsPipelines(ctx.dev.handle, .null_handle, 1, &.{
        .{
            .stage_count = @intCast(shaders.len),
            .p_stages = &.{
                .{
                    .stage = .{ .vertex_bit = true },
                    .module = shaders[0],
                    .p_name = shader_p_names[0],
                },
                .{
                    .stage = .{ .fragment_bit = true },
                    .module = shaders[1],
                    .p_name = shader_p_names[1],
                },
            },
            .p_vertex_input_state = &.{
                .vertex_binding_description_count = 0,
                .vertex_attribute_description_count = 0,
            },
            .p_input_assembly_state = &.{
                .topology = .triangle_list,
                .primitive_restart_enable = 0,
            },
            .p_viewport_state = &.{
                .viewport_count = 1,
                .p_viewports = &.{
                    .{
                        .x = 0,
                        .y = 0,
                        .width = @floatFromInt(ctx.swapchain.extent.width),
                        .height = @floatFromInt(ctx.swapchain.extent.height),
                        .min_depth = 0,
                        .max_depth = 1,
                    },
                },
                .scissor_count = 1,
                .p_scissors = &.{
                    .{
                        .offset = .{
                            .x = 0,
                            .y = 0,
                        },
                        .extent = .{
                            .width = @intCast(ctx.swapchain.extent.width),
                            .height = @intCast(ctx.swapchain.extent.height),
                        },
                    },
                },
            },
            .p_rasterization_state = &.{
                .depth_clamp_enable = vk.FALSE,
                .rasterizer_discard_enable = vk.FALSE,
                .polygon_mode = .fill,
                .front_face = .clockwise,
                .cull_mode = .{},
                .depth_bias_enable = vk.FALSE,
                .depth_bias_constant_factor = 1,
                .depth_bias_clamp = 1,
                .depth_bias_slope_factor = 0,
                .line_width = 1,
            },
            .p_multisample_state = &.{
                .rasterization_samples = .{ .@"1_bit" = true },
                .sample_shading_enable = 0,
                .min_sample_shading = 0,
                .alpha_to_coverage_enable = 0,
                .alpha_to_one_enable = 0,
            },
            .p_color_blend_state = &.{
                .logic_op_enable = 0,
                .logic_op = .clear,
                .attachment_count = 1,
                .p_attachments = &.{
                    .{
                        .blend_enable = 0,
                        .src_color_blend_factor = .src_color,
                        .dst_color_blend_factor = .src_color,
                        .color_blend_op = .add,
                        .src_alpha_blend_factor = .src_color,
                        .dst_alpha_blend_factor = .src_color,
                        .alpha_blend_op = .add,
                        .color_write_mask = .{
                            .r_bit = true,
                            .g_bit = true,
                            .b_bit = true,
                            .a_bit = true,
                        },
                    },
                },
                .blend_constants = [_]f32{ 0, 0, 0, 0 },
            },
            .render_pass = ctx.render_pass,
            .subpass = 0,
            .base_pipeline_index = 0,
        },
    }, null, ctx.pipelines.ptr);
}

pub fn create_framebuffers(ctx: *GraphicsContext) !void {
    ctx.framebuffers = ctx.arena.push(vk.Framebuffer, ctx.swapchain.images.len);
    for (ctx.framebuffers, 0..) |*framebuffer, idx| {
        framebuffer.* = try ctx.dev.wrapper.createFramebuffer(ctx.dev.handle, &.{
            .render_pass = ctx.render_pass,
            .attachment_count = 1,
            .p_attachments = &[_]vk.ImageView{ctx.swapchain.image_views[idx]},
            .width = ctx.swapchain.extent.width,
            .height = ctx.swapchain.extent.height,
            .layers = 1,
        }, null);
    }
}

const DeviceCandidate = struct {
    pdev: vk.PhysicalDevice,
    props: vk.PhysicalDeviceProperties,
};

pub const Queue = struct {
    handle: vk.Queue,
    family: u32,

    fn init(device: Device, family: u32) Queue {
        return .{
            .handle = device.getDeviceQueue(family, 0),
            .family = family,
        };
    }
};

pub const Swapchain = struct {
    arena: *Arena,
    surface: *@"wl-client".Surface,
    images: []vk.Image,
    image_mem: []vk.DeviceMemory,
    image_views: []vk.ImageView,
    buffers: []wl.Buffer,
    sync: Sync,
    format: vk.Format,
    extent: vk.Extent2D,
    idx: usize,

    pub fn init(
        arena: *Arena,
        surface: *@"wl-client".Surface,
        instance: Instance,
        device: Device,
        pdev: vk.PhysicalDevice,
        format: vk.Format,
        extent: vk.Extent2D,
        image_count: usize,
    ) !*Swapchain {
        const client = surface.client;
        const sc_ptr = arena.create(Swapchain);
        sc_ptr.* = .{
            .arena = arena,
            .surface = surface,
            .images = arena.push(vk.Image, image_count),
            .image_mem = arena.push(vk.DeviceMemory, image_count),
            .image_views = arena.push(vk.ImageView, image_count),
            .buffers = arena.push(wl.Buffer, image_count),
            .sync = undefined,
            .format = format,
            .extent = extent,
            .idx = 1,
        };

        for (0..image_count) |idx| {
            log.debug("Creating image for #{d}", .{idx});
            // Create image
            sc_ptr.images[idx] = try device.createImage(&.{
                .flags = .{ .@"2d_view_compatible_bit_ext" = true },
                .image_type = .@"2d",
                .extent = .{
                    .width = extent.width,
                    .height = extent.height,
                    .depth = 1,
                },
                .mip_levels = 1,
                .array_layers = 1,
                .format = format,
                .tiling = .linear,
                .initial_layout = .general,
                .usage = .{
                    .transfer_src_bit = true,
                    .color_attachment_bit = true,
                },
                .samples = .{ .@"1_bit" = true },
                .sharing_mode = .exclusive,
            }, null);

            // create image view
            sc_ptr.image_views[idx] = try device.createImageView(&.{
                .view_type = .@"2d",
                .image = sc_ptr.images[idx],
                .format = format,
                .subresource_range = .{
                    .aspect_mask = .{ .color_bit = true },
                    .base_mip_level = 0,
                    .level_count = 1,
                    .base_array_layer = 0,
                    .layer_count = 1,
                },
                .components = .{
                    .r = .r,
                    .g = .g,
                    .b = .b,
                    .a = .a,
                },
            }, null);
        }

        var mem_type_opt: ?vk.MemoryType = null;
        for (0..ImageCount) |idx| {
            log.debug("Creating buffers for #{d}", .{idx});
            // Get Access to Image Memory
            const mem_reqs = device.getImageMemoryRequirements(sc_ptr.images[idx]);
            if (mem_type_opt == null) {
                mem_type_opt = mem_type: {
                    const pdev_mem_reqs = instance.wrapper.getPhysicalDeviceMemoryProperties(pdev);
                    var mem_idx: u32 = 0;
                    while (mem_idx < pdev_mem_reqs.memory_type_count) : (mem_idx += 1) {
                        const flags = pdev_mem_reqs.memory_types[idx].property_flags;
                        if (mem_reqs.memory_type_bits & (@as(u6, 1) << @as(u3, @intCast(mem_idx))) != 0 and
                            (flags.host_coherent_bit and flags.host_visible_bit))
                        {
                            break :mem_type pdev_mem_reqs.memory_types[mem_idx];
                        }
                    }

                    break :mem_type .{
                        .property_flags = .{},
                        .heap_index = 0,
                    };
                };
            }

            const mem_type = mem_type_opt.?;
            log.debug("mem_type.heap_index = {d}, property_flags = {any}", .{ mem_type.heap_index, mem_type.property_flags });
            sc_ptr.image_mem[idx] = try device.allocateMemory(&.{
                .p_next = &vk.ExportMemoryAllocateInfo{
                    .handle_types = .{
                        .dma_buf_bit_ext = true,
                        .host_allocation_bit_ext = true,
                    },
                },
                .allocation_size = mem_reqs.size,
                .memory_type_index = mem_type.heap_index,
            }, null);

            try device.bindImageMemory(sc_ptr.images[idx], sc_ptr.image_mem[idx], 0);

            const fd = try device.getMemoryFdKHR(&.{
                .memory = sc_ptr.image_mem[idx],
                .handle_type = .{ .dma_buf_bit_ext = true },
            });

            sc_ptr.buffers[idx] = create_buffer(client, fd, .abgr8888, extent);
        }

        try sc_ptr.init_sync(device, ImageCount);

        return sc_ptr;
    }

    pub fn deinit(sc: *Swapchain, device: Device) void {
        for (0..sc.images.len) |idx| {
            device.destroySemaphore(sc.sync.image_available[idx], null);
            device.destroySemaphore(sc.sync.render_finished[idx], null);
            device.destroyFence(sc.sync.in_flight_fences[idx], null);

            device.destroyImage(sc.images[idx], null);
            device.destroyImageView(sc.image_views[idx], null);
            sc.buffers[idx].destroy(sc.client.connection.writer(), .{});
        }
    }

    pub fn next_image(sc: *Swapchain, device: Device) !usize {
        // wait for prev frame's fence
        _ = try device.waitForFences(
            1,
            &.{sc.sync.in_flight_fences[sc.idx]},
            vk.TRUE,
            std.math.maxInt(u64),
        );

        sc.idx = (sc.idx + 1) % sc.images.len;

        // Wait for next image to be freed if still in flight
        if (sc.sync.images_in_flight[sc.idx]) |fence| {
            _ = try device.waitForFences(
                1,
                &.{fence},
                vk.TRUE,
                std.math.maxInt(u64),
            );
        }

        try device.resetFences(
            1,
            &.{sc.sync.in_flight_fences[sc.idx]},
        );
        sc.sync.images_in_flight[sc.idx] = sc.sync.in_flight_fences[sc.idx];

        return sc.idx;
    }

    pub fn present(sc: *Swapchain, writer: anytype, surface: wl.Surface) !void {
        surface.attach(writer, .{
            // TEMPORARY HACK -- Hyprland doesn't seem to like changing buffers ever??
            .buffer = sc.buffers[0].id,
            .x = 0,
            .y = 0,
        }) catch |err| {
            log.err("wl_surface.attach() failed due to err :: {s}", .{@errorName(err)});
            return err;
        };

        surface.damage_buffer(writer, .{
            .x = 0,
            .y = 0,
            .width = @intCast(sc.extent.width),
            .height = @intCast(sc.extent.height),
        }) catch |err| {
            log.err("wl_surface.damage_buffer() failed due to err :: {s}", .{@errorName(err)});
            return err;
        };

        surface.commit(writer, .{}) catch |err| {
            log.err("wl_surface.commit() failed due to err :: {s}", .{@errorName(err)});
            return err;
        };
    }

    fn init_sync(sc: *Swapchain, device: Device, count: usize) !void {
        sc.sync = .{
            .image_available = sc.arena.push(vk.Semaphore, count),
            .render_finished = sc.arena.push(vk.Semaphore, count),
            .in_flight_fences = sc.arena.push(vk.Fence, count),
            .images_in_flight = sc.arena.push(?vk.Fence, count),
        };

        const semaphore_info: vk.SemaphoreCreateInfo = .{};
        const fence_info: vk.FenceCreateInfo = .{
            .flags = .{ .signaled_bit = true },
        };

        for (0..count) |idx| {
            sc.sync.image_available[idx] = try device.createSemaphore(&semaphore_info, null);
            sc.sync.render_finished[idx] = try device.createSemaphore(&semaphore_info, null);
            sc.sync.in_flight_fences[idx] = try device.createFence(&fence_info, null);
            sc.sync.images_in_flight[idx] = null;
        }
    }

    fn create_buffer(
        wl_client: *const @"wl-client",
        fd: std.posix.fd_t,
        format: Drm.Format,
        extent: vk.Extent2D,
    ) wl.Buffer {
        const writer = wl_client.connection.writer();
        const dmabuf_params_opt = wl_client.dmabuf.create_params(writer, .{}) catch |err| nil: {
            log.err("Failed to create linux_dmabuf_params due to err :: {s}", .{@errorName(err)});
            break :nil null;
        };

        const wl_buffer = if (dmabuf_params_opt) |dmabuf_params| buffer: {
            log.debug("Created zwp_linux_buffer_params_v1#{d}", .{dmabuf_params.id});
            log.debug("Adding to zwp_linux_buffer_params_v1#{d} :: {{ fd ={d}, plane_idx={d}, offset={d}, stride={d}, modifier_hi={d}, modifier_lo={d} }}", .{
                dmabuf_params.id,
                fd,
                0,
                0,
                extent.width * 4,
                Drm.Modifier.linear.hi(),
                Drm.Modifier.linear.lo(),
            });
            dmabuf_params.add(writer, .{
                .fd = fd,
                .plane_idx = 0,
                .offset = 0,
                .stride = @intCast(extent.width * 4),
                .modifier_hi = Drm.Modifier.linear.hi(),
                .modifier_lo = Drm.Modifier.linear.lo(),
            }) catch |err| {
                log.err("Failed to add data to linux_dmabuf_params due to err :: {s}", .{@errorName(err)});
                break :buffer null;
            };

            log.debug("Creating wl_buffer :: {{ .width={d}, .height={d}, .format={d}, .flags={{ .y_invert={s}, .interlaced={s}, .bottom_first={s} }} }}", .{
                extent.width,
                extent.height,
                @intFromEnum(format),
                "false",
                "false",
                "false",
            });
            const wl_buffer = dmabuf_params.create_immed(writer, .{
                .width = @intCast(extent.width),
                .height = @intCast(extent.height),
                .format = @intFromEnum(format),
                .flags = .{},
            }) catch |err| {
                log.err("Failed to create wl_buffer due to err :: {s}", .{@errorName(err)});
                break :buffer null;
            };

            log.debug("Destroying zwp_linux_buffer_params_v1#{d}", .{dmabuf_params.id});
            dmabuf_params.destroy(writer, .{}) catch |err| {
                log.err("Failed to destroy linux_dmabuf_params due to err :: {s}", .{@errorName(err)});
            };

            break :buffer wl_buffer;
        } else buffer: {
            break :buffer null;
        };

        if (wl_buffer) |buffer| return buffer else return .{ .id = 0 };
    }

    const Sync = struct {
        image_available: []vk.Semaphore,
        render_finished: []vk.Semaphore,
        in_flight_fences: []vk.Fence,
        images_in_flight: []?vk.Fence,
    };
};

const wl = @import("generated/protocols.zig").wayland;
const std = @import("std");
const vk = @import("vulkan");
const log = std.log.scoped(.vulkan);

const Allocator = std.mem.Allocator;
const Arena = @import("Arena.zig");
const Drm = @import("Drm.zig");
const @"wl-client" = @import("wl-client.zig");
