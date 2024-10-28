const std = @import("std");
const builtin = @import("builtin");

const endian = builtin.cpu.arch.endian();
const buf_align = @sizeOf(u32);
const str_len_size = buf_align;

const fd_t = packed struct {
    fd: std.posix.fd_t,
    len: u32,
};

/// Wayland Wire Communication Header
///
/// 4 Bytes: ID of resource to call methods on
/// 2 Bytes: method opcode
/// 2 Bytes: size of message
/// Follow with any arguments to method
pub const Header = packed struct {
    id: u32,
    op: u16,
    msg_size: u16,
    pub const Size: u16 = @sizeOf(@This());
};

const EventParser = struct {
    buf: []const u8,

    pub fn get_u32(mp: *EventParser) !u32 {
        if (mp.buf.len < @sizeOf(u32)) {
            return error.InvalidLength;
        }

        const val = std.mem.bytesToValue(u32, mp.buf[0..@sizeOf(u32)]);
        mp.consume(@sizeOf(u32));
        return val;
    }

    pub fn get_i32(mp: *EventParser) !i32 {
        return @intCast(try mp.get_u32());
    }

    pub fn get_arr(mp: *EventParser) ![]const u8 {
        if (mp.buf.len < @sizeOf(u32)) {
            return error.InvalidLength;
        }

        const msg_len = std.mem.bytesToValue(u32, mp.buf[0..@sizeOf(u32)]);
        const rounded_len = round_up(msg_len, @sizeOf(u32));
        const consume_len = rounded_len + @sizeOf(u32);

        if (consume_len > mp.buf.len) {
            return error.InvalidLength;
        }

        const str = mp.buf[@sizeOf(u32) .. @sizeOf(u32) + msg_len];
        mp.consume(consume_len);
        return str;
    }

    pub fn get_string(mp: *EventParser) ![:0]const u8 {
        if (mp.buf.len < @sizeOf(u32)) {
            return error.InvalidLength;
        }

        const msg_len = std.mem.bytesToValue(u32, mp.buf[0..@sizeOf(u32)]);
        const rounded_len = round_up(msg_len, @sizeOf(u32));
        const consume_len = rounded_len + @sizeOf(u32);

        if (consume_len > mp.buf.len) {
            return error.InvalidLength;
        }

        var buf = @constCast(mp.buf);
        buf[@sizeOf(u32) + msg_len + 1] = 0;
        const str = mp.buf[@sizeOf(u32) .. @sizeOf(u32) + msg_len :0];
        mp.consume(consume_len);
        return str;
    }

    fn consume(mp: *EventParser, len: usize) void {
        if (mp.buf.len == len) {
            mp.buf = &.{};
        } else {
            mp.buf = mp.buf[len..];
        }
    }
};

pub fn parse_event(comptime T: type, data: []const u8) !T {
    var event_result: T = undefined;
    var ev_iter: EventParser = .{ .buf = data };
    inline for (std.meta.fields(T)) |field| {
        @field(event_result, field.name) = switch (field.type) {
            u32 => try ev_iter.get_u32(),
            i32 => try ev_iter.get_i32(),
            [:0]const u8 => try ev_iter.get_string(),
            []const u8 => try ev_iter.get_arr(),
            else => {
                @compileLog("Data Parse Not Implemented for field {s} of type {}", .{ field.name, field.type });
            },
        };
    }
    return event_result;
}

pub fn write(writer: anytype, item: anytype, id: u32) !void {
    var msg_size: usize = Header.Size;
    inline for (std.meta.fields(@TypeOf(item))) |field| {
        switch (field.type) {
            fd_t => msg_size += @sizeOf(fd_t),
            u32, i32 => msg_size += @sizeOf(u32),
            []const u8, [:0]const u8 => msg_size += str_write_len(@field(item, field.name).len, @sizeOf(u32)),
            else => @compileLog("Unsupported field {s} of type {}", .{ field.name, field.type }),
        }
    }
    const header: Header = .{
        .id = id,
        .op = @TypeOf(item).op,
        .size = @intCast(msg_size),
    };

    try writer.writeStruct(header);

    inline for (std.meta.fields(@TypeOf(item))) |field| {
        switch (field.type) {
            u32, i32 => try writer.writeInt(field.type, @field(item, field.name), endian),
            [:0]const u8 => try write_str(writer, @field(item, field.name)),
            []const u8 => try write_arr(writer, @field(item, field.name)),
            fd_t => {
                const val = @field(item, field.name);
                write_ctrl_msg(writer, val.fd, val.len);
            },
            else => @compileLog("Unsupported field {s} of type {}", .{ field.name, field.type }),
        }
    }
}

inline fn arr_write_len(arr: []const u8) usize {
    return round_up(@sizeOf(u32) + arr, buf_align);
}
inline fn str_write_len(str: [:0]const u8) usize {
    return arr_write_len(str[0 .. str.len + 1]);
}

fn write_arr(writer: anytype, arr: []const u8) !void {
    const to_write: u32 = @intCast(arr_write_len(arr));
    try writer.writeInt(u32, to_write, endian);
    try writer.writeAll(arr);
    const written = str_len_size + arr.len;
    try writer.writeByteNTimes(0, to_write - written);
}

inline fn write_str(writer: anytype, str: [:0]const u8) !void {
    try write_arr(writer, str[0 .. str.len + 1]);
}

fn write_ctrl_msg(writer: anytype, fd: std.posix.fd_t, fd_len: u32) !void {
    try writer.writeInt(u32, fd_len, endian);
    const control_msg: cmsg(std.posix.fd_t) = .{
        .level = std.posix.SOL.SOCKET,
        .type = 0x01, // SCM_RIGHTS
        .data = fd,
    };

    const cmsg_bytes = std.mem.asBytes(&control_msg);
    const sock_msg: std.posix.msghdr_const = .{
        .name = null,
        .namelen = 0,
        .iov = &{},
        .iovlen = 0,
        .control = cmsg_bytes.ptr,
        .controllen = cmsg_bytes.len,
        .flags = 0,
    };

    _ = try std.posix.sendmsg(writer.context.handle, &sock_msg, 0);
}

fn round_up(val: anytype, mul: @TypeOf(val)) @TypeOf(val) {
    if (val == 0)
        return 0
    else
        return if (val % mul == 0)
            val
        else
            val + (mul - (val % mul));
}

fn cmsg(comptime T: type) type {
    const padding_size = (@sizeOf(T) + @sizeOf(c_long) - 1) & ~(@as(usize, @sizeOf(c_long)) - 1);
    return packed struct {
        len: c_ulong = @sizeOf(@This()) - padding_size,
        level: c_int,
        type: c_int,
        data: T,
        _padding: std.meta.Int(.unsigned, 8 * padding_size) = 0,
    };
}
