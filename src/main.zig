const std = @import("std");
const wayland = @import("wayland.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, Wayland!\n", .{});
}
