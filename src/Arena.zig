const std = @import("std");
const mem = std.mem;
const posix = std.posix;

pub const Arena = @This();

pub const Flags = packed struct {
    no_chain: bool,
    __padding_a: u31 = 0,
    large_pages: bool,
    __padding_b: u31 = 0,

    pub const default: @This() = .{
        .no_chain = false,
        .large_pages = false,
    };

    pub const largepage: @This() = .{
        .no_chain = false,
        .large_pages = true,
    };

    pub const nochain: @This() = .{
        .no_chain = true,
        .large_pages = false,
    };

    pub const large_nochain: @This() = .{
        .no_chain = true,
        .large_pages = true,
    };
};

pub const InitParams = struct {
    flags: Flags,
    reserve_size: usize,
    commit_size: usize,
    backing_buffer: ?[]align(mem.page_size) u8,

    pub const default: @This() = .{
        .flags = .default,
        .reserve_size = mem.page_size,
        .commit_size = mem.page_size,
        .backing_buffer = null,
    };

    pub const large_pages: @This() = .{
        .flags = .largepage,
        .reserve_size = to_unit(2, .megabytes),
        .commit_size = to_unit(2, .megabytes),
        .backing_buffer = null,
    };
};

prev: ?*Arena,
cur: *Arena,
flags: Flags,
cmt_size: usize,
res_size: usize,
base_pos: usize,
_pos: usize,
cmt: usize,
res: usize,

pub const Size = @sizeOf(Arena);

pub fn init(params: InitParams) *Arena {
    var reserve_size: usize = params.reserve_size;
    var commit_size: usize = params.commit_size;
    var flags: Flags = params.flags;
    if (params.flags.large_pages) {
        reserve_size = align_pow2(reserve_size, to_unit(2, .megabytes));
        commit_size = align_pow2(commit_size, to_unit(2, .megabytes));
    } else {
        reserve_size = align_pow2(reserve_size, mem.page_size);
        commit_size = align_pow2(commit_size, mem.page_size);
    }

    const base = if (params.backing_buffer) |buf|
        buf
    else if (params.flags.large_pages) base: {
        const ptr = mem_reserve_large(reserve_size) orelse ptr: {
            // Fallback to standard page sizes if large pages not working
            flags.large_pages = false;
            reserve_size = align_pow2(reserve_size, mem.page_size);
            commit_size = align_pow2(commit_size, mem.page_size);

            std.log.warn("Arena :: Mem_Reserve :: Large pages not supported, falling back to standard page sizes", .{});
            break :ptr mem_reserve(reserve_size);
        };

        if (ptr) |p| {
            if (flags.large_pages) {
                if (!mem_commit_large(p[0..commit_size]))
                    std.debug.print("Failed Large ({d} Bytes) Page Commit\n", .{commit_size});
            } else {
                if (!mem_commit(p[0..commit_size]))
                    std.debug.print("Failed {d}KB Page(s) Commit\n", .{mem.page_size});
            }
        }

        break :base ptr;
    } else base: {
        const ptr = mem_reserve(reserve_size);
        if (ptr) |p|
            if (!mem_commit(p[0..commit_size]))
                std.debug.print("Failed {d}KB Page(s) Commit\n", .{mem.page_size});

        break :base ptr;
    };

    const arena: *Arena = @ptrCast(base);

    arena.* = .{
        .flags = flags,
        .prev = null,
        .cur = arena,
        .cmt_size = commit_size,
        .res_size = reserve_size,
        .base_pos = 0,
        ._pos = Arena.Size,
        .cmt = commit_size,
        .res = reserve_size,
    };

    return arena;
}

pub fn push(arena: *Arena, comptime T: type, count: usize) []T {
    const data: []u8 = arena.push_impl((@sizeOf(T) * count), @max(8, @alignOf(T)));
    @memset(data[0..count], 0);
    const res: [*]T = @ptrCast(@alignCast(data));

    return (res[0..count]);
}

pub fn create(arena: *Arena, comptime T: type) *T {
    const data = arena.push(T, 1);

    return @ptrCast(@alignCast(data));
}

