const std = @import("std");
const meta = std.meta;
const protocols = @import("generated/protocols.zig");
const Arena = @import("Arena.zig");

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

    const ObjectTag = blk: {
        const enum_len = len_blk: {
            var decl_count: usize = 0;
            for (std.meta.declarations(protocols)) |protocol_decl| {
                const protocol = @field(protocols, protocol_decl.name);
                const interfaces = meta.fields(meta.DeclEnum(protocol));
                decl_count += interfaces.len;
            }
            break :len_blk decl_count;
        };

        var idx: u32 = 1;
        var fields: [enum_len + 1]std.builtin.Type.EnumField = undefined;

        fields[0] = .{
            .name = "nil",
            .value = 0,
        };

        for (std.meta.declarations(protocols)) |protocol_decl| {
            const protocol = @field(protocols, protocol_decl.name);

            for (std.meta.declarations(protocol)) |interface_decl| {
                const interface = @field(protocol, interface_decl.name);
                fields[idx] = .{
                    .name = @field(interface, "Name") ++ "",
                    .value = idx,
                };
                idx += 1;
            }
        }

        const T = @Type(.{
            .@"enum" = .{
                .tag_type = std.math.IntFittingRange(0, enum_len + 1),
                .fields = &fields,
                .decls = &.{},
                .is_exhaustive = true,
            },
        });
        break :blk T;
    };

    pub const Object = blk: {
        const union_len = len_blk: {
            var decl_count: usize = 0;
            for (std.meta.declarations(protocols)) |protocol_decl| {
                const protocol = @field(protocols, protocol_decl.name);
                const interfaces = meta.fields(meta.DeclEnum(protocol));
                decl_count += interfaces.len;
            }
            break :len_blk decl_count;
        };

        var idx: u32 = 1;
        var fields: [union_len + 1]std.builtin.Type.UnionField = undefined;

        fields[0] = .{
            .name = "nil",
            .type = void,
            .alignment = @alignOf(void),
        };

        for (std.meta.declarations(protocols)) |protocol_decl| {
            const protocol = @field(protocols, protocol_decl.name);

            for (@typeInfo(protocol).@"struct".decls) |interface_decl| {
                const interface = @field(protocol, interface_decl.name);
                fields[idx] = .{
                    .name = @field(interface, "Name") ++ "",
                    .type = interface,
                    .alignment = @alignOf(interface),
                };
                idx += 1;
            }
        }

        const T = @Type(.{
            .@"union" = .{
                .layout = .auto,
                .tag_type = ObjectTag,
                .fields = &fields,
                .decls = &.{},
            },
        });
        break :blk T;
    };

    cur_idx: u32,
    objects: []Object,
    registry: wl.Registry,
    free_list: IndexFreeQueue = .{},

    pub fn init(arena: *Arena, display: wl.Display) !Registry {
        const objects = arena.push(Object, 256);
        for (objects) |*obj| {
            obj = .{ .nil = {} };
        }
        objects[1] = display;

        return .{
            .cur_idx = 2,
            .registry = .{ .id = 2 },
            .objects = objects,
        };
    }

    pub fn deinit(self: *Registry) void {
        log.warn("Interface Registry deinit not yet implemented", .{});
        _ = self;
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
        self.objects[idx] = @unionInit(Object, @field(T, "Name"), .{ .id = idx });

        log.debug("Interface \"{s}\" bound with id :: {d}", .{ T.name, idx });
        return .{
            .id = idx,
        };
    }

    pub fn register(self: *Registry, comptime T: type) !T {
        const idx = if (self.free_list.next()) |freed_id|
            freed_id
        else blk: {
            defer self.cur_idx += 1;
            break :blk self.cur_idx;
        };

        self.objects[idx] = @unionInit(Object, @field(T, "Name"), .{ .id = idx });
        return .{
            .id = idx,
        };
    }

    pub fn get(self: *Registry, idx: u32) Object {
        return self.objects[idx];
    }

    pub fn remove(self: *Registry, obj: anytype) void {
        self.free_list.push(obj.id);
        _ = self.elems.remove(obj.id);
    }
};

pub var registry: Registry = undefined;
