// WARNING: This file is auto-generated by wl-zig-bindgen.
//          It is recommended that you do NOT edit this file.
//
// TODO: Put a useful message in here when this thing is ready.
//

const std = @import("std");
const log = std.log.scoped(.@"xdg-decoration-unstable-v1");

const wl_msg = @import("wl_msg"); // It's assumed that the user provides this module

/// window decoration manager
pub const DecorationManagerV1 = struct {
    id: u32,
    version: u32 = 1,

    pub const destroy_params = struct {
        pub const op = 0;
    };

    /// destroy the decoration manager object
    pub fn destroy(self: *const DecorationManagerV1, writer: anytype, params: destroy_params) !void {
        try wl_msg.write(writer, @TypeOf(params), params, self.id);
    }

    pub const get_toplevel_decoration_params = struct {
        pub const op = 1;
        id: u32,
        toplevel: u32,
    };

    /// create a new toplevel decoration object
    pub fn get_toplevel_decoration(self: *const DecorationManagerV1, writer: anytype, params: get_toplevel_decoration_params) !void {
        try wl_msg.write(writer, @TypeOf(params), params, self.id);
    }
};

/// decoration object for a toplevel surface
pub const ToplevelDecorationV1 = struct {
    id: u32,
    version: u32 = 1,
    pub const Error = enum(u32) {
        /// xdg_toplevel has a buffer attached before configure
        unconfigured_buffer = 0,
        /// xdg_toplevel already has a decoration object
        already_constructed = 1,
        /// xdg_toplevel destroyed before the decoration object
        orphaned = 2,
        /// invalid mode
        invalid_mode = 3,
    };
    /// window decoration modes
    pub const Mode = enum(u32) {
        /// no server-side window decoration
        client_side = 1,
        /// server-side window decoration
        server_side = 2,
    };
    pub const destroy_params = struct {
        pub const op = 0;
    };

    /// destroy the decoration object
    pub fn destroy(self: *const ToplevelDecorationV1, writer: anytype, params: destroy_params) !void {
        try wl_msg.write(writer, @TypeOf(params), params, self.id);
    }

    pub const set_mode_params = struct {
        pub const op = 1;
        /// the decoration mode
        mode: Mode,
    };

    /// set the decoration mode
    pub fn set_mode(self: *const ToplevelDecorationV1, writer: anytype, params: set_mode_params) !void {
        try wl_msg.write(writer, @TypeOf(params), params, self.id);
    }

    pub const unset_mode_params = struct {
        pub const op = 2;
    };

    /// unset the decoration mode
    pub fn unset_mode(self: *const ToplevelDecorationV1, writer: anytype, params: unset_mode_params) !void {
        try wl_msg.write(writer, @TypeOf(params), params, self.id);
    }
    pub const Event = union(enum) {
        configure: Event.Configure,

        /// notify a decoration mode change
        pub const Configure = struct {
            mode: ToplevelDecorationV1.Mode,
        };
        pub fn parse(op: u32, data: []const u8) !Event {
            return switch (op) {
                0 => .{ .configure = try wl_msg.parse_data(Event.Configure, data) },
                else => {
                    log.warn("Unknown toplevel_decoration_v1 event: {d}", .{op});
                    return error.UnknownEvent;
                },
            };
        }
    };
};