pub fn release(arena: *Arena) void {
    var next: ?*Arena = arena.cur;
    var prev: ?*Arena = null;
    while (next) |n| : (next = prev) {
        prev = n.prev;
        const ptr: [*]align(mem.page_size) u8 = @ptrCast(@alignCast(n));
        mem_release(ptr[0..n.res]);
    }
}

pub fn pos(arena: *Arena) usize {
    const cur = arena.cur;
    const _pos = cur.base_pos + cur._pos;

    return _pos;
}

pub fn pop_to(arena: *Arena, _pos: usize) void {
    const big_pos = if (Arena.Size < _pos) _pos else Arena.Size;
    var cur: *Arena = arena.cur;
    var prev: ?*Arena = null;

    while (cur.base_pos >= big_pos) : (cur = prev.?) {
        prev = cur.prev;
        const ptr: [*]align(mem.page_size) const u8 = @ptrCast(@alignCast(cur));
        mem_release(ptr[0..cur.res]);
    }

    arena.cur = cur;
    const new_pos = big_pos - cur.base_pos;
    cur._pos = new_pos;
}

pub fn temp(arena: *Arena) Temp {
    return .{
        .arena = arena,
        .pos = arena.pos(),
    };
}

pub fn end(tmp: *Temp) void {
    tmp.arena.pop_to(tmp.pos);
}

pub fn clear(arena: *Arena) void {
    arena.pop_to(0);
}

fn push_impl(arena: *Arena, size: usize, @"align": usize) []u8 {
    var cur: *Arena = arena.cur;
    var pos_pre: usize = @intCast(align_pow2(cur._pos, @"align"));
    var pos_pst: usize = pos_pre + size;

    // chain if needed
    if (cur.res < pos_pst and !(arena.flags.no_chain)) {
        var new_block: *Arena = new_block: {
            var res_size: usize = cur.res_size;
            var cmt_size: usize = cur.cmt_size;

            if (size + Arena.Size > res_size) {
                res_size = align_pow2(size + Arena.Size, @"align");
                cmt_size = align_pow2(size + Arena.Size, @"align");
            }

            break :new_block .init(.{
                .flags = cur.flags,
                .reserve_size = res_size, // had cur.res_size
                .commit_size = cmt_size, // had cur.cmt_size
                .backing_buffer = null,
            });
        };

        new_block.base_pos = cur.base_pos + cur.res;
        new_block.prev = arena.cur;
        arena.cur = new_block;

        cur = new_block;
        pos_pre = align_pow2(cur._pos, @"align");
        pos_pst = pos_pst + size;
    }

    // commit new pages if needed
    if (cur.cmt < pos_pst) {
        var cmt_pst_aligned: usize = pos_pst + @as(usize, cur.cmt_size - 1);
        cmt_pst_aligned -= cmt_pst_aligned % @as(usize, cur.cmt_size);

        const cmt_pst_clamped: usize = @min(cmt_pst_aligned, cur.res);
        const cmt_size = cmt_pst_clamped - cur.cmt;

        const ptr: [*]align(mem.page_size) u8 = @ptrCast(@alignCast(cur));
        const cmt_range = ptr[cur.cmt .. cur.cmt + cmt_size];
        if (cur.flags.large_pages) {
            if (!mem_commit_large(@alignCast(cmt_range)))
                std.debug.print("Failed to commit large page of mem: [{d}..{d}]\n", .{
                    cur.cmt,
                    cur.cmt + cmt_size,
                });
        } else {
            if (!mem_commit(@alignCast(cmt_range)))
                std.debug.print("Failed to commit page of mem: [{d}..{d}]\n", .{
                    cur.cmt,
                    cur.cmt + cmt_size,
                });
        }

        cur.cmt = cmt_pst_aligned;
    }

    const result: []u8 = if (cur.cmt >= pos_pst) result: {
        cur._pos = pos_pst;
        const ptr: [*]u8 = @alignCast(@ptrCast(cur));
        break :result ptr[pos_pre .. pos_pre + pos_pst];
    } else unreachable;

    return result;
}

fn mem_reserve(size: usize) ?[]align(mem.page_size) u8 {
    // TODO: add Windows path (VirtualAlloc())
    const ptr = posix.mmap(
        null,
        size,
        posix.PROT.NONE,
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    ) catch |err| ptr: {
        std.log.err("Memory reserve error :: {s}", .{@errorName(err)});
        break :ptr null;
    };

    return ptr;
}

