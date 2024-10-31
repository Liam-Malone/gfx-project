const std = @import("std");

const BindingsGenerator = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    binding_gen: *std.Build.Step.Compile,
    wl_msg: *std.Build.Module,

    pub fn gen_bindings(self: *const BindingsGenerator, name: []const u8, xml_spec: std.Build.LazyPath) *std.Build.Module {
        const binding_gen_run = self.b.addRunArtifact(self.binding_gen);
        binding_gen_run.addFileArg(xml_spec);
        const bindings = binding_gen_run.addOutputFileArg(name);

        const bindings_module = self.b.addModule("bindings", .{
            .root_source_file = bindings,
            .target = self.target,
            .optimize = self.optimize,
        });

        bindings_module.addImport("wl_msg", self.wl_msg);
        return bindings_module;
    }
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const bindings = b.addExecutable(.{
        .name = "wl_bindings_gen",
        .root_source_file = b.path("src/wl_gen.zig"),
        .target = target,
        .optimize = optimize,
    });

    const wl_msg_module = b.addModule("wl_msg", .{
        .root_source_file = b.path("src/wl_msg.zig"),
        .target = target,
        .optimize = optimize,
    });

    const bindings_generator: BindingsGenerator = .{
        .b = b,
        .target = target,
        .optimize = optimize,
        .wl_msg = wl_msg_module,
        .binding_gen = bindings,
    };

    const wayland_bindings = bindings_generator.gen_bindings("wayland.zig", b.path("protocols/wayland/wayland.xml"));
    const xdg_shell_bindings = bindings_generator.gen_bindings("xdg_shell.zig", b.path("protocols/wayland/xdg-shell.xml"));
    const linux_dmabuf_bindings = bindings_generator.gen_bindings("linux_dmabuf.zig", b.path("protocols/wayland/linux-dmabuf-v1.xml"));

    const exe = b.addExecutable(.{
        .name = "GfxDemo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("wl_msg", wl_msg_module);
    exe.root_module.addImport("wayland", wayland_bindings);
    exe.root_module.addImport("xdg_shell", xdg_shell_bindings);
    exe.root_module.addImport("dmabuf", linux_dmabuf_bindings);

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
