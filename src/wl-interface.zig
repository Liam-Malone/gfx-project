const std = @import("std");
const protocols = @import("generated/protocols.zig");

const wl = protocols.wayland;

pub const Registry = struct {
    const IndexFreeQueue = struct {
        buf: [QueueSize]u32 = [_]u32{0} ** QueueSize,
        first: usize = 0,
        last: usize = 0,

        const QueueSize = 32;

        pub fn push(q: *IndexFreeQueue, idx: u32) void {
            q.buf[(q.last % QueueSize)] = idx;
            q.last += 1;
        }
        pub fn next(q: *IndexFreeQueue) ?u32 {
            const res = blk: {
                if (q.buf[(q.first % QueueSize)] == 0) {
                    break :blk null;
                } else {
                    defer q.first += 1;
                    defer q.buf[(q.first % QueueSize)] = 0;
                    break :blk q.buf[(q.first % QueueSize)];
                }
            };
            return res;
        }
    };

    const InterfaceMap = std.AutoHashMap(u32, type);

    cur_idx: u32,
    elems: InterfaceMap,
    registry: wl.Registry,
    free_list: IndexFreeQueue = .{},

    pub fn init(arena: std.mem.Allocator, writer: anytype, display: wl.Display) Registry {
        var map: InterfaceMap = .init(arena);
        try map.put(1, wl.Display);
        try map.put(2, wl.Registry);

        const wl_registry = display.get_registry(writer, .{});
        return .{
            .idx = 3,
            .elems = map,
            .registry = wl_registry,
        };
    }

    pub fn bind(self: *Registry, comptime T: type, writer: anytype, params: wl.Registry.Event.Global) !T {
        const idx = if (self.free_list.next()) |freed_id|
            freed_id
        else blk: {
            defer self.idx += 1;
            break :blk self.idx;
        };

        try self.registry.bind(writer, .{
            .name = params.name,
            .id_interface = params.interface,
            .id_interface_version = params.version,
            .id = idx,
        });

        try self.elems.put(idx, try .from_type(T));
        return .{
            .id = idx,
        };
    }

    pub fn insert(self: *Registry, id: u32, comptime T: type) !void {
        self.idx = id + 1;
        self.elems.put(id, T);
    }

    pub fn register(self: *Registry, comptime T: type) !T {
        const idx = if (self.free_list.next()) |freed_id|
            freed_id
        else blk: {
            defer self.idx += 1;
            break :blk self.idx;
        };

        try self.elems.put(idx, T);
        return .{
            .id = idx,
        };
    }

    pub fn remove(self: *Registry, obj: anytype) void {
        self.free_list.push(obj.id);
        _ = self.elems.remove(obj.id);
    }
};

pub var registry: Registry = undefined;
