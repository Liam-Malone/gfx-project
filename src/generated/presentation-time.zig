// WARNING: This file is auto-generated by wl-zig-bindgen.
//          It is recommended that you do NOT edit this file.
//
// TODO: Put a useful message in here when this thing is ready.
//

const std = @import("std");
const log = std.log.scoped(.@"presentation-time");

const wl_msg = @import("wl_msg"); // It's assumed that the user provides this module

/// timed presentation related wl_surface requests
pub const Presentation = struct {
    pub const name: [:0]const u8 = "wp_presentation";

    version: u32 = 2,
    id: u32,

    /// fatal presentation errors
    pub const Error = enum(u32) {
        /// invalid value in tv_nsec
        invalid_timestamp = 0,
        /// invalid flag
        invalid_flag = 1,
    };
    pub const destroy_params = struct {
        pub const op = 0;
    };

    /// unbind from the presentation interface
    pub fn destroy(self: *const Presentation, writer: anytype, params: destroy_params) !void {
        try wl_msg.write(writer, @TypeOf(params), params, self.id);
    }

    pub const feedback_params = struct {
        pub const op = 1;
        /// target surface
        surface: u32,
        /// new feedback object
        callback: u32,
    };

    /// request presentation feedback information
    pub fn feedback(self: *const Presentation, writer: anytype, params: feedback_params) !void {
        try wl_msg.write(writer, @TypeOf(params), params, self.id);
    }
    pub const Event = union(enum) {
        clock_id: Event.ClockId,

        /// clock ID for timestamps
        pub const ClockId = struct {
            clk_id: u32,
        };
        pub fn parse(op: u32, data: []const u8) !Event {
            return switch (op) {
                0 => .{ .clock_id = try wl_msg.parse_data(Event.ClockId, data) },
                else => {
                    log.warn("Unknown presentation event: {d}", .{op});
                    return error.UnknownEvent;
                },
            };
        }
    };
};

/// presentation time feedback event
pub const PresentationFeedback = struct {
    pub const name: [:0]const u8 = "wp_presentation_feedback";

    version: u32 = 2,
    id: u32,

    /// bitmask of flags in presented event
    pub const Kind = packed struct(u32) {
        vsync: bool = false,
        hw_clock: bool = false,
        hw_completion: bool = false,
        zero_copy: bool = false,
        __reserved_bit_4: bool = false,
        __reserved_bit_5: bool = false,
        __reserved_bit_6: bool = false,
        __reserved_bit_7: bool = false,
        __reserved_bit_8: bool = false,
        __reserved_bit_9: bool = false,
        __reserved_bit_10: bool = false,
        __reserved_bit_11: bool = false,
        __reserved_bit_12: bool = false,
        __reserved_bit_13: bool = false,
        __reserved_bit_14: bool = false,
        __reserved_bit_15: bool = false,
        __reserved_bit_16: bool = false,
        __reserved_bit_17: bool = false,
        __reserved_bit_18: bool = false,
        __reserved_bit_19: bool = false,
        __reserved_bit_20: bool = false,
        __reserved_bit_21: bool = false,
        __reserved_bit_22: bool = false,
        __reserved_bit_23: bool = false,
        __reserved_bit_24: bool = false,
        __reserved_bit_25: bool = false,
        __reserved_bit_26: bool = false,
        __reserved_bit_27: bool = false,
        __reserved_bit_28: bool = false,
        __reserved_bit_29: bool = false,
        __reserved_bit_30: bool = false,
        __reserved_bit_31: bool = false,
    };
    pub const Event = union(enum) {
        sync_output: Event.SyncOutput,
        presented: Event.Presented,
        discarded: Event.Discarded,

        /// presentation synchronized to this output
        pub const SyncOutput = struct {
            output: u32,
        };

        /// the content update was displayed
        pub const Presented = struct {
            tv_sec_hi: u32,
            tv_sec_lo: u32,
            tv_nsec: u32,
            refresh: u32,
            seq_hi: u32,
            seq_lo: u32,
            flags: PresentationFeedback.Kind,
        };

        /// the content update was not displayed
        pub const Discarded = struct {};
        pub fn parse(op: u32, data: []const u8) !Event {
            return switch (op) {
                0 => .{ .sync_output = try wl_msg.parse_data(Event.SyncOutput, data) },
                1 => .{ .presented = try wl_msg.parse_data(Event.Presented, data) },
                2 => .{ .discarded = try wl_msg.parse_data(Event.Discarded, data) },
                else => {
                    log.warn("Unknown presentation_feedback event: {d}", .{op});
                    return error.UnknownEvent;
                },
            };
        }
    };
};