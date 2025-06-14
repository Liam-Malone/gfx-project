const std = @import("std");
const builtin = @import("builtin");

const endian = builtin.cpu.arch.endian();
const u32_size = @sizeOf(u32);
const f32_size = @sizeOf(f32);
const buf_align = u32_size;
const str_len_size = buf_align;
const SCM_RIGHTS = 0x01;
const SCM_CREDENTIALS = 0x02;

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

    pub fn get_f32(mp: *EventParser) !f32 {
        if (mp.buf.len < f32_size) {
            return error.InvalidLength;
        }

        const val = std.mem.bytesToValue(i32, mp.buf[0..f32_size]);
        const float_val: f32 = @floatFromInt(val);
        mp.consume(f32_size);
        return (float_val / 256);
    }

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

    // Leaving the file descriptor undefined for the user to add onto the struct later
    // I don't love this solution, but if not this, I'd require the user
    // to provide an interface for interacting with a file descriptor queue
    if (@hasField(T, "fd")) {
        inline for (std.meta.fields(T)) |field| {
            if (!std.mem.eql(u8, "fd", field.name))
                @field(event_result, field.name) = switch (field.type) {
                    u32 => try data_iter.get_u32(),
                    i32 => try data_iter.get_i32(),
                    f32 => try data_iter.get_f32(),
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
                f32 => try data_iter.get_f32(),
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
            .optional => |Optional| Optional.child,
            else => field.type,
        };
        switch (field_type) {
            i32, u32 => {
                if (!std.mem.eql(u8, field.name, "fd")) msg_size += u32_size;
            },
            f32 => msg_size += f32_size,
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
                const field_as_bytes = if (@typeInfo(field.type) == .optional)
                    std.mem.asBytes(&(val.?))
                else
                    std.mem.asBytes(&val);
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
            .optional => |Optional| Optional.child,
            else => field.type,
        };

        const field_val = @field(item, field.name);
        const msg_val = switch (@typeInfo(field.type)) {
            .@"enum" => @intFromEnum(field_val),
            .@"struct" => @as(u32, @bitCast(field_val)),
            .optional => field_val.?,
            else => field_val,
        };
        switch (field_type) {
            f32 => try write_float(writer, msg_val),
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

fn write_float(writer: anytype, float: f32) !void {
    const val: i32 = @intFromFloat(float * 256);
    try writer.writeInt(i32, val, endian);
}

fn write_control_msg(sock: std.posix.socket_t, msg_bytes: []const u8, fd: std.posix.fd_t) !void {
    const control_msg: cmsg(@TypeOf(fd)) = .init(
        std.posix.SOL.SOCKET,
        SCM_RIGHTS,
        fd,
    );

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

/// Create container type for control messages
pub fn cmsg(comptime T: type) type {
    const msg_len = cmsghdr.msg_len(@sizeOf(T));
    const padded_bit_count = cmsghdr.padding_bits(msg_len, @bitSizeOf(T));

    return packed struct {
        /// Control message header
        header: cmsghdr,
        /// Data we actually want
        data: T,

        /// padding to reach data alignment
        __padding: @Type(.{
            .int = .{
                .bits = padded_bit_count,
                .signedness = .unsigned,
            },
        }) = 0,

        pub fn init(level: i32, @"type": i32, data: T) cmsg_t {
            return .{
                .header = .{
                    .len = msg_len,
                    .level = level,
                    .type = @"type",
                },
                .data = data,
            };
        }

        pub const Size = @sizeOf(cmsg_t);

        const cmsg_t = @This();
    };
}

const CmsgIterator = struct {
    buf: []const u8,
    idx: usize,

    const Iterator = @This();

    pub fn first(iter: *Iterator) ?cmsghdr {
        const result: ?cmsghdr = if (iter.buf[iter.idx..].len > @sizeOf(cmsghdr))
            std.mem.bytesToValue(cmsghdr, iter.buf[iter.idx..][0..@sizeOf(cmsghdr)])
        else
            null;

        return result;
    }

    pub fn next(iter: *Iterator) ?cmsghdr {
        const result: ?cmsghdr = if (iter.buf[iter.idx..].len > @sizeOf(cmsghdr)) hdr: { 
            const hdr = std.mem.bytesToValue(cmsghdr, iter.buf[iter.idx..][0..@sizeOf(cmsghdr)]);
            iter.idx += cmsghdr.__msg_len(&hdr);

            if (iter.idx >= iter.buf.len)
                iter.idx = iter.buf.len - 1;

            break :hdr hdr;
        } else
            null;

        return result;
    }

    pub fn reset(iter: *Iterator) void {
        iter.idx = 0;
    }
};

pub const cmsghdr = packed struct {
    /// Data byte count, including header
    len: usize,
    /// Originating protocol
    level: i32,
    /// Protocol-specific type
    type: i32,

    pub fn iter(buf: []const u8) CmsgIterator {
        return .{
            .buf = buf,
            .idx = 0,
        };
    }

    pub fn data(ptr: *const cmsghdr, comptime T: type) *const T {
        const buf: [*]const u8 = @ptrCast(@alignCast(ptr));

        return @ptrCast(@alignCast(buf[Size..][0..@sizeOf(T)].ptr));
    }

    /// Calculate length of control message given data of length `len`
    ///
    /// Port of musl libc's CMSG_LEN macro
    ///
    /// Macro Definition:
    /// #define CMSG_LEN(len)   (CMSG_ALIGN (sizeof (struct cmsghdr)) + (len))
    pub inline fn msg_len(len: usize) usize {
        return msg_align(cmsghdr.Size + len);
    }

    pub inline fn __msg_len(msg: *const cmsghdr) usize {
        return ((msg.len + @sizeOf(c_ulong) - 1) & ~@as(usize, (@sizeOf(c_ulong) - 1)));
    }

    /// Get the number of bits needed to pad out the message
    pub inline fn padding_bits(len: usize, data_t_size: usize) usize {
        return (8 * len) - (@bitSizeOf(cmsghdr) + data_t_size);
    }

    /// Calculate alignment of control message of length `len` to cmsghdr size
    ///
    /// Port of musl libc's CMSG_ALIGN macro
    ///
    /// Macro Definition:
    /// #define CMSG_ALIGN(len) (((len) + sizeof (size_t) - 1) & (size_t) ~(sizeof (size_t) - 1))
    inline fn msg_align(len: usize) usize {
        return (((len) + @sizeOf(size_t) - 1) & ~@as(usize, (@sizeOf(size_t) - 1)));
    }

    const size_t = usize;
    const Size = @sizeOf(@This());
};

inline fn round_up(val: anytype, mul: @TypeOf(val)) @TypeOf(val) {
    if (val == 0)
        return 0
    else
        return if (val % mul == 0)
            val
        else
            val + (mul - (val % mul));
}
