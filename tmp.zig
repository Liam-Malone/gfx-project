pub fn main() !void {
    const x: u32 = ((67 - 1) / (4 + 1) * 4);
    const y: u32 = 67 + (4 - (67 % 4));
    const z: u32 = 67 + (4 - (67 % 4));
    try @import("std").io.getStdOut().writer().print("{d}, {d}, {d}\n", .{ x, y, z });
}
