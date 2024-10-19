const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "GfxDemo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (b.lazyDependency("vulkan-zig", .{
        .target = target,
        .optimize = optimize,
        .registry = @as([]const u8, b.pathFromRoot("protocols/vulkan/vk.xml")),
    })) |vkzig_dep| {
        const vkzig_bindings = vkzig_dep.module("vulkan-zig");
        exe.root_module.addImport("vulkan", vkzig_bindings);
    }

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run Program");
    run_step.dependOn(&run_cmd.step);
}
