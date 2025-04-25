const std = @import("std");
const input = @import("input.zig");

const Event = @This();

const Type = enum {
    invalid,
    /// Keyboard input events
    keyboard,

    /// Mouse input events
    mouse_button,
    mouse_move,

    /// General events relating to surfaces/windows. Resize/Close/Etc.
    surface,

    /// Drag'n'drop/Upload/Paste events
    data,
};

const Surface = struct {
    id: u32,
    type: Surface.Type,

    const Type = union(enum) {
        close: void,
        fullscreen: Vec2i32,
        resize: Vec2i32,
    };
};

type: Type,
mouse_button: input.MouseButton,
mouse_button_state: input.MouseButton.State,
mouse_pos_prev: Vec2f32,
mouse_pos_new: Vec2f32,
key: input.Key,
key_state: input.Key.State,
surface: Surface,

pub const nil: Event = .{
    .type = undefined,
    .mouse_button = undefined,
    .mouse_button_state = undefined,
    .mouse_pos_prev = undefined,
    .mouse_pos_new = undefined,
    .key = undefined,
    .key_state = undefined,
    .surface = undefined,
};

pub const Queue = struct {
    buf: []Event,
    read: usize = 0,
    write: usize = 0,

    const Q = @This();

    pub fn init(buf: []Event) Queue {
        return .{
            .buf = buf,
        };
    }

    pub fn push(queue: *Q, entry: Event) void {
        defer queue.write += 1;
        queue.buf[queue.write % queue.buf.len] = entry;
    }

    pub fn peek(queue: *Q) ?Event {
        const result = if (queue.read >= queue.write)
            null
        else
            queue.buf[queue.read % queue.buf.len];

        return result;
    }

    pub fn next(queue: *Q) ?Event {
        const result = blk: {
            if (queue.read >= queue.write) {
                break :blk null;
            } else {
                defer queue.read += 1;
                break :blk queue.buf[queue.read % queue.buf.len];
            }
        };

        return result;
    }
};

const math = @import("math.zig");
const Vec2f32 = math.Vec2f32;
const Vec2i32 = math.Vec2i32;