fn mem_commit(ptr: []align(mem.page_size) u8) bool {
    // TODO: add Windows path (VirtualProtect())
    posix.mprotect(ptr, posix.PROT.READ | posix.PROT.WRITE) catch |err| {
        std.log.err("Memory commit error :: {s}", .{@errorName(err)});
        return false;
    };

    return true;
}

fn mem_decommit(ptr: []align(mem.page_size) const u8) void {
    // TODO: add Windows path (VirtualProtect())
    posix.madvise(ptr, ptr.len, posix.MADV.DONTNEED);
    posix.mprotect(ptr, posix.PROT.NONE);
}

fn mem_release(ptr: []align(mem.page_size) const u8) void {
    // TODO: add Windows path(VirtualFree())
    posix.munmap(ptr);
}

fn mem_reserve_large(size: usize) ?[]align(mem.page_size) u8 {
    // TODO: add Windows path (VirtualAlloc())
    const ptr = posix.mmap(
        null,
        size,
        posix.PROT.NONE,
        .{
            .TYPE = .PRIVATE,
            .ANONYMOUS = true,
            .HUGETLB = true,
        },
        -1,
        0,
    ) catch |err| ptr: {
        std.log.warn("Lage page ({d} Bytes) reserve error :: {s}", .{ size, @errorName(err) });
        break :ptr null;
    };

    return ptr;
}

fn mem_commit_large(ptr: []align(mem.page_size) u8) bool {
    // TODO: add Windows path (VirtualProtect())
    posix.mprotect(ptr, posix.PROT.READ | posix.PROT.WRITE) catch |err| {
        std.log.warn("Large page ({d} Bytes) commit error :: {s}", .{ ptr.len, @errorName(err) });
        return false;
    };

    return true;
}

// Zig Allocator Interface Implementation
pub fn allocator(arena: *Arena) std.mem.Allocator {
    return .{
        .ptr = @ptrCast(arena),
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .free = free, // TODO: add a free list
        },
    };
}

fn alloc(ctx: *anyopaque, n: usize, @"align": u8, ret_addr: usize) ?[*]u8 {
    const arena: *Arena = @ptrCast(@alignCast(ctx));
    _ = ret_addr;
    const ptr_align = @as(usize, 1) << @as(std.math.Log2Int(usize), @intCast(@"align"));
    return @ptrCast(arena.push_impl(n, ptr_align));
}
fn resize(ctx: *anyopaque, buf: []u8, log2_buf_align: u8, new_len: usize, ret_addr: usize) bool {
    const arena: *Arena = @ptrCast(@alignCast(ctx));
    const current = arena.cur;
    _ = log2_buf_align;
    _ = ret_addr;

    if (@intFromPtr(buf.ptr) != (@intFromPtr(current) + current.pos()) - buf.len) {
        return new_len <= buf.len;
    }

    if (buf.len >= new_len) {
        current._pos = @max(Arena.Size, current.pos() - (buf.len - new_len));
        return true;
    } else if (current.res - current.pos() >= new_len - buf.len) {
        current._pos += (new_len - buf.len);
        return true;
    } else {
        return false;
    }
}

pub const Temp = packed struct {
    arena: *Arena,
    pos: usize,

    pub fn end(tmp: *const Temp) void {
        tmp.arena.pop_to(tmp.pos);
    }
};

fn free(ctx: *anyopaque, buf: []u8, pow2_buf_align: u8, ret_addr: usize) void {
    _ = ctx;
    _ = pow2_buf_align;
    _ = ret_addr;

    // TODO: Implement a free list in arena
    _ = buf;
}

