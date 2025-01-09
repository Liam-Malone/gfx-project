const std = @import("std");
pub const wl = struct {
    pub const display = struct {
        pub const name = "wl_display";
    };
    pub const seat = struct {
        pub const name = "wl_seat";
    };
    pub const surface = struct {
        pub const name = "wl_surface";
    };
};

const interface_map_entries = blk: {
    const entry_count = std.meta.declarations(wl).len;
    var idx: usize = 0;

    var entries: [entry_count]struct { []const u8, type } = undefined;
    for (std.meta.declarations(wl)) |interface| {
        const T = @field(wl, interface.name);
        entries[idx] = .{ T.name, T };
        idx += 1;
    }
    break :blk entries;
};

const interface_map: std.StaticStringMap(type) = .initComptime(interface_map_entries);
test {
    const @"type": type = interface_map.get("wl_surface") orelse return error.NoTypeFound;
    try std.testing.expect(@"type" == wl.surface);
}
