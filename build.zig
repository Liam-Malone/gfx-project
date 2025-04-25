const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const use_llvm = b.option(bool, "use-llvm", "Whether or not to use the LLVM compiler backend") orelse true;
    const use_lld = b.option(bool, "use-lld", "Whether or not to use LLD as the linker") orelse use_llvm;

    // BEGIN Wayland-Bindings
    const wl_protocols = &.{
        b.pathFromRoot("protocols/wayland/wayland.xml"),
        b.pathFromRoot("protocols/wayland/xdg-shell.xml"),
        b.pathFromRoot("protocols/wayland/xdg-decoration-unstable-v1.xml"),
        b.pathFromRoot("protocols/wayland/linux-dmabuf-v1.xml"),
    };

    const bindgen_run = b.addSystemCommand(&.{"zig"});
    bindgen_run.addArgs(&.{
        "run",
        "src/wl-bindgen.zig",
        "--",
        "--cli",
    });
    bindgen_run.addArgs(wl_protocols);

    const protocols_file = bindgen_run.captureStdOut();
    b.getInstallStep().dependOn(&b.addInstallFileWithDir(protocols_file, .{ .custom = "../src/generated" }, "protocols.zig").step);

    // END Wayland-Bindings
    const exe = b.addExecutable(.{
        .name = "Gfx",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .use_llvm = use_llvm,
        .use_lld = use_lld,
    });

    if (b.lazyDependency("vulkan", .{
        .target = target,
        .optimize = optimize,
        .registry = @as([]const u8, b.pathFromRoot("protocols/vulkan/vk.xml")),
    })) |vkzig_dep| {
        const vkzig_bindings = vkzig_dep.module("vulkan-zig");
        exe.root_module.addImport("vulkan", vkzig_bindings);
        exe.linkSystemLibrary("vulkan");
    }

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run Program");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run Tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
