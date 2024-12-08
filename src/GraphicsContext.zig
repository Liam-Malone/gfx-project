const std = @import("std");
const Allocator = std.mem.Allocator;

const wl = @import("wayland");
const vk = @import("vulkan");

const vk_log = std.log.scoped(.vulkan);
const Arena = @import("Arena.zig");

const GraphicsContext = @This();

const required_device_extensions = [_][*:0]const u8{
    vk.extensions.khr_swapchain.name,
    vk.extensions.khr_external_memory.name,
    vk.extensions.khr_external_memory_fd.name,
    vk.extensions.ext_external_memory_dma_buf.name,
};

// Create List of APIs for Instance/Device wrappers
const apis: []const vk.ApiInfo = &.{
    .{
        .base_commands = .{
            .createInstance = true,
        },
        .instance_commands = .{
            .createDevice = true,
        },
    },
    vk.features.version_1_0,
    vk.features.version_1_1,
    vk.features.version_1_2,
    vk.extensions.khr_surface,
    vk.extensions.khr_external_memory,
    vk.extensions.khr_external_memory_fd,
    vk.extensions.ext_external_memory_dma_buf,
};

// Pass 'API's to wrappers to create dispatch tables
const BaseDispatch = vk.BaseWrapper(apis);
const InstanceDispatch = vk.InstanceWrapper(apis);
const DeviceDispatch = vk.DeviceWrapper(apis);

// Create Proxying Wrappers -- contain handles
pub const Instance = vk.InstanceProxy(apis);
pub const Device = vk.DeviceProxy(apis);

const CommandBuffer = vk.CommandBufferProxy(apis);

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

vkb: BaseDispatch,
instance: Instance,
// surface: vk.SurfaceKHR,
pdev: vk.PhysicalDevice,
props: vk.PhysicalDeviceProperties,
mem_props: vk.PhysicalDeviceMemoryProperties,

dev: Device,
graphics_queue: Queue,
// present_queue: Queue,

extent: vk.Extent3D,
format: vk.Format,
images: [ImageCount]vk.Image,
image_views: [ImageCount]vk.ImageView,
export_mem: [ImageCount]vk.DeviceMemory,
mem_fds: [ImageCount]c_int,
cmd_pool: vk.CommandPool,
cmd_bufs: []vk.CommandBuffer,
render_pass: vk.RenderPass,

pipeline_layout: vk.PipelineLayout = undefined,
pipelines: []vk.Pipeline = undefined,
framebuffers: []vk.Framebuffer = undefined,

// debug_messenger: vk.DebugUtilsMessengerEXT,

