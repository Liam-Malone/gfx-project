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

allocator: Allocator,

vkb: BaseDispatch,

instance: Instance,
// surface: vk.SurfaceKHR,
pdev: vk.PhysicalDevice,
props: vk.PhysicalDeviceProperties,
mem_props: vk.PhysicalDeviceMemoryProperties,

dev: Device,
graphics_queue: Queue,
// present_queue: Queue,

// debug_messenger: vk.DebugUtilsMessengerEXT,

pub fn init(
    arena: Allocator,
    app_name: [*:0]const u8,
    extent: vk.Extent2D,
    enable_validation: bool,
) !GraphicsContext {
    _ = extent;
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

    const vki: *InstanceDispatch = try arena.create(InstanceDispatch);
    errdefer arena.destroy(vki);
    vki.* = try InstanceDispatch.load(vkb_instance, vkb.dispatch.vkGetInstanceProcAddr);
    const instance: Instance = .init(vkb_instance, vki);
    errdefer instance.destroyInstance(null);

    // Select a physical device to use
    const selected_device: DeviceCandidate = select_physical_device(arena, instance, try instance.enumeratePhysicalDevicesAlloc(arena));
    const physical_device = selected_device.pdev;
    if (physical_device == .null_handle) {
        return error.NoVulkanDevice;
    }
    const props = selected_device.props;

    const graphics_family = graphics_family: {
        const families = try instance.getPhysicalDeviceQueueFamilyPropertiesAlloc(physical_device, arena);
        defer arena.free(families);

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
    const vkd = try arena.create(DeviceDispatch);
    vkd.* = try .load(device, instance.wrapper.dispatch.vkGetDeviceProcAddr);
    const dev = Device.init(device, vkd);
    errdefer dev.destroyDevice(null);

    const graphics_queue: Queue = Queue.init(
        dev,
        graphics_family,
    );

    return .{
        .allocator = arena,
        .vkb = vkb,
        .instance = instance,
        .pdev = physical_device,
        .props = props,
        .mem_props = instance.getPhysicalDeviceMemoryProperties(physical_device),
        .dev = dev,
        .graphics_queue = graphics_queue,
    };
}

pub fn deinit(context: GraphicsContext) void {
    context.dev.destroyDevice(null);
    context.instance.destroyInstance(null);

    context.allocator.destroy(context.dev.wrapper);
    context.allocator.destroy(context.instance.wrapper);
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
