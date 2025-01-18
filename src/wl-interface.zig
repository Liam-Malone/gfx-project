const std = @import("std");
const meta = std.meta;
const protocols = @import("generated/protocols.zig");

const wl = protocols.wayland;
const log = std.log.scoped(.@"wl-interface");

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

    const InterfaceEnum = blk: {
        const enum_len = len_blk: {
            var decl_count: usize = 0;
            for (std.meta.declarations(protocols)) |protocol_decl| {
                const protocol = @field(protocols, protocol_decl.name);
                const interfaces = meta.fields(meta.DeclEnum(protocol));
                decl_count += interfaces.len;
            }
            break :len_blk decl_count;
        };

        var idx: u32 = 0;
        var fields: [enum_len]std.builtin.Type.EnumField = undefined;

        for (std.meta.declarations(protocols)) |protocol_decl| {
            const protocol = @field(protocols, protocol_decl.name);
            for (@typeInfo(meta.DeclEnum(protocol)).@"enum".fields) |interface_decl| {
                const interface = @field(protocol, interface_decl.name);
                fields[idx] = .{ .name = interface.name ++ "", .value = idx };
                idx += 1;
            }
        }

        break :blk @Type(.{
            .@"enum" = .{
                .tag_type = std.math.IntFittingRange(0, enum_len),
                .fields = &fields,
                .decls = &.{},
                .is_exhaustive = true,
            },
        });
    };

    const InterfaceMap = std.AutoHashMap(u32, InterfaceEnum);

    cur_idx: u32,
    elems: InterfaceMap,
    registry: wl.Registry,
    free_list: IndexFreeQueue = .{},

    pub fn init(arena: std.mem.Allocator, display: wl.Display) !Registry {
        var map: InterfaceMap = .init(arena);

        try map.put(1, meta.stringToEnum(InterfaceEnum, @TypeOf(display).name).?);

        return .{
            .cur_idx = 2,
            .elems = map,
            .registry = .{ .id = 2 },
        };
    }
    pub fn deinit(self: *Registry) void {
        log.warn("Interface Registry deinit not yet implemented", .{});
        self.elems.deinit();
    }

    pub fn bind(self: *Registry, comptime T: type, writer: anytype, params: wl.Registry.Event.Global) !T {
        const idx = if (self.free_list.next()) |freed_id|
            freed_id
        else blk: {
            defer self.cur_idx += 1;
            break :blk self.cur_idx;
        };

        try self.registry.bind(writer, .{
            .name = params.name,
            .id_interface = params.interface,
            .id_interface_version = params.version,
            .id = idx,
        });

        log.debug("Interface \"{s}\" bound with id :: {d}", .{ T.name, idx });
        try self.elems.put(idx, meta.stringToEnum(InterfaceEnum, T.name).?);
        return .{
            .id = idx,
        };
    }

    pub fn insert(self: *Registry, id: u32, comptime T: type) !void {
        self.cur_idx = id + 1;
        try self.elems.put(id, meta.stringToEnum(InterfaceEnum, T.name).?);
    }

    pub fn register(self: *Registry, comptime T: type) !T {
        const idx = if (self.free_list.next()) |freed_id|
            freed_id
        else blk: {
            defer self.cur_idx += 1;
            break :blk self.cur_idx;
        };

        try self.elems.put(idx, meta.stringToEnum(InterfaceEnum, T.name).?);
        log.info("Registering object \"{s}\" with id :: {d}", .{ T.name, idx });
        return .{
            .id = idx,
        };
    }

    pub fn get(self: *Registry, idx: u32) ?InterfaceEnum {
        return self.elems.get(idx);
    }

    pub fn remove(self: *Registry, obj: anytype) void {
        self.free_list.push(obj.id);
        _ = self.elems.remove(obj.id);
    }
};

pub var registry: Registry = undefined;