pub fn init(
    arena: *Arena,
    app_name: [*:0]const u8,
    extent: vk.Extent3D,
    format: vk.Format,
    enable_validation: bool,
) !GraphicsContext {
    const alloc = arena.allocator();
    const vkb = try BaseDispatch.load(vkGetInstanceProcAddr);

    const app_info: vk.ApplicationInfo = .{
        .p_application_name = app_name,
        .application_version = vk.makeApiVersion(0, 0, 0, 0),
        .p_engine_name = app_name,
        .engine_version = vk.makeApiVersion(0, 0, 0, 0),
        .api_version = vk.API_VERSION_1_3,
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

    const vki: *InstanceDispatch = try alloc.create(InstanceDispatch);
    errdefer alloc.destroy(vki);
    vki.* = try InstanceDispatch.load(vkb_instance, vkb.dispatch.vkGetInstanceProcAddr);
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
        vk_log.err("Failed to create Vulkan Logical Device with error: {s}", .{@errorName(err)});
        return error.VkDeviceCreationFailed;
    };
    const vkd = try alloc.create(DeviceDispatch);
    vkd.* = try .load(device, instance.wrapper.dispatch.vkGetDeviceProcAddr);
    const dev = Device.init(device, vkd);
    errdefer dev.destroyDevice(null);

    const graphics_queue: Queue = Queue.init(
        dev,
        graphics_family,
    );

    const images = [ImageCount]vk.Image{
        dev.wrapper.createImage(dev.handle, &.{
            .flags = .{ .@"2d_view_compatible_bit_ext" = true },
            .image_type = .@"2d",
            .extent = .{
                .width = extent.width,
                .height = extent.height,
                .depth = extent.depth,
            },
            .mip_levels = 1,
            .array_layers = 1,
            .format = format,
            .tiling = .linear,
            .initial_layout = .present_src_khr,
            .usage = .{
                .transfer_src_bit = true,
                .color_attachment_bit = true,
            },
            .samples = .{ .@"1_bit" = true },
            .sharing_mode = .exclusive,
        }, null) catch |err| {
            vk_log.err("Failed to create VkImage with error: {s}", .{@errorName(err)});
            return err;
        },
        dev.wrapper.createImage(dev.handle, &.{
            .flags = .{ .@"2d_view_compatible_bit_ext" = true },
            .image_type = .@"2d",
            .extent = .{
                .width = extent.width,
                .height = extent.height,
                .depth = extent.depth,
            },
            .mip_levels = 1,
            .array_layers = 1,
            .format = format,
            .tiling = .linear,
            .initial_layout = .present_src_khr,
            .usage = .{
                .transfer_src_bit = true,
                .color_attachment_bit = true,
            },
            .samples = .{ .@"1_bit" = true },
            .sharing_mode = .exclusive,
        }, null) catch |err| {
            vk_log.err("Failed to create VkImage with error: {s}", .{@errorName(err)});
            return err;
        },
    };

    var image_views: [ImageCount]vk.ImageView = undefined;
    var fds: [ImageCount]c_int = undefined;
    var export_mem: [ImageCount]vk.DeviceMemory = undefined;
    for (images, 0..) |vk_image, idx| {
        image_views[idx] = dev.wrapper.createImageView(dev.handle, &.{
            .view_type = .@"2d",
            .image = vk_image,
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
        }, null) catch |err| {
            vk_log.err("Failed to create VkImageView with error: {s}", .{@errorName(err)});
            return err;
        };

        const mem_reqs = dev.wrapper.getImageMemoryRequirements(dev.handle, vk_image);

        const mem_type: vk.MemoryType = mem_type: {
            const pdev_mem_reqs = instance.wrapper.getPhysicalDeviceMemoryProperties(physical_device);
            var mem_idx: u32 = 0;
            while (mem_idx < pdev_mem_reqs.memory_type_count) : (mem_idx += 1) {
                const mem_type_flags = pdev_mem_reqs.memory_types[idx].property_flags;
                if (mem_reqs.memory_type_bits & (@as(u6, 1) << @as(u3, @intCast(mem_idx))) != 0 and (mem_type_flags.host_coherent_bit and mem_type_flags.host_visible_bit)) {
                    break :mem_type pdev_mem_reqs.memory_types[mem_idx];
                }
            }

            break :mem_type .{
                .property_flags = .{},
                .heap_index = 0,
            };
        };

        export_mem[idx] = try dev.wrapper.allocateMemory(dev.handle, &.{
            .p_next = &vk.ExportMemoryAllocateInfo{
                .handle_types = .{
                    .dma_buf_bit_ext = true,
                    .host_allocation_bit_ext = true,
                },
            },
            .allocation_size = mem_reqs.size,
            .memory_type_index = mem_type.heap_index,
        }, null);

        try dev.wrapper.bindImageMemory(dev.handle, vk_image, export_mem[idx], 0);

        fds[idx] = try dev.wrapper.getMemoryFdKHR(dev.handle, &.{
            .memory = export_mem[idx],
            .handle_type = .{ .dma_buf_bit_ext = true },
        });
    }

    const cmd_pool = try dev.wrapper.createCommandPool(dev.handle, &.{
        .queue_family_index = graphics_queue.family,
        .flags = .{ .reset_command_buffer_bit = true },
    }, null);

    const image_count = 2;
    const cmd_bufs = arena.push(vk.CommandBuffer, image_count);
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
                .final_layout = .present_src_khr,
            },
        },
        .subpass_count = 1,
        .p_subpasses = &[_]vk.SubpassDescription{
            .{
                .pipeline_bind_point = .graphics,
                .color_attachment_count = 1,
                .p_color_attachments = &[_]vk.AttachmentReference{
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

        .extent = extent,
        .format = format,
        .images = images,
        .image_views = image_views,
        .export_mem = export_mem,
        .mem_fds = fds,
        .cmd_pool = cmd_pool,
        .cmd_bufs = cmd_bufs,
        .render_pass = render_pass,

        .pipeline_layout = undefined,
        .pipelines = undefined,
        .framebuffers = undefined,
    };
}

pub fn deinit(ctx: *GraphicsContext) void {
    ctx.dev.destroyDevice(null);
    ctx.instance.destroyInstance(null);

    ctx.allocator.destroy(ctx.dev.wrapper);
    ctx.allocator.destroy(ctx.instance.wrapper);
}

const DeviceCandidate = struct {
    pdev: vk.PhysicalDevice,
    props: vk.PhysicalDeviceProperties,
};
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
            vk_log.err("Unable to enumerate device extension properties. Error:: {s}", .{@errorName(err)});
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

pub fn create_pipelines(
    ctx: *GraphicsContext,
    shaders: []const vk.ShaderModule,
    shader_p_names: []const [*:0]const u8,
) !vk.Result {
    ctx.pipeline_layout = try ctx.dev.wrapper.createPipelineLayout(ctx.dev.handle, &.{}, null);
    ctx.pipelines = ctx.arena.push(vk.Pipeline, 1);
    return try ctx.dev.wrapper.createGraphicsPipelines(ctx.dev.handle, .null_handle, 1, &[_]vk.GraphicsPipelineCreateInfo{
        .{
            .stage_count = @intCast(shaders.len),
            .p_stages = &[_]vk.PipelineShaderStageCreateInfo{
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
                .p_viewports = &[_]vk.Viewport{
                    .{
                        .x = 0,
                        .y = 0,
                        .width = @floatFromInt(ctx.extent.width),
                        .height = @floatFromInt(ctx.extent.height),
                        .min_depth = 0,
                        .max_depth = @floatFromInt(ctx.extent.depth),
                    },
                },
                .scissor_count = 1,
                .p_scissors = &[_]vk.Rect2D{
                    .{
                        .offset = .{
                            .x = 0,
                            .y = 0,
                        },
                        .extent = .{
                            .width = @intCast(ctx.extent.width),
                            .height = @intCast(ctx.extent.height),
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
                .p_attachments = &[_]vk.PipelineColorBlendAttachmentState{
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
    ctx.framebuffers = ctx.arena.push(vk.Framebuffer, ctx.images.len);
    for (ctx.framebuffers, 0..) |*framebuffer, idx| {
        framebuffer.* = try ctx.dev.wrapper.createFramebuffer(ctx.dev.handle, &.{
            .render_pass = ctx.render_pass,
            .attachment_count = 1,
            .p_attachments = &[_]vk.ImageView{ctx.image_views[idx]},
            .width = ctx.extent.width,
            .height = ctx.extent.height,
            .layers = ctx.extent.depth,
        }, null);
    }
}
