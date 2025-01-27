const std = @import("std");
const math = std.math;

pub const Vec2F32 = struct {
    x: f32,
    y: f32,

    pub const zero: Vec2F32 = .{ .x = 0, .y = 0 };
};

pub const Vec2I32 = struct {
    x: i32,
    y: i32,

    pub const zero: Vec2I32 = .{ .x = 0, .y = 0 };
};
