const std = @import("std");
const builtin = @import("builtin");

const endian = builtin.cpu.arch.endian();
const u32_size = @sizeOf(u32);
const buf_align = u32_size;
const str_len_size = buf_align;

/// Wayland Wire Communication Header
///
/// 4 Bytes: ID of resource to call methods on
/// 2 Bytes: method opcode
/// 2 Bytes: size of message
/// Follow with any arguments to method
pub const Header = packed struct(u64) {
    id: u32,
    op: u16,
    msg_size: u16,
    pub const Size: u16 = @sizeOf(@This());
};

const EventParser = struct {
    buf: []const u8,

    pub fn get_u32(mp: *EventParser) !u32 {
        if (mp.buf.len < u32_size) {
            return error.InvalidLength;
        }

        const val = std.mem.bytesToValue(u32, mp.buf[0..u32_size]);
        mp.consume(u32_size);
        return val;
    }

    pub fn get_i32(mp: *EventParser) !i32 {
        return @intCast(try mp.get_u32());
    }

    pub fn get_arr(mp: *EventParser) ![]const u8 {
        if (mp.buf.len < u32_size) {
            return error.InvalidLength;
        }

        const msg_len = std.mem.bytesToValue(u32, mp.buf[0..u32_size]);
        const rounded_len = round_up(msg_len, u32_size);
        const consume_len = rounded_len + u32_size;

        if (consume_len > mp.buf.len) {
            return error.InvalidLength;
        }

        defer mp.consume(consume_len);
        const arr = mp.buf[u32_size .. u32_size + msg_len];
        return arr;
    }

    pub fn get_string(mp: *EventParser) ![:0]const u8 {
        const arr = try mp.get_arr();
        return @ptrCast(arr[0 .. arr.len - 1 :0]);
    }

    fn consume(mp: *EventParser, len: usize) void {
        if (mp.buf.len == len) {
            mp.buf = &.{};
        } else {
            mp.buf = mp.buf[len..];
        }
    }
};

pub fn parse_data(comptime T: type, data: []const u8) !T {
    var event_result: T = undefined;
    var ev_iter: EventParser = .{ .buf = data };
    inline for (std.meta.fields(T)) |field| {
        @field(event_result, field.name) = switch (field.type) {
            u32 => try ev_iter.get_u32(),
            i32 => try ev_iter.get_i32(),
            [:0]const u8 => try ev_iter.get_string(),
            []const u8 => try ev_iter.get_arr(),
            void => {},
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
            u32 => msg_size += u32_size,
            i32 => msg_size += u32_size,
            [:0]const u8 => msg_size += str_write_len(@field(item, field.name)),
            []const u8 => msg_size += arr_write_len(@field(item, field.name)),
            void => {},
            else => @compileLog("Unsupported field {s} of type {}", .{ field.name, field.type }),
        }
    }
    const header: Header = .{
        .id = id,
        .op = @TypeOf(item).op,
        .msg_size = @intCast(msg_size),
    };

    try writer.writeStruct(header);

    inline for (std.meta.fields(@TypeOf(item))) |field| {
        switch (field.type) {
            u32 => try writer.writeInt(u32, @field(item, field.name), endian),
            i32 => try writer.writeInt(i32, @field(item, field.name), endian),
            [:0]const u8 => try write_str(writer, @field(item, field.name)),
            []const u8 => try write_arr(writer, @field(item, field.name)),
            void => {},
            else => @compileLog("Unsupported field {s} of type {}", .{ field.name, field.type }),
        }
    }
}

fn arr_write_len(arr: []const u8) usize {
    return round_up(u32_size + arr.len, buf_align);
}
fn str_write_len(str: [:0]const u8) usize {
    return arr_write_len(str[0 .. str.len + 1]);
}

fn write_arr(writer: anytype, arr: []const u8) !void {
    const to_write = arr_write_len(arr);
    try writer.writeInt(u32, @intCast(arr.len), endian);
    try writer.writeAll(arr);
    const written = u32_size + arr.len;
    try writer.writeByteNTimes(0, to_write - written);
}

fn write_str(writer: anytype, str: [:0]const u8) !void {
    std.debug.print("writing: {s}\n", .{str});
    try write_arr(writer, @ptrCast(str[0 .. str.len + 1]));
}

/// Function for using Control Messages to send File Descriptors
/// TODO: make it work
pub fn write_ctrl_msg(writer: anytype, msg: []const u8, fd: std.posix.fd_t) !void {
    const control_msg: cmsg(std.posix.fd_t) = .{
        .level = std.posix.SOL.SOCKET,
        .type = 0x01, // SCM_RIGHTS
        .data = fd,
    };

    const iov = [1]std.posix.iovec_const{.{
        .base = msg.ptr,
        .len = msg.len,
    }};

    const cmsg_bytes = std.mem.asBytes(&control_msg);
    const sock_msg: std.posix.msghdr_const = .{
        .name = null,
        .namelen = 0,
        .iov = iov,
        .iovlen = 1,
        .control = cmsg_bytes.ptr,
        .controllen = cmsg_bytes.len,
        .flags = 0,
    };

    _ = try std.posix.sendmsg(writer.context.handle, &sock_msg, 0);
}

pub fn cmsg(comptime T: type) type {
    const padding_size = (@sizeOf(T) + @sizeOf(c_long) - 1) & ~(@as(usize, @sizeOf(c_long)) - 1);
    return packed struct {
        len: c_ulong = @sizeOf(@This()) - padding_size,
        level: c_int,
        type: c_int,
        data: T,
        _padding: std.meta.Int(.unsigned, 8 * padding_size) = 0,
    };
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
