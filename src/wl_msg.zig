const std = @import("std");
const builtin = @import("builtin");

const endian = builtin.cpu.arch.endian();
const u32_size = @sizeOf(u32);
const buf_align = u32_size;
const str_len_size = buf_align;
const SCM_RIGHTS = 0x01;

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
    var data_iter: EventParser = .{ .buf = data };

    // Leaving it null for the user to add onto the struct later
    // I don't love this solution, but if not this, I'd require the user
    // to provide an interface for interacting with a file descriptor queue
    if (@hasField(T, "fd")) {
        inline for (std.meta.fields(T)) |field| {
            if (!std.mem.eql(u8, "fd", field.name))
                @field(event_result, field.name) = switch (field.type) {
                    u32 => try data_iter.get_u32(),
                    i32 => try data_iter.get_i32(),
                    [:0]const u8 => try data_iter.get_string(),
                    []const u8 => try data_iter.get_arr(),
                    else => parse: {
                        switch (@typeInfo(field.type)) {
                            .@"enum" => break :parse @enumFromInt(try data_iter.get_u32()),
                            .@"struct" => |@"struct"| if (@"struct".layout == .@"packed") {
                                break :parse @bitCast(try data_iter.get_u32());
                            },
                            else => @compileLog("Data Parse Not Implemented for field {s} of type {}", .{ field.name, field.type }),
                        }
                    },
                };
        }
    } else {
        inline for (std.meta.fields(T)) |field| {
            @field(event_result, field.name) = switch (field.type) {
                u32 => try data_iter.get_u32(),
                i32 => try data_iter.get_i32(),
                [:0]const u8 => try data_iter.get_string(),
                []const u8 => try data_iter.get_arr(),
                else => parse: {
                    switch (@typeInfo(field.type)) {
                        .@"enum" => break :parse @enumFromInt(try data_iter.get_u32()),
                        .@"struct" => |@"struct"| if (@"struct".layout == .@"packed") {
                            break :parse @bitCast(try data_iter.get_u32());
                        },
                        else => @compileLog("Data Parse Not Implemented for field {s} of type {}", .{ field.name, field.type }),
                    }
                },
            };
        }
    }
    return event_result;
}

pub fn write(writer: anytype, comptime T: type, item: anytype, id: u32) !void {
    var msg_size: usize = Header.Size;
    inline for (std.meta.fields(@TypeOf(item))) |field| {
        const field_type: type = switch (@typeInfo(field.type)) {
            .@"enum" => u32,
            .@"struct" => |@"struct"| if (@"struct".layout == .@"packed") u32 else field.type,
            else => field.type,
        };
        switch (field_type) {
            i32, u32 => {
                if (!std.mem.eql(u8, field.name, "fd")) msg_size += u32_size;
            },
            [:0]const u8 => msg_size += str_write_len(@field(item, field.name)),
            []const u8 => msg_size += arr_write_len(@field(item, field.name)),
            else => @compileLog("Unsupported field {s} of type {}", .{ field.name, field.type }),
        }
    }
    const header: Header = .{
        .id = id,
        .op = @TypeOf(item).op,
        .msg_size = @intCast(msg_size),
    };
    try writer.writeStruct(header);

    if (@hasField(T, "fd")) {
        const msg_len = @sizeOf(T) - @sizeOf(std.posix.fd_t);
        var msg: [msg_len]u8 = undefined;
        var idx: usize = 0;
        var fd: std.posix.fd_t = undefined;
        inline for (std.meta.fields(@TypeOf(item))) |field| {
            const val = @field(item, field.name);
            if (std.mem.eql(u8, field.name, "fd")) {
                fd = @intCast(val);
            } else {
                const field_as_bytes = std.mem.asBytes(&val);
                @memcpy(msg[idx .. idx + field_as_bytes.len], field_as_bytes);
                idx += field_as_bytes.len;
            }
        }

        try write_control_msg(writer.context.handle, &msg, fd);
        return;
    }

    inline for (std.meta.fields(@TypeOf(item))) |field| {
        const field_type: type = switch (@typeInfo(field.type)) {
            .@"enum" => u32,
            .@"struct" => |@"struct"| if (@"struct".layout == .@"packed") u32 else field.type,
            else => field.type,
        };

        const field_val = @field(item, field.name);
        const msg_val = switch (@typeInfo(field.type)) {
            .@"enum" => @intFromEnum(field_val),
            .@"struct" => @as(u32, @bitCast(field_val)),
            else => field_val,
        };
        switch (field_type) {
            u32 => try writer.writeInt(u32, msg_val, endian),
            i32 => try writer.writeInt(i32, msg_val, endian),
            [:0]const u8 => try write_str(writer, msg_val),
            []const u8 => try write_arr(writer, msg_val),
            void => {}, // skip -- should be cmsg
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
    try write_arr(writer, @ptrCast(str[0 .. str.len + 1]));
}

fn write_control_msg(sock: std.posix.socket_t, msg_bytes: []const u8, fd: std.posix.fd_t) !void {
    const control_msg: cmsg(@TypeOf(fd)) = .{
        .level = std.posix.SOL.SOCKET,
        .type = SCM_RIGHTS,
        .data = fd,
    };

    const iov = [_]std.posix.iovec_const{
        .{
            .base = msg_bytes.ptr,
            .len = msg_bytes.len,
        },
    };

    const cmsg_bytes = std.mem.asBytes(&control_msg);
    const sock_msg: std.posix.msghdr_const = .{
        .name = null,
        .namelen = 0,
        .iov = &iov,
        .iovlen = iov.len,
        .control = cmsg_bytes.ptr,
        .controllen = cmsg_bytes.len,
        .flags = 0,
    };

    _ = try std.posix.sendmsg(sock, &sock_msg, 0);
}

/// Create data container for control messages
pub fn cmsg(comptime T: type) type {
    const msg_size = cmsg_len(@sizeOf(T));
    const padded_bit_count = ((8 * msg_size) - (@bitSizeOf(c_ulong) + (2 * @bitSizeOf(c_int)) + @bitSizeOf(T)));

    return packed struct {
        len: c_ulong = cmsg_len(@sizeOf(T)),
        level: c_int,
        type: c_int,
        data: T,
        __padding: std.meta.Int(.unsigned, padded_bit_count) = 0,

        pub const Padding = padded_bit_count / 8;
        pub const Size = msg_size;
    };
}

/// Ported version of musl libc's CMSG_ALIGN macro for getting alignment of a Control Message
///
/// Macro Definition:
/// #define CMSG_ALIGN(len) (((len) + sizeof (size_t) - 1) & (size_t) ~(sizeof (size_t) - 1))
fn cmsg_align(len: usize) usize {
    const size_t = c_ulong;
    return (((len) + @sizeOf(size_t) - 1) & ~(@as(usize, @sizeOf(size_t) - 1)));
}

/// Ported version of musl libc's CMSG_LEN macro for getting length of a Control Message
///
/// Macro Definition:
/// #define CMSG_LEN(len)   (CMSG_ALIGN (sizeof (struct cmsghdr)) + (len))
fn cmsg_len(len: usize) usize {
    return cmsg_align(@sizeOf(c_ulong) + (2 * @sizeOf(i32)) + len);
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
