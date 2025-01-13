const std = @import("std");

const BindingsGenerator = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    binding_gen: *std.Build.Step.Compile,

    pub fn gen_bindings(self: *const BindingsGenerator, protocols: [][]const u8) !void {
        const binding_gen_run = self.b.addRunArtifact(self.binding_gen);

        binding_gen_run.addArg("-p");
        _ = binding_gen_run.addOutputDirectoryArg("src/generated");

        binding_gen_run.addArgs(protocols);
    }
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const use_llvm = b.option(bool, "use-llvm", "Whether or not to use the LLVM compiler backend") orelse true;
    const use_lld = b.option(bool, "use-lld", "Whether or not to use LLD as the linker") orelse use_llvm;

    // BEGIN Wayland-Bindings
    const bindgen = b.addExecutable(.{
        .name = "wl-bindgen",
        .root_source_file = b.path("src/wl-bindgen.zig"),
        .target = target,
        .optimize = optimize,
        .use_llvm = false,
        .use_lld = false,
    });

    const bindings_generator: BindingsGenerator = .{
        .b = b,
        .target = target,
        .optimize = optimize,
        .binding_gen = bindgen,
    };

    var wl_protocols = [_][]const u8{
        b.pathFromRoot("protocols/wayland/wayland.xml"),
        b.pathFromRoot("protocols/wayland/xdg-shell.xml"),
        b.pathFromRoot("protocols/wayland/xdg-decoration-unstable-v1.xml"),
        b.pathFromRoot("protocols/wayland/linux-dmabuf-v1.xml"),
    };

    // END Wayland-Bindings
    const exe = b.addExecutable(.{
        .name = "Gfx-Project",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .use_llvm = use_llvm,
        .use_lld = use_lld,
    });

    // TODO: Add windows and eventually macos support
    switch (target.result.os.tag) {
        .linux => {
            try bindings_generator.gen_bindings(&wl_protocols);
        },
        else => {
            std.log.err("Unsupported Platform: {s}\n", .{@tagName(target.result.os.tag)});
            std.process.exit(1);
        },
    }

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
    // TODO: Add windows and eventually macos support
    switch (target.result.os.tag) {
        .linux => {
            try bindings_generator.gen_bindings(&wl_protocols);
        },
        else => {
            std.log.err("Unsupported Platform: {s}\n", .{@tagName(target.result.os.tag)});
            std.process.exit(1);
        },
    }

    const test_step = b.step("test", "Run Tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