test "Normal Page Size" {
    const arena: *Arena = .init(.default);
    defer arena.release();

    // Mostly copied from std.heap.arena_allocator
    var rng_src = std.Random.DefaultPrng.init(19930913);
    const random = rng_src.random();
    var rounds: usize = 25;
    while (rounds > 0) {
        rounds -= 1;
        arena.clear();
        var alloced_bytes: usize = 0;
        const total_size: usize = random.intRangeAtMost(usize, 256, 16384);
        while (alloced_bytes < total_size) {
            const size = random.intRangeAtMost(usize, 16, 256);
            const alignment = 32;
            const slice = try arena.allocator().alignedAlloc(u8, alignment, size);
            try std.testing.expect(std.mem.isAligned(@intFromPtr(slice.ptr), alignment));
            try std.testing.expectEqual(size, slice.len);
            alloced_bytes += slice.len;
        }
    }
}

test "Large Page Reserve Fallback" {
    const params: Arena.InitParams = .large_pages;
    const arena: *Arena = .init(params);
    defer arena.release();

    // Mostly copied from std.heap.arena_allocator
    var rng_src = std.Random.DefaultPrng.init(19930913);
    const random = rng_src.random();
    var rounds: usize = 25;
    while (rounds > 0) {
        rounds -= 1;
        arena.clear();
        var alloced_bytes: usize = 0;
        const total_size: usize = random.intRangeAtMost(usize, 256, 16384);
        while (alloced_bytes < total_size) {
            const size = random.intRangeAtMost(usize, 16, 256);
            const alignment = 32;
            const slice = try arena.allocator().alignedAlloc(u8, alignment, size);
            try std.testing.expect(std.mem.isAligned(@intFromPtr(slice.ptr), alignment));
            try std.testing.expectEqual(size, slice.len);
            alloced_bytes += slice.len;
        }
        try std.testing.expectEqual(@as(Arena.Flags, .default), arena.flags); // Ensure No Fallback Required
    }
}

// test "Large Page Size" {
//     const params: Arena.InitParams = .large_pages;
//     const arena: *Arena = .init(params);
//     defer arena.release();
//
//     // Mostly copied from std.heap.arena_allocator
//     var rng_src = std.Random.DefaultPrng.init(19930913);
//     const random = rng_src.random();
//     var rounds: usize = 25;
//     while (rounds > 0) {
//         rounds -= 1;
//         arena.clear();
//         var alloced_bytes: usize = 0;
//         const total_size: usize = random.intRangeAtMost(usize, 256, 16384);
//         while (alloced_bytes < total_size) {
//             const size = random.intRangeAtMost(usize, 16, 256);
//             const alignment = 32;
//             const slice = try arena.allocator().alignedAlloc(u8, alignment, size);
//             try std.testing.expect(std.mem.isAligned(@intFromPtr(slice.ptr), alignment));
//             try std.testing.expectEqual(size, slice.len);
//             alloced_bytes += slice.len;
//         }
//         try std.testing.expectEqual(params.flags, arena.flags); // Ensure No Fallback Required
//     }
// }

test "Temp Arena" {
    const arena: *Arena = .init(.default);
    defer arena.release();
    const start_pos = arena.pos();

    const scratch = arena.temp();

    // Mostly copied from std.heap.arena_allocator
    var rng_src = std.Random.DefaultPrng.init(19930913);
    const random = rng_src.random();
    var rounds: usize = 25;
    while (rounds > 0) {
        rounds -= 1;
        var alloced_bytes: usize = 0;
        const total_size: usize = random.intRangeAtMost(usize, 256, 16384);
        while (alloced_bytes < total_size) {
            const size = random.intRangeAtMost(usize, 16, 256);
            const alignment = 32;
            const slice = try scratch.arena.allocator().alignedAlloc(u8, alignment, size);
            try std.testing.expect(std.mem.isAligned(@intFromPtr(slice.ptr), alignment));
            try std.testing.expectEqual(size, slice.len);
            alloced_bytes += slice.len;
        }
    }

    scratch.end();
    const end_pos = arena.pos();
    try std.testing.expect(start_pos == end_pos);
}

// Utility Functionality
const SizeUnit = enum(u6) {
    kilobytes = 10,
    megabytes = 20,
    gigabytes = 30,
    terabytes = 40,
};
pub fn to_unit(n: usize, unit: SizeUnit) usize {
    return (@as(usize, n) << @intFromEnum(unit));
}
pub fn align_pow2(x: usize, b: usize) usize {
    return @as(usize, (@as(usize, (x + b - 1)) & (~@as(usize, (b - 1)))));
}
