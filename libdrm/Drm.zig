pub const __builtin_bswap16 = @import("std").zig.c_builtins.__builtin_bswap16;
pub const __builtin_bswap32 = @import("std").zig.c_builtins.__builtin_bswap32;
pub const __builtin_bswap64 = @import("std").zig.c_builtins.__builtin_bswap64;
pub const __builtin_signbit = @import("std").zig.c_builtins.__builtin_signbit;
pub const __builtin_signbitf = @import("std").zig.c_builtins.__builtin_signbitf;
pub const __builtin_popcount = @import("std").zig.c_builtins.__builtin_popcount;
pub const __builtin_ctz = @import("std").zig.c_builtins.__builtin_ctz;
pub const __builtin_clz = @import("std").zig.c_builtins.__builtin_clz;
pub const __builtin_sqrt = @import("std").zig.c_builtins.__builtin_sqrt;
pub const __builtin_sqrtf = @import("std").zig.c_builtins.__builtin_sqrtf;
pub const __builtin_sin = @import("std").zig.c_builtins.__builtin_sin;
pub const __builtin_sinf = @import("std").zig.c_builtins.__builtin_sinf;
pub const __builtin_cos = @import("std").zig.c_builtins.__builtin_cos;
pub const __builtin_cosf = @import("std").zig.c_builtins.__builtin_cosf;
pub const __builtin_exp = @import("std").zig.c_builtins.__builtin_exp;
pub const __builtin_expf = @import("std").zig.c_builtins.__builtin_expf;
pub const __builtin_exp2 = @import("std").zig.c_builtins.__builtin_exp2;
pub const __builtin_exp2f = @import("std").zig.c_builtins.__builtin_exp2f;
pub const __builtin_log = @import("std").zig.c_builtins.__builtin_log;
pub const __builtin_logf = @import("std").zig.c_builtins.__builtin_logf;
pub const __builtin_log2 = @import("std").zig.c_builtins.__builtin_log2;
pub const __builtin_log2f = @import("std").zig.c_builtins.__builtin_log2f;
pub const __builtin_log10 = @import("std").zig.c_builtins.__builtin_log10;
pub const __builtin_log10f = @import("std").zig.c_builtins.__builtin_log10f;
pub const __builtin_abs = @import("std").zig.c_builtins.__builtin_abs;
pub const __builtin_labs = @import("std").zig.c_builtins.__builtin_labs;
pub const __builtin_llabs = @import("std").zig.c_builtins.__builtin_llabs;
pub const __builtin_fabs = @import("std").zig.c_builtins.__builtin_fabs;
pub const __builtin_fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
pub const __builtin_floor = @import("std").zig.c_builtins.__builtin_floor;
pub const __builtin_floorf = @import("std").zig.c_builtins.__builtin_floorf;
pub const __builtin_ceil = @import("std").zig.c_builtins.__builtin_ceil;
pub const __builtin_ceilf = @import("std").zig.c_builtins.__builtin_ceilf;
pub const __builtin_trunc = @import("std").zig.c_builtins.__builtin_trunc;
pub const __builtin_truncf = @import("std").zig.c_builtins.__builtin_truncf;
pub const __builtin_round = @import("std").zig.c_builtins.__builtin_round;
pub const __builtin_roundf = @import("std").zig.c_builtins.__builtin_roundf;
pub const __builtin_strlen = @import("std").zig.c_builtins.__builtin_strlen;
pub const __builtin_strcmp = @import("std").zig.c_builtins.__builtin_strcmp;
pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
pub const __builtin_memset = @import("std").zig.c_builtins.__builtin_memset;
pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;
pub const __builtin_memcpy = @import("std").zig.c_builtins.__builtin_memcpy;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
pub const __builtin_nanf = @import("std").zig.c_builtins.__builtin_nanf;
pub const __builtin_huge_valf = @import("std").zig.c_builtins.__builtin_huge_valf;
pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
pub const __builtin_isnan = @import("std").zig.c_builtins.__builtin_isnan;
pub const __builtin_isinf = @import("std").zig.c_builtins.__builtin_isinf;
pub const __builtin_isinf_sign = @import("std").zig.c_builtins.__builtin_isinf_sign;
pub const __has_builtin = @import("std").zig.c_builtins.__has_builtin;
pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_unreachable = @import("std").zig.c_builtins.__builtin_unreachable;
pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;
pub const __builtin_mul_overflow = @import("std").zig.c_builtins.__builtin_mul_overflow;
pub const __s8 = i8;
pub const __u8 = u8;
pub const __s16 = c_short;
pub const __u16 = c_ushort;
pub const __s32 = c_int;
pub const __u32 = c_uint;
pub const __s64 = c_longlong;
pub const __u64 = c_ulonglong;
pub const __kernel_fd_set = extern struct {
    fds_bits: [16]c_ulong = @import("std").mem.zeroes([16]c_ulong),
};
pub const __kernel_sighandler_t = ?*const fn (c_int) callconv(.c) void;
pub const __kernel_key_t = c_int;
pub const __kernel_mqd_t = c_int;
pub const __kernel_old_uid_t = c_ushort;
pub const __kernel_old_gid_t = c_ushort;
pub const __kernel_old_dev_t = c_ulong;
pub const __kernel_long_t = c_long;
pub const __kernel_ulong_t = c_ulong;
pub const __kernel_ino_t = __kernel_ulong_t;
pub const __kernel_mode_t = c_uint;
pub const __kernel_pid_t = c_int;
pub const __kernel_ipc_pid_t = c_int;
pub const __kernel_uid_t = c_uint;
pub const __kernel_gid_t = c_uint;
pub const __kernel_suseconds_t = __kernel_long_t;
pub const __kernel_daddr_t = c_int;
pub const __kernel_uid32_t = c_uint;
pub const __kernel_gid32_t = c_uint;
pub const __kernel_size_t = __kernel_ulong_t;
pub const __kernel_ssize_t = __kernel_long_t;
pub const __kernel_ptrdiff_t = __kernel_long_t;
pub const __kernel_fsid_t = extern struct {
    val: [2]c_int = @import("std").mem.zeroes([2]c_int),
};
pub const __kernel_off_t = __kernel_long_t;
pub const __kernel_loff_t = c_longlong;
pub const __kernel_old_time_t = __kernel_long_t;
pub const __kernel_time_t = __kernel_long_t;
pub const __kernel_time64_t = c_longlong;
pub const __kernel_clock_t = __kernel_long_t;
pub const __kernel_timer_t = c_int;
pub const __kernel_clockid_t = c_int;
pub const __kernel_caddr_t = [*c]u8;
pub const __kernel_uid16_t = c_ushort;
pub const __kernel_gid16_t = c_ushort;
pub const __s128 = i128;
pub const __u128 = u128;
pub const __le16 = __u16;
pub const __be16 = __u16;
pub const __le32 = __u32;
pub const __be32 = __u32;
pub const __le64 = __u64;
pub const __be64 = __u64;
pub const __sum16 = __u16;
pub const __wsum = __u32;
pub const __poll_t = c_uint;
pub const drm_handle_t = c_uint;
pub const drm_context_t = c_uint;
pub const drm_drawable_t = c_uint;
pub const drm_magic_t = c_uint;
pub const struct_drm_clip_rect = extern struct {
    x1: c_ushort = @import("std").mem.zeroes(c_ushort),
    y1: c_ushort = @import("std").mem.zeroes(c_ushort),
    x2: c_ushort = @import("std").mem.zeroes(c_ushort),
    y2: c_ushort = @import("std").mem.zeroes(c_ushort),
};
pub const struct_drm_drawable_info = extern struct {
    num_rects: c_uint = @import("std").mem.zeroes(c_uint),
    rects: [*c]struct_drm_clip_rect = @import("std").mem.zeroes([*c]struct_drm_clip_rect),
};
pub const struct_drm_tex_region = extern struct {
    next: u8 = @import("std").mem.zeroes(u8),
    prev: u8 = @import("std").mem.zeroes(u8),
    in_use: u8 = @import("std").mem.zeroes(u8),
    padding: u8 = @import("std").mem.zeroes(u8),
    age: c_uint = @import("std").mem.zeroes(c_uint),
};
pub const struct_drm_hw_lock = extern struct {
    lock: c_uint = @import("std").mem.zeroes(c_uint),
    padding: [60]u8 = @import("std").mem.zeroes([60]u8),
};
pub const struct_drm_version = extern struct {
    version_major: c_int = @import("std").mem.zeroes(c_int),
    version_minor: c_int = @import("std").mem.zeroes(c_int),
    version_patchlevel: c_int = @import("std").mem.zeroes(c_int),
    name_len: __kernel_size_t = @import("std").mem.zeroes(__kernel_size_t),
    name: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    date_len: __kernel_size_t = @import("std").mem.zeroes(__kernel_size_t),
    date: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    desc_len: __kernel_size_t = @import("std").mem.zeroes(__kernel_size_t),
    desc: [*c]u8 = @import("std").mem.zeroes([*c]u8),
};
pub const struct_drm_unique = extern struct {
    unique_len: __kernel_size_t = @import("std").mem.zeroes(__kernel_size_t),
    unique: [*c]u8 = @import("std").mem.zeroes([*c]u8),
};
pub const struct_drm_list = extern struct {
    count: c_int = @import("std").mem.zeroes(c_int),
    version: [*c]struct_drm_version = @import("std").mem.zeroes([*c]struct_drm_version),
};
pub const struct_drm_block = extern struct {
    unused: c_int = @import("std").mem.zeroes(c_int),
};
pub const DRM_ADD_COMMAND: c_int = 0;
pub const DRM_RM_COMMAND: c_int = 1;
pub const DRM_INST_HANDLER: c_int = 2;
pub const DRM_UNINST_HANDLER: c_int = 3;
const enum_unnamed_1 = c_uint;
pub const struct_drm_control = extern struct {
    func: enum_unnamed_1 = @import("std").mem.zeroes(enum_unnamed_1),
    irq: c_int = @import("std").mem.zeroes(c_int),
};
pub const _DRM_FRAME_BUFFER: c_int = 0;
pub const _DRM_REGISTERS: c_int = 1;
pub const _DRM_SHM: c_int = 2;
pub const _DRM_AGP: c_int = 3;
pub const _DRM_SCATTER_GATHER: c_int = 4;
pub const _DRM_CONSISTENT: c_int = 5;
pub const enum_drm_map_type = c_uint;
pub const _DRM_RESTRICTED: c_int = 1;
pub const _DRM_READ_ONLY: c_int = 2;
pub const _DRM_LOCKED: c_int = 4;
pub const _DRM_KERNEL: c_int = 8;
pub const _DRM_WRITE_COMBINING: c_int = 16;
pub const _DRM_CONTAINS_LOCK: c_int = 32;
pub const _DRM_REMOVABLE: c_int = 64;
pub const _DRM_DRIVER: c_int = 128;
pub const enum_drm_map_flags = c_uint;
pub const struct_drm_ctx_priv_map = extern struct {
    ctx_id: c_uint = @import("std").mem.zeroes(c_uint),
    handle: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const struct_drm_map = extern struct {
    offset: c_ulong = @import("std").mem.zeroes(c_ulong),
    size: c_ulong = @import("std").mem.zeroes(c_ulong),
    type: enum_drm_map_type = @import("std").mem.zeroes(enum_drm_map_type),
    flags: enum_drm_map_flags = @import("std").mem.zeroes(enum_drm_map_flags),
    handle: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    mtrr: c_int = @import("std").mem.zeroes(c_int),
};
pub const struct_drm_client = extern struct {
    idx: c_int = @import("std").mem.zeroes(c_int),
    auth: c_int = @import("std").mem.zeroes(c_int),
    pid: c_ulong = @import("std").mem.zeroes(c_ulong),
    uid: c_ulong = @import("std").mem.zeroes(c_ulong),
    magic: c_ulong = @import("std").mem.zeroes(c_ulong),
    iocs: c_ulong = @import("std").mem.zeroes(c_ulong),
};
pub const _DRM_STAT_LOCK: c_int = 0;
pub const _DRM_STAT_OPENS: c_int = 1;
pub const _DRM_STAT_CLOSES: c_int = 2;
pub const _DRM_STAT_IOCTLS: c_int = 3;
pub const _DRM_STAT_LOCKS: c_int = 4;
pub const _DRM_STAT_UNLOCKS: c_int = 5;
pub const _DRM_STAT_VALUE: c_int = 6;
pub const _DRM_STAT_BYTE: c_int = 7;
pub const _DRM_STAT_COUNT: c_int = 8;
pub const _DRM_STAT_IRQ: c_int = 9;
pub const _DRM_STAT_PRIMARY: c_int = 10;
pub const _DRM_STAT_SECONDARY: c_int = 11;
pub const _DRM_STAT_DMA: c_int = 12;
pub const _DRM_STAT_SPECIAL: c_int = 13;
pub const _DRM_STAT_MISSED: c_int = 14;
pub const enum_drm_stat_type = c_uint;
const struct_unnamed_2 = extern struct {
    value: c_ulong = @import("std").mem.zeroes(c_ulong),
    type: enum_drm_stat_type = @import("std").mem.zeroes(enum_drm_stat_type),
};
pub const struct_drm_stats = extern struct {
    count: c_ulong = @import("std").mem.zeroes(c_ulong),
    data: [15]struct_unnamed_2 = @import("std").mem.zeroes([15]struct_unnamed_2),
};
pub const _DRM_LOCK_READY: c_int = 1;
pub const _DRM_LOCK_QUIESCENT: c_int = 2;
pub const _DRM_LOCK_FLUSH: c_int = 4;
pub const _DRM_LOCK_FLUSH_ALL: c_int = 8;
pub const _DRM_HALT_ALL_QUEUES: c_int = 16;
pub const _DRM_HALT_CUR_QUEUES: c_int = 32;
pub const enum_drm_lock_flags = c_uint;
pub const struct_drm_lock = extern struct {
    context: c_int = @import("std").mem.zeroes(c_int),
    flags: enum_drm_lock_flags = @import("std").mem.zeroes(enum_drm_lock_flags),
};
pub const _DRM_DMA_BLOCK: c_int = 1;
pub const _DRM_DMA_WHILE_LOCKED: c_int = 2;
pub const _DRM_DMA_PRIORITY: c_int = 4;
pub const _DRM_DMA_WAIT: c_int = 16;
pub const _DRM_DMA_SMALLER_OK: c_int = 32;
pub const _DRM_DMA_LARGER_OK: c_int = 64;
pub const enum_drm_dma_flags = c_uint;
pub const _DRM_PAGE_ALIGN: c_int = 1;
pub const _DRM_AGP_BUFFER: c_int = 2;
pub const _DRM_SG_BUFFER: c_int = 4;
pub const _DRM_FB_BUFFER: c_int = 8;
pub const _DRM_PCI_BUFFER_RO: c_int = 16;
const enum_unnamed_3 = c_uint;
pub const struct_drm_buf_desc = extern struct {
    count: c_int = @import("std").mem.zeroes(c_int),
    size: c_int = @import("std").mem.zeroes(c_int),
    low_mark: c_int = @import("std").mem.zeroes(c_int),
    high_mark: c_int = @import("std").mem.zeroes(c_int),
    flags: enum_unnamed_3 = @import("std").mem.zeroes(enum_unnamed_3),
    agp_start: c_ulong = @import("std").mem.zeroes(c_ulong),
};
pub const struct_drm_buf_info = extern struct {
    count: c_int = @import("std").mem.zeroes(c_int),
    list: [*c]struct_drm_buf_desc = @import("std").mem.zeroes([*c]struct_drm_buf_desc),
};
pub const struct_drm_buf_free = extern struct {
    count: c_int = @import("std").mem.zeroes(c_int),
    list: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
};
pub const struct_drm_buf_pub = extern struct {
    idx: c_int = @import("std").mem.zeroes(c_int),
    total: c_int = @import("std").mem.zeroes(c_int),
    used: c_int = @import("std").mem.zeroes(c_int),
    address: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const struct_drm_buf_map = extern struct {
    count: c_int = @import("std").mem.zeroes(c_int),
    virtual: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    list: [*c]struct_drm_buf_pub = @import("std").mem.zeroes([*c]struct_drm_buf_pub),
};
pub const struct_drm_dma = extern struct {
    context: c_int = @import("std").mem.zeroes(c_int),
    send_count: c_int = @import("std").mem.zeroes(c_int),
    send_indices: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    send_sizes: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    flags: enum_drm_dma_flags = @import("std").mem.zeroes(enum_drm_dma_flags),
    request_count: c_int = @import("std").mem.zeroes(c_int),
    request_size: c_int = @import("std").mem.zeroes(c_int),
    request_indices: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    request_sizes: [*c]c_int = @import("std").mem.zeroes([*c]c_int),
    granted_count: c_int = @import("std").mem.zeroes(c_int),
};
pub const _DRM_CONTEXT_PRESERVED: c_int = 1;
pub const _DRM_CONTEXT_2DONLY: c_int = 2;
pub const enum_drm_ctx_flags = c_uint;
pub const struct_drm_ctx = extern struct {
    handle: drm_context_t = @import("std").mem.zeroes(drm_context_t),
    flags: enum_drm_ctx_flags = @import("std").mem.zeroes(enum_drm_ctx_flags),
};
pub const struct_drm_ctx_res = extern struct {
    count: c_int = @import("std").mem.zeroes(c_int),
    contexts: [*c]struct_drm_ctx = @import("std").mem.zeroes([*c]struct_drm_ctx),
};
pub const struct_drm_draw = extern struct {
    handle: drm_drawable_t = @import("std").mem.zeroes(drm_drawable_t),
};
pub const DRM_DRAWABLE_CLIPRECTS: c_int = 0;
pub const drm_drawable_info_type_t = c_uint;
pub const struct_drm_update_draw = extern struct {
    handle: drm_drawable_t = @import("std").mem.zeroes(drm_drawable_t),
    type: c_uint = @import("std").mem.zeroes(c_uint),
    num: c_uint = @import("std").mem.zeroes(c_uint),
    data: c_ulonglong = @import("std").mem.zeroes(c_ulonglong),
};
pub const struct_drm_auth = extern struct {
    magic: drm_magic_t = @import("std").mem.zeroes(drm_magic_t),
};
pub const struct_drm_irq_busid = extern struct {
    irq: c_int = @import("std").mem.zeroes(c_int),
    busnum: c_int = @import("std").mem.zeroes(c_int),
    devnum: c_int = @import("std").mem.zeroes(c_int),
    funcnum: c_int = @import("std").mem.zeroes(c_int),
};
pub const _DRM_VBLANK_ABSOLUTE: c_int = 0;
pub const _DRM_VBLANK_RELATIVE: c_int = 1;
pub const _DRM_VBLANK_HIGH_CRTC_MASK: c_int = 62;
pub const _DRM_VBLANK_EVENT: c_int = 67108864;
pub const _DRM_VBLANK_FLIP: c_int = 134217728;
pub const _DRM_VBLANK_NEXTONMISS: c_int = 268435456;
pub const _DRM_VBLANK_SECONDARY: c_int = 536870912;
pub const _DRM_VBLANK_SIGNAL: c_int = 1073741824;
pub const enum_drm_vblank_seq_type = c_uint;
pub const struct_drm_wait_vblank_request = extern struct {
    type: enum_drm_vblank_seq_type = @import("std").mem.zeroes(enum_drm_vblank_seq_type),
    sequence: c_uint = @import("std").mem.zeroes(c_uint),
    signal: c_ulong = @import("std").mem.zeroes(c_ulong),
};
pub const struct_drm_wait_vblank_reply = extern struct {
    type: enum_drm_vblank_seq_type = @import("std").mem.zeroes(enum_drm_vblank_seq_type),
    sequence: c_uint = @import("std").mem.zeroes(c_uint),
    tval_sec: c_long = @import("std").mem.zeroes(c_long),
    tval_usec: c_long = @import("std").mem.zeroes(c_long),
};
pub const union_drm_wait_vblank = extern union {
    request: struct_drm_wait_vblank_request,
    reply: struct_drm_wait_vblank_reply,
};
pub const struct_drm_modeset_ctl = extern struct {
    crtc: __u32 = @import("std").mem.zeroes(__u32),
    cmd: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_agp_mode = extern struct {
    mode: c_ulong = @import("std").mem.zeroes(c_ulong),
};
pub const struct_drm_agp_buffer = extern struct {
    size: c_ulong = @import("std").mem.zeroes(c_ulong),
    handle: c_ulong = @import("std").mem.zeroes(c_ulong),
    type: c_ulong = @import("std").mem.zeroes(c_ulong),
    physical: c_ulong = @import("std").mem.zeroes(c_ulong),
};
pub const struct_drm_agp_binding = extern struct {
    handle: c_ulong = @import("std").mem.zeroes(c_ulong),
    offset: c_ulong = @import("std").mem.zeroes(c_ulong),
};
pub const struct_drm_agp_info = extern struct {
    agp_version_major: c_int = @import("std").mem.zeroes(c_int),
    agp_version_minor: c_int = @import("std").mem.zeroes(c_int),
    mode: c_ulong = @import("std").mem.zeroes(c_ulong),
    aperture_base: c_ulong = @import("std").mem.zeroes(c_ulong),
    aperture_size: c_ulong = @import("std").mem.zeroes(c_ulong),
    memory_allowed: c_ulong = @import("std").mem.zeroes(c_ulong),
    memory_used: c_ulong = @import("std").mem.zeroes(c_ulong),
    id_vendor: c_ushort = @import("std").mem.zeroes(c_ushort),
    id_device: c_ushort = @import("std").mem.zeroes(c_ushort),
};
pub const struct_drm_scatter_gather = extern struct {
    size: c_ulong = @import("std").mem.zeroes(c_ulong),
    handle: c_ulong = @import("std").mem.zeroes(c_ulong),
};
pub const struct_drm_set_version = extern struct {
    drm_di_major: c_int = @import("std").mem.zeroes(c_int),
    drm_di_minor: c_int = @import("std").mem.zeroes(c_int),
    drm_dd_major: c_int = @import("std").mem.zeroes(c_int),
    drm_dd_minor: c_int = @import("std").mem.zeroes(c_int),
};
pub const struct_drm_gem_close = extern struct {
    handle: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_gem_flink = extern struct {
    handle: __u32 = @import("std").mem.zeroes(__u32),
    name: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_gem_open = extern struct {
    name: __u32 = @import("std").mem.zeroes(__u32),
    handle: __u32 = @import("std").mem.zeroes(__u32),
    size: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_get_cap = extern struct {
    capability: __u64 = @import("std").mem.zeroes(__u64),
    value: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_set_client_cap = extern struct {
    capability: __u64 = @import("std").mem.zeroes(__u64),
    value: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_prime_handle = extern struct {
    handle: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    fd: __s32 = @import("std").mem.zeroes(__s32),
};
pub const struct_drm_syncobj_create = extern struct {
    handle: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_syncobj_destroy = extern struct {
    handle: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_syncobj_handle = extern struct {
    handle: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    fd: __s32 = @import("std").mem.zeroes(__s32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_syncobj_transfer = extern struct {
    src_handle: __u32 = @import("std").mem.zeroes(__u32),
    dst_handle: __u32 = @import("std").mem.zeroes(__u32),
    src_point: __u64 = @import("std").mem.zeroes(__u64),
    dst_point: __u64 = @import("std").mem.zeroes(__u64),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_syncobj_wait = extern struct {
    handles: __u64 = @import("std").mem.zeroes(__u64),
    timeout_nsec: __s64 = @import("std").mem.zeroes(__s64),
    count_handles: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    first_signaled: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
    deadline_nsec: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_syncobj_timeline_wait = extern struct {
    handles: __u64 = @import("std").mem.zeroes(__u64),
    points: __u64 = @import("std").mem.zeroes(__u64),
    timeout_nsec: __s64 = @import("std").mem.zeroes(__s64),
    count_handles: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    first_signaled: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
    deadline_nsec: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_syncobj_eventfd = extern struct {
    handle: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    point: __u64 = @import("std").mem.zeroes(__u64),
    fd: __s32 = @import("std").mem.zeroes(__s32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_syncobj_array = extern struct {
    handles: __u64 = @import("std").mem.zeroes(__u64),
    count_handles: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_syncobj_timeline_array = extern struct {
    handles: __u64 = @import("std").mem.zeroes(__u64),
    points: __u64 = @import("std").mem.zeroes(__u64),
    count_handles: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_crtc_get_sequence = extern struct {
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    active: __u32 = @import("std").mem.zeroes(__u32),
    sequence: __u64 = @import("std").mem.zeroes(__u64),
    sequence_ns: __s64 = @import("std").mem.zeroes(__s64),
};
pub const struct_drm_crtc_queue_sequence = extern struct {
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    sequence: __u64 = @import("std").mem.zeroes(__u64),
    user_data: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_modeinfo = extern struct {
    clock: __u32 = @import("std").mem.zeroes(__u32),
    hdisplay: __u16 = @import("std").mem.zeroes(__u16),
    hsync_start: __u16 = @import("std").mem.zeroes(__u16),
    hsync_end: __u16 = @import("std").mem.zeroes(__u16),
    htotal: __u16 = @import("std").mem.zeroes(__u16),
    hskew: __u16 = @import("std").mem.zeroes(__u16),
    vdisplay: __u16 = @import("std").mem.zeroes(__u16),
    vsync_start: __u16 = @import("std").mem.zeroes(__u16),
    vsync_end: __u16 = @import("std").mem.zeroes(__u16),
    vtotal: __u16 = @import("std").mem.zeroes(__u16),
    vscan: __u16 = @import("std").mem.zeroes(__u16),
    vrefresh: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    type: __u32 = @import("std").mem.zeroes(__u32),
    name: [32]u8 = @import("std").mem.zeroes([32]u8),
};
pub const struct_drm_mode_card_res = extern struct {
    fb_id_ptr: __u64 = @import("std").mem.zeroes(__u64),
    crtc_id_ptr: __u64 = @import("std").mem.zeroes(__u64),
    connector_id_ptr: __u64 = @import("std").mem.zeroes(__u64),
    encoder_id_ptr: __u64 = @import("std").mem.zeroes(__u64),
    count_fbs: __u32 = @import("std").mem.zeroes(__u32),
    count_crtcs: __u32 = @import("std").mem.zeroes(__u32),
    count_connectors: __u32 = @import("std").mem.zeroes(__u32),
    count_encoders: __u32 = @import("std").mem.zeroes(__u32),
    min_width: __u32 = @import("std").mem.zeroes(__u32),
    max_width: __u32 = @import("std").mem.zeroes(__u32),
    min_height: __u32 = @import("std").mem.zeroes(__u32),
    max_height: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_crtc = extern struct {
    set_connectors_ptr: __u64 = @import("std").mem.zeroes(__u64),
    count_connectors: __u32 = @import("std").mem.zeroes(__u32),
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    fb_id: __u32 = @import("std").mem.zeroes(__u32),
    x: __u32 = @import("std").mem.zeroes(__u32),
    y: __u32 = @import("std").mem.zeroes(__u32),
    gamma_size: __u32 = @import("std").mem.zeroes(__u32),
    mode_valid: __u32 = @import("std").mem.zeroes(__u32),
    mode: struct_drm_mode_modeinfo = @import("std").mem.zeroes(struct_drm_mode_modeinfo),
};
pub const struct_drm_mode_set_plane = extern struct {
    plane_id: __u32 = @import("std").mem.zeroes(__u32),
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    fb_id: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    crtc_x: __s32 = @import("std").mem.zeroes(__s32),
    crtc_y: __s32 = @import("std").mem.zeroes(__s32),
    crtc_w: __u32 = @import("std").mem.zeroes(__u32),
    crtc_h: __u32 = @import("std").mem.zeroes(__u32),
    src_x: __u32 = @import("std").mem.zeroes(__u32),
    src_y: __u32 = @import("std").mem.zeroes(__u32),
    src_h: __u32 = @import("std").mem.zeroes(__u32),
    src_w: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_get_plane = extern struct {
    plane_id: __u32 = @import("std").mem.zeroes(__u32),
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    fb_id: __u32 = @import("std").mem.zeroes(__u32),
    possible_crtcs: __u32 = @import("std").mem.zeroes(__u32),
    gamma_size: __u32 = @import("std").mem.zeroes(__u32),
    count_format_types: __u32 = @import("std").mem.zeroes(__u32),
    format_type_ptr: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_get_plane_res = extern struct {
    plane_id_ptr: __u64 = @import("std").mem.zeroes(__u64),
    count_planes: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_get_encoder = extern struct {
    encoder_id: __u32 = @import("std").mem.zeroes(__u32),
    encoder_type: __u32 = @import("std").mem.zeroes(__u32),
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    possible_crtcs: __u32 = @import("std").mem.zeroes(__u32),
    possible_clones: __u32 = @import("std").mem.zeroes(__u32),
};
pub const DRM_MODE_SUBCONNECTOR_Automatic: c_int = 0;
pub const DRM_MODE_SUBCONNECTOR_Unknown: c_int = 0;
pub const DRM_MODE_SUBCONNECTOR_VGA: c_int = 1;
pub const DRM_MODE_SUBCONNECTOR_DVID: c_int = 3;
pub const DRM_MODE_SUBCONNECTOR_DVIA: c_int = 4;
pub const DRM_MODE_SUBCONNECTOR_Composite: c_int = 5;
pub const DRM_MODE_SUBCONNECTOR_SVIDEO: c_int = 6;
pub const DRM_MODE_SUBCONNECTOR_Component: c_int = 8;
pub const DRM_MODE_SUBCONNECTOR_SCART: c_int = 9;
pub const DRM_MODE_SUBCONNECTOR_DisplayPort: c_int = 10;
pub const DRM_MODE_SUBCONNECTOR_HDMIA: c_int = 11;
pub const DRM_MODE_SUBCONNECTOR_Native: c_int = 15;
pub const DRM_MODE_SUBCONNECTOR_Wireless: c_int = 18;
pub const enum_drm_mode_subconnector = c_uint;
pub const struct_drm_mode_get_connector = extern struct {
    encoders_ptr: __u64 = @import("std").mem.zeroes(__u64),
    modes_ptr: __u64 = @import("std").mem.zeroes(__u64),
    props_ptr: __u64 = @import("std").mem.zeroes(__u64),
    prop_values_ptr: __u64 = @import("std").mem.zeroes(__u64),
    count_modes: __u32 = @import("std").mem.zeroes(__u32),
    count_props: __u32 = @import("std").mem.zeroes(__u32),
    count_encoders: __u32 = @import("std").mem.zeroes(__u32),
    encoder_id: __u32 = @import("std").mem.zeroes(__u32),
    connector_id: __u32 = @import("std").mem.zeroes(__u32),
    connector_type: __u32 = @import("std").mem.zeroes(__u32),
    connector_type_id: __u32 = @import("std").mem.zeroes(__u32),
    connection: __u32 = @import("std").mem.zeroes(__u32),
    mm_width: __u32 = @import("std").mem.zeroes(__u32),
    mm_height: __u32 = @import("std").mem.zeroes(__u32),
    subpixel: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_property_enum = extern struct {
    value: __u64 = @import("std").mem.zeroes(__u64),
    name: [32]u8 = @import("std").mem.zeroes([32]u8),
};
pub const struct_drm_mode_get_property = extern struct {
    values_ptr: __u64 = @import("std").mem.zeroes(__u64),
    enum_blob_ptr: __u64 = @import("std").mem.zeroes(__u64),
    prop_id: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    name: [32]u8 = @import("std").mem.zeroes([32]u8),
    count_values: __u32 = @import("std").mem.zeroes(__u32),
    count_enum_blobs: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_connector_set_property = extern struct {
    value: __u64 = @import("std").mem.zeroes(__u64),
    prop_id: __u32 = @import("std").mem.zeroes(__u32),
    connector_id: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_obj_get_properties = extern struct {
    props_ptr: __u64 = @import("std").mem.zeroes(__u64),
    prop_values_ptr: __u64 = @import("std").mem.zeroes(__u64),
    count_props: __u32 = @import("std").mem.zeroes(__u32),
    obj_id: __u32 = @import("std").mem.zeroes(__u32),
    obj_type: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_obj_set_property = extern struct {
    value: __u64 = @import("std").mem.zeroes(__u64),
    prop_id: __u32 = @import("std").mem.zeroes(__u32),
    obj_id: __u32 = @import("std").mem.zeroes(__u32),
    obj_type: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_get_blob = extern struct {
    blob_id: __u32 = @import("std").mem.zeroes(__u32),
    length: __u32 = @import("std").mem.zeroes(__u32),
    data: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_fb_cmd = extern struct {
    fb_id: __u32 = @import("std").mem.zeroes(__u32),
    width: __u32 = @import("std").mem.zeroes(__u32),
    height: __u32 = @import("std").mem.zeroes(__u32),
    pitch: __u32 = @import("std").mem.zeroes(__u32),
    bpp: __u32 = @import("std").mem.zeroes(__u32),
    depth: __u32 = @import("std").mem.zeroes(__u32),
    handle: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_fb_cmd2 = extern struct {
    fb_id: __u32 = @import("std").mem.zeroes(__u32),
    width: __u32 = @import("std").mem.zeroes(__u32),
    height: __u32 = @import("std").mem.zeroes(__u32),
    pixel_format: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    handles: [4]__u32 = @import("std").mem.zeroes([4]__u32),
    pitches: [4]__u32 = @import("std").mem.zeroes([4]__u32),
    offsets: [4]__u32 = @import("std").mem.zeroes([4]__u32),
    modifier: [4]__u64 = @import("std").mem.zeroes([4]__u64),
};
pub const struct_drm_mode_fb_dirty_cmd = extern struct {
    fb_id: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    color: __u32 = @import("std").mem.zeroes(__u32),
    num_clips: __u32 = @import("std").mem.zeroes(__u32),
    clips_ptr: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_mode_cmd = extern struct {
    connector_id: __u32 = @import("std").mem.zeroes(__u32),
    mode: struct_drm_mode_modeinfo = @import("std").mem.zeroes(struct_drm_mode_modeinfo),
};
pub const struct_drm_mode_cursor = extern struct {
    flags: __u32 = @import("std").mem.zeroes(__u32),
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    x: __s32 = @import("std").mem.zeroes(__s32),
    y: __s32 = @import("std").mem.zeroes(__s32),
    width: __u32 = @import("std").mem.zeroes(__u32),
    height: __u32 = @import("std").mem.zeroes(__u32),
    handle: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_cursor2 = extern struct {
    flags: __u32 = @import("std").mem.zeroes(__u32),
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    x: __s32 = @import("std").mem.zeroes(__s32),
    y: __s32 = @import("std").mem.zeroes(__s32),
    width: __u32 = @import("std").mem.zeroes(__u32),
    height: __u32 = @import("std").mem.zeroes(__u32),
    handle: __u32 = @import("std").mem.zeroes(__u32),
    hot_x: __s32 = @import("std").mem.zeroes(__s32),
    hot_y: __s32 = @import("std").mem.zeroes(__s32),
};
pub const struct_drm_mode_crtc_lut = extern struct {
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    gamma_size: __u32 = @import("std").mem.zeroes(__u32),
    red: __u64 = @import("std").mem.zeroes(__u64),
    green: __u64 = @import("std").mem.zeroes(__u64),
    blue: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_color_ctm = extern struct {
    matrix: [9]__u64 = @import("std").mem.zeroes([9]__u64),
};
pub const struct_drm_color_lut = extern struct {
    red: __u16 = @import("std").mem.zeroes(__u16),
    green: __u16 = @import("std").mem.zeroes(__u16),
    blue: __u16 = @import("std").mem.zeroes(__u16),
    reserved: __u16 = @import("std").mem.zeroes(__u16),
};
pub const struct_drm_plane_size_hint = extern struct {
    width: __u16 = @import("std").mem.zeroes(__u16),
    height: __u16 = @import("std").mem.zeroes(__u16),
};
const struct_unnamed_4 = extern struct {
    x: __u16 = @import("std").mem.zeroes(__u16),
    y: __u16 = @import("std").mem.zeroes(__u16),
};
const struct_unnamed_5 = extern struct {
    x: __u16 = @import("std").mem.zeroes(__u16),
    y: __u16 = @import("std").mem.zeroes(__u16),
};
pub const struct_hdr_metadata_infoframe = extern struct {
    eotf: __u8 = @import("std").mem.zeroes(__u8),
    metadata_type: __u8 = @import("std").mem.zeroes(__u8),
    display_primaries: [3]struct_unnamed_4 = @import("std").mem.zeroes([3]struct_unnamed_4),
    white_point: struct_unnamed_5 = @import("std").mem.zeroes(struct_unnamed_5),
    max_display_mastering_luminance: __u16 = @import("std").mem.zeroes(__u16),
    min_display_mastering_luminance: __u16 = @import("std").mem.zeroes(__u16),
    max_cll: __u16 = @import("std").mem.zeroes(__u16),
    max_fall: __u16 = @import("std").mem.zeroes(__u16),
};
const union_unnamed_6 = extern union {
    hdmi_metadata_type1: struct_hdr_metadata_infoframe,
};
pub const struct_hdr_output_metadata = extern struct {
    metadata_type: __u32 = @import("std").mem.zeroes(__u32),
    unnamed_0: union_unnamed_6 = @import("std").mem.zeroes(union_unnamed_6),
};
pub const struct_drm_mode_crtc_page_flip = extern struct {
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    fb_id: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    reserved: __u32 = @import("std").mem.zeroes(__u32),
    user_data: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_crtc_page_flip_target = extern struct {
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
    fb_id: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    sequence: __u32 = @import("std").mem.zeroes(__u32),
    user_data: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_create_dumb = extern struct {
    height: __u32 = @import("std").mem.zeroes(__u32),
    width: __u32 = @import("std").mem.zeroes(__u32),
    bpp: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    handle: __u32 = @import("std").mem.zeroes(__u32),
    pitch: __u32 = @import("std").mem.zeroes(__u32),
    size: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_map_dumb = extern struct {
    handle: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
    offset: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_destroy_dumb = extern struct {
    handle: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_atomic = extern struct {
    flags: __u32 = @import("std").mem.zeroes(__u32),
    count_objs: __u32 = @import("std").mem.zeroes(__u32),
    objs_ptr: __u64 = @import("std").mem.zeroes(__u64),
    count_props_ptr: __u64 = @import("std").mem.zeroes(__u64),
    props_ptr: __u64 = @import("std").mem.zeroes(__u64),
    prop_values_ptr: __u64 = @import("std").mem.zeroes(__u64),
    reserved: __u64 = @import("std").mem.zeroes(__u64),
    user_data: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_format_modifier_blob = extern struct {
    version: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    count_formats: __u32 = @import("std").mem.zeroes(__u32),
    formats_offset: __u32 = @import("std").mem.zeroes(__u32),
    count_modifiers: __u32 = @import("std").mem.zeroes(__u32),
    modifiers_offset: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_format_modifier = extern struct {
    formats: __u64 = @import("std").mem.zeroes(__u64),
    offset: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
    modifier: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_create_blob = extern struct {
    data: __u64 = @import("std").mem.zeroes(__u64),
    length: __u32 = @import("std").mem.zeroes(__u32),
    blob_id: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_destroy_blob = extern struct {
    blob_id: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_create_lease = extern struct {
    object_ids: __u64 = @import("std").mem.zeroes(__u64),
    object_count: __u32 = @import("std").mem.zeroes(__u32),
    flags: __u32 = @import("std").mem.zeroes(__u32),
    lessee_id: __u32 = @import("std").mem.zeroes(__u32),
    fd: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_list_lessees = extern struct {
    count_lessees: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
    lessees_ptr: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_get_lease = extern struct {
    count_objects: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
    objects_ptr: __u64 = @import("std").mem.zeroes(__u64),
};
pub const struct_drm_mode_revoke_lease = extern struct {
    lessee_id: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_mode_rect = extern struct {
    x1: __s32 = @import("std").mem.zeroes(__s32),
    y1: __s32 = @import("std").mem.zeroes(__s32),
    x2: __s32 = @import("std").mem.zeroes(__s32),
    y2: __s32 = @import("std").mem.zeroes(__s32),
};
pub const struct_drm_mode_closefb = extern struct {
    fb_id: __u32 = @import("std").mem.zeroes(__u32),
    pad: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_event = extern struct {
    type: __u32 = @import("std").mem.zeroes(__u32),
    length: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_event_vblank = extern struct {
    base: struct_drm_event = @import("std").mem.zeroes(struct_drm_event),
    user_data: __u64 = @import("std").mem.zeroes(__u64),
    tv_sec: __u32 = @import("std").mem.zeroes(__u32),
    tv_usec: __u32 = @import("std").mem.zeroes(__u32),
    sequence: __u32 = @import("std").mem.zeroes(__u32),
    crtc_id: __u32 = @import("std").mem.zeroes(__u32),
};
pub const struct_drm_event_crtc_sequence = extern struct {
    base: struct_drm_event = @import("std").mem.zeroes(struct_drm_event),
    user_data: __u64 = @import("std").mem.zeroes(__u64),
    time_ns: __s64 = @import("std").mem.zeroes(__s64),
    sequence: __u64 = @import("std").mem.zeroes(__u64),
};
pub const drm_clip_rect_t = struct_drm_clip_rect;
pub const drm_drawable_info_t = struct_drm_drawable_info;
pub const drm_tex_region_t = struct_drm_tex_region;
pub const drm_hw_lock_t = struct_drm_hw_lock;
pub const drm_version_t = struct_drm_version;
pub const drm_unique_t = struct_drm_unique;
pub const drm_list_t = struct_drm_list;
pub const drm_block_t = struct_drm_block;
pub const drm_control_t = struct_drm_control;
pub const drm_map_type_t = enum_drm_map_type;
pub const drm_map_flags_t = enum_drm_map_flags;
pub const drm_ctx_priv_map_t = struct_drm_ctx_priv_map;
pub const drm_map_t = struct_drm_map;
pub const drm_client_t = struct_drm_client;
pub const drm_stat_type_t = enum_drm_stat_type;
pub const drm_stats_t = struct_drm_stats;
pub const drm_lock_flags_t = enum_drm_lock_flags;
pub const drm_lock_t = struct_drm_lock;
pub const drm_dma_flags_t = enum_drm_dma_flags;
pub const drm_buf_desc_t = struct_drm_buf_desc;
pub const drm_buf_info_t = struct_drm_buf_info;
pub const drm_buf_free_t = struct_drm_buf_free;
pub const drm_buf_pub_t = struct_drm_buf_pub;
pub const drm_buf_map_t = struct_drm_buf_map;
pub const drm_dma_t = struct_drm_dma;
pub const drm_wait_vblank_t = union_drm_wait_vblank;
pub const drm_agp_mode_t = struct_drm_agp_mode;
pub const drm_ctx_flags_t = enum_drm_ctx_flags;
pub const drm_ctx_t = struct_drm_ctx;
pub const drm_ctx_res_t = struct_drm_ctx_res;
pub const drm_draw_t = struct_drm_draw;
pub const drm_update_draw_t = struct_drm_update_draw;
pub const drm_auth_t = struct_drm_auth;
pub const drm_irq_busid_t = struct_drm_irq_busid;
pub const drm_vblank_seq_type_t = enum_drm_vblank_seq_type;
pub const drm_agp_buffer_t = struct_drm_agp_buffer;
pub const drm_agp_binding_t = struct_drm_agp_binding;
pub const drm_agp_info_t = struct_drm_agp_info;
pub const drm_scatter_gather_t = struct_drm_scatter_gather;
pub const drm_set_version_t = struct_drm_set_version;
pub fn drm_fourcc_canonicalize_nvidia_format_mod(arg_modifier: __u64) callconv(.c) __u64 {
    var modifier = arg_modifier;
    _ = &modifier;
    if (!((modifier & @as(__u64, @bitCast(@as(c_longlong, @as(c_int, 16))))) != 0) or ((modifier & @as(__u64, @bitCast(@as(c_longlong, @as(c_int, 255) << @intCast(12))))) != 0)) return modifier else return modifier | @as(__u64, @bitCast(@as(c_longlong, @as(c_int, 254) << @intCast(12))));
    return @import("std").mem.zeroes(__u64);
}
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 19);
pub const __clang_minor__ = @as(c_int, 1);
pub const __clang_patchlevel__ = @as(c_int, 7);
pub const __clang_version__ = "19.1.7 ";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __MEMORY_SCOPE_SYSTEM = @as(c_int, 0);
pub const __MEMORY_SCOPE_DEVICE = @as(c_int, 1);
pub const __MEMORY_SCOPE_WRKGRP = @as(c_int, 2);
pub const __MEMORY_SCOPE_WVFRNT = @as(c_int, 3);
pub const __MEMORY_SCOPE_SINGLE = @as(c_int, 4);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __FPCLASS_SNAN = @as(c_int, 0x0001);
pub const __FPCLASS_QNAN = @as(c_int, 0x0002);
pub const __FPCLASS_NEGINF = @as(c_int, 0x0004);
pub const __FPCLASS_NEGNORMAL = @as(c_int, 0x0008);
pub const __FPCLASS_NEGSUBNORMAL = @as(c_int, 0x0010);
pub const __FPCLASS_NEGZERO = @as(c_int, 0x0020);
pub const __FPCLASS_POSZERO = @as(c_int, 0x0040);
pub const __FPCLASS_POSSUBNORMAL = @as(c_int, 0x0080);
pub const __FPCLASS_POSNORMAL = @as(c_int, 0x0100);
pub const __FPCLASS_POSINF = @as(c_int, 0x0200);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 19.1.7";
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-32";
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_WIDTH__ = @as(c_int, 64);
pub const __LLONG_WIDTH__ = @as(c_int, 64);
pub const __BITINT_MAXWIDTH__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 8388608, .decimal);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __INTMAX_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_long;
pub const __INTMAX_FMTd__ = "ld";
pub const __INTMAX_FMTi__ = "li";
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`");
// (no file):95:9
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_FMTo__ = "lo";
pub const __UINTMAX_FMTu__ = "lu";
pub const __UINTMAX_FMTx__ = "lx";
pub const __UINTMAX_FMTX__ = "lX";
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// (no file):101:9
pub const __PTRDIFF_TYPE__ = c_long;
pub const __PTRDIFF_FMTd__ = "ld";
pub const __PTRDIFF_FMTi__ = "li";
pub const __INTPTR_TYPE__ = c_long;
pub const __INTPTR_FMTd__ = "ld";
pub const __INTPTR_FMTi__ = "li";
pub const __SIZE_TYPE__ = c_ulong;
pub const __SIZE_FMTo__ = "lo";
pub const __SIZE_FMTu__ = "lu";
pub const __SIZE_FMTx__ = "lx";
pub const __SIZE_FMTX__ = "lX";
pub const __WCHAR_TYPE__ = c_int;
pub const __WINT_TYPE__ = c_uint;
pub const __SIG_ATOMIC_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTPTR_TYPE__ = c_ulong;
pub const __UINTPTR_FMTo__ = "lo";
pub const __UINTPTR_FMTu__ = "lu";
pub const __UINTPTR_FMTx__ = "lx";
pub const __UINTPTR_FMTX__ = "lX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_NORM_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT16_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_NORM_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_NORM_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_NORM_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 16);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub const __INT64_TYPE__ = c_long;
pub const __INT64_FMTd__ = "ld";
pub const __INT64_FMTi__ = "li";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`");
// (no file):202:9
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub const __UINT16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`");
// (no file):224:9
pub const __UINT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulong;
pub const __UINT64_FMTo__ = "lo";
pub const __UINT64_FMTu__ = "lu";
pub const __UINT64_FMTx__ = "lx";
pub const __UINT64_FMTX__ = "lX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// (no file):232:9
pub const __UINT64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __INT64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_long;
pub const __INT_LEAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_LEAST64_FMTd__ = "ld";
pub const __INT_LEAST64_FMTi__ = "li";
pub const __UINT_LEAST64_TYPE__ = c_ulong;
pub const __UINT_LEAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_LEAST64_FMTo__ = "lo";
pub const __UINT_LEAST64_FMTu__ = "lu";
pub const __UINT_LEAST64_FMTx__ = "lx";
pub const __UINT_LEAST64_FMTX__ = "lX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_TYPE__ = c_long;
pub const __INT_FAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_FAST64_FMTd__ = "ld";
pub const __INT_FAST64_FMTi__ = "li";
pub const __UINT_FAST64_TYPE__ = c_ulong;
pub const __UINT_FAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_FAST64_FMTo__ = "lo";
pub const __UINT_FAST64_FMTu__ = "lu";
pub const __UINT_FAST64_FMTx__ = "lx";
pub const __UINT_FAST64_FMTX__ = "lX";
pub const __USER_LABEL_PREFIX__ = "";
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __GCC_DESTRUCTIVE_SIZE = @as(c_int, 64);
pub const __GCC_CONSTRUCTIVE_SIZE = @as(c_int, 64);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __NO_INLINE__ = @as(c_int, 1);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __SSP_STRONG__ = @as(c_int, 2);
pub const __ELF__ = @as(c_int, 1);
pub const __GCC_ASM_FLAG_OUTPUTS__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):366:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):367:9
pub const __corei7 = @as(c_int, 1);
pub const __corei7__ = @as(c_int, 1);
pub const __tune_corei7__ = @as(c_int, 1);
pub const __REGISTER_PREFIX__ = "";
pub const __NO_MATH_INLINES = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __VAES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __VPCLMULQDQ__ = @as(c_int, 1);
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __GFNI__ = @as(c_int, 1);
pub const __SHA__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __PKU__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __CLWB__ = @as(c_int, 1);
pub const __SHSTK__ = @as(c_int, 1);
pub const __KL__ = @as(c_int, 1);
pub const __WIDEKL__ = @as(c_int, 1);
pub const __RDPID__ = @as(c_int, 1);
pub const __WAITPKG__ = @as(c_int, 1);
pub const __MOVDIRI__ = @as(c_int, 1);
pub const __MOVDIR64B__ = @as(c_int, 1);
pub const __PTWRITE__ = @as(c_int, 1);
pub const __INVPCID__ = @as(c_int, 1);
pub const __HRESET__ = @as(c_int, 1);
pub const __AVXVNNI__ = @as(c_int, 1);
pub const __SERIALIZE__ = @as(c_int, 1);
pub const __CRC32__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE2_MATH__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const linux = @as(c_int, 1);
pub const __linux = @as(c_int, 1);
pub const __linux__ = @as(c_int, 1);
pub const __gnu_linux__ = @as(c_int, 1);
pub const __FLOAT128__ = @as(c_int, 1);
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const __GLIBC_MINOR__ = @as(c_int, 39);
pub const _DEBUG = @as(c_int, 1);
pub const __GCC_HAVE_DWARF2_CFI_ASM = @as(c_int, 1);
pub const DRM_FOURCC_H = "";
pub const _DRM_H_ = "";
pub const _LINUX_TYPES_H = "";
pub const _ASM_GENERIC_TYPES_H = "";
pub const _ASM_GENERIC_INT_LL64_H = "";
pub const __ASM_X86_BITSPERLONG_H = "";
pub const __BITS_PER_LONG = @as(c_int, 64);
pub const __ASM_GENERIC_BITS_PER_LONG = "";
pub const __BITS_PER_LONG_LONG = @as(c_int, 64);
pub const _LINUX_POSIX_TYPES_H = "";
pub const _LINUX_STDDEF_H = "";
pub const __always_inline = @compileError("unable to translate C expr: unexpected token '__inline__'");
// /nix/store/1ycjq6h047qqwp3fm9sbl805xnrxlh2h-glibc-2.40-66-dev/include/linux/stddef.h:8:9
pub const __struct_group = @compileError("unable to translate C expr: expected ')' instead got '...'");
// /nix/store/1ycjq6h047qqwp3fm9sbl805xnrxlh2h-glibc-2.40-66-dev/include/linux/stddef.h:26:9
pub const __DECLARE_FLEX_ARRAY = @compileError("unable to translate macro: undefined identifier `__empty_`");
// /nix/store/1ycjq6h047qqwp3fm9sbl805xnrxlh2h-glibc-2.40-66-dev/include/linux/stddef.h:47:9
pub const __counted_by = @compileError("unable to translate C expr: unexpected token ''");
// /nix/store/1ycjq6h047qqwp3fm9sbl805xnrxlh2h-glibc-2.40-66-dev/include/linux/stddef.h:55:9
pub const __counted_by_le = @compileError("unable to translate C expr: unexpected token ''");
// /nix/store/1ycjq6h047qqwp3fm9sbl805xnrxlh2h-glibc-2.40-66-dev/include/linux/stddef.h:59:9
pub const __counted_by_be = @compileError("unable to translate C expr: unexpected token ''");
// /nix/store/1ycjq6h047qqwp3fm9sbl805xnrxlh2h-glibc-2.40-66-dev/include/linux/stddef.h:63:9
pub const __FD_SETSIZE = @as(c_int, 1024);
pub const _ASM_X86_POSIX_TYPES_64_H = "";
pub const __ASM_GENERIC_POSIX_TYPES_H = "";
pub const __bitwise = "";
pub const __bitwise__ = "";
pub const __aligned_u64 = @compileError("unable to translate macro: undefined identifier `aligned`");
// /nix/store/1ycjq6h047qqwp3fm9sbl805xnrxlh2h-glibc-2.40-66-dev/include/linux/types.h:50:9
pub const __aligned_be64 = @compileError("unable to translate macro: undefined identifier `aligned`");
// /nix/store/1ycjq6h047qqwp3fm9sbl805xnrxlh2h-glibc-2.40-66-dev/include/linux/types.h:51:9
pub const __aligned_le64 = @compileError("unable to translate macro: undefined identifier `aligned`");
// /nix/store/1ycjq6h047qqwp3fm9sbl805xnrxlh2h-glibc-2.40-66-dev/include/linux/types.h:52:9
pub const _ASM_GENERIC_IOCTL_H = "";
pub const _IOC_NRBITS = @as(c_int, 8);
pub const _IOC_TYPEBITS = @as(c_int, 8);
pub const _IOC_SIZEBITS = @as(c_int, 14);
pub const _IOC_DIRBITS = @as(c_int, 2);
pub const _IOC_NRMASK = (@as(c_int, 1) << _IOC_NRBITS) - @as(c_int, 1);
pub const _IOC_TYPEMASK = (@as(c_int, 1) << _IOC_TYPEBITS) - @as(c_int, 1);
pub const _IOC_SIZEMASK = (@as(c_int, 1) << _IOC_SIZEBITS) - @as(c_int, 1);
pub const _IOC_DIRMASK = (@as(c_int, 1) << _IOC_DIRBITS) - @as(c_int, 1);
pub const _IOC_NRSHIFT = @as(c_int, 0);
pub const _IOC_TYPESHIFT = _IOC_NRSHIFT + _IOC_NRBITS;
pub const _IOC_SIZESHIFT = _IOC_TYPESHIFT + _IOC_TYPEBITS;
pub const _IOC_DIRSHIFT = _IOC_SIZESHIFT + _IOC_SIZEBITS;
pub const _IOC_NONE = @as(c_uint, 0);
pub const _IOC_WRITE = @as(c_uint, 1);
pub const _IOC_READ = @as(c_uint, 2);
pub inline fn _IOC(dir: anytype, @"type": anytype, nr: anytype, size: anytype) @TypeOf((((dir << _IOC_DIRSHIFT) | (@"type" << _IOC_TYPESHIFT)) | (nr << _IOC_NRSHIFT)) | (size << _IOC_SIZESHIFT)) {
    _ = &dir;
    _ = &@"type";
    _ = &nr;
    _ = &size;
    return (((dir << _IOC_DIRSHIFT) | (@"type" << _IOC_TYPESHIFT)) | (nr << _IOC_NRSHIFT)) | (size << _IOC_SIZESHIFT);
}
pub inline fn _IOC_TYPECHECK(t: anytype) @TypeOf(@import("std").zig.c_translation.sizeof(t)) {
    _ = &t;
    return @import("std").zig.c_translation.sizeof(t);
}
pub inline fn _IO(@"type": anytype, nr: anytype) @TypeOf(_IOC(_IOC_NONE, @"type", nr, @as(c_int, 0))) {
    _ = &@"type";
    _ = &nr;
    return _IOC(_IOC_NONE, @"type", nr, @as(c_int, 0));
}
pub inline fn _IOR(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_READ, @"type", nr, _IOC_TYPECHECK(size))) {
    _ = &@"type";
    _ = &nr;
    _ = &size;
    return _IOC(_IOC_READ, @"type", nr, _IOC_TYPECHECK(size));
}
pub inline fn _IOW(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_WRITE, @"type", nr, _IOC_TYPECHECK(size))) {
    _ = &@"type";
    _ = &nr;
    _ = &size;
    return _IOC(_IOC_WRITE, @"type", nr, _IOC_TYPECHECK(size));
}
pub inline fn _IOWR(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_READ | _IOC_WRITE, @"type", nr, _IOC_TYPECHECK(size))) {
    _ = &@"type";
    _ = &nr;
    _ = &size;
    return _IOC(_IOC_READ | _IOC_WRITE, @"type", nr, _IOC_TYPECHECK(size));
}
pub inline fn _IOR_BAD(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_READ, @"type", nr, @import("std").zig.c_translation.sizeof(size))) {
    _ = &@"type";
    _ = &nr;
    _ = &size;
    return _IOC(_IOC_READ, @"type", nr, @import("std").zig.c_translation.sizeof(size));
}
pub inline fn _IOW_BAD(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_WRITE, @"type", nr, @import("std").zig.c_translation.sizeof(size))) {
    _ = &@"type";
    _ = &nr;
    _ = &size;
    return _IOC(_IOC_WRITE, @"type", nr, @import("std").zig.c_translation.sizeof(size));
}
pub inline fn _IOWR_BAD(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_READ | _IOC_WRITE, @"type", nr, @import("std").zig.c_translation.sizeof(size))) {
    _ = &@"type";
    _ = &nr;
    _ = &size;
    return _IOC(_IOC_READ | _IOC_WRITE, @"type", nr, @import("std").zig.c_translation.sizeof(size));
}
pub inline fn _IOC_DIR(nr: anytype) @TypeOf((nr >> _IOC_DIRSHIFT) & _IOC_DIRMASK) {
    _ = &nr;
    return (nr >> _IOC_DIRSHIFT) & _IOC_DIRMASK;
}
pub inline fn _IOC_TYPE(nr: anytype) @TypeOf((nr >> _IOC_TYPESHIFT) & _IOC_TYPEMASK) {
    _ = &nr;
    return (nr >> _IOC_TYPESHIFT) & _IOC_TYPEMASK;
}
pub inline fn _IOC_NR(nr: anytype) @TypeOf((nr >> _IOC_NRSHIFT) & _IOC_NRMASK) {
    _ = &nr;
    return (nr >> _IOC_NRSHIFT) & _IOC_NRMASK;
}
pub inline fn _IOC_SIZE(nr: anytype) @TypeOf((nr >> _IOC_SIZESHIFT) & _IOC_SIZEMASK) {
    _ = &nr;
    return (nr >> _IOC_SIZESHIFT) & _IOC_SIZEMASK;
}
pub const IOC_IN = _IOC_WRITE << _IOC_DIRSHIFT;
pub const IOC_OUT = _IOC_READ << _IOC_DIRSHIFT;
pub const IOC_INOUT = (_IOC_WRITE | _IOC_READ) << _IOC_DIRSHIFT;
pub const IOCSIZE_MASK = _IOC_SIZEMASK << _IOC_SIZESHIFT;
pub const IOCSIZE_SHIFT = _IOC_SIZESHIFT;
pub const DRM_NAME = "drm";
pub const DRM_MIN_ORDER = @as(c_int, 5);
pub const DRM_MAX_ORDER = @as(c_int, 22);
pub const DRM_RAM_PERCENT = @as(c_int, 10);
pub const _DRM_LOCK_HELD = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0x80000000, .hex);
pub const _DRM_LOCK_CONT = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0x40000000, .hex);
pub inline fn _DRM_LOCK_IS_HELD(lock: anytype) @TypeOf(lock & _DRM_LOCK_HELD) {
    _ = &lock;
    return lock & _DRM_LOCK_HELD;
}
pub inline fn _DRM_LOCK_IS_CONT(lock: anytype) @TypeOf(lock & _DRM_LOCK_CONT) {
    _ = &lock;
    return lock & _DRM_LOCK_CONT;
}
pub inline fn _DRM_LOCKING_CONTEXT(lock: anytype) @TypeOf(lock & ~(_DRM_LOCK_HELD | _DRM_LOCK_CONT)) {
    _ = &lock;
    return lock & ~(_DRM_LOCK_HELD | _DRM_LOCK_CONT);
}
pub const _DRM_VBLANK_HIGH_CRTC_SHIFT = @as(c_int, 1);
pub const _DRM_VBLANK_TYPES_MASK = _DRM_VBLANK_ABSOLUTE | _DRM_VBLANK_RELATIVE;
pub const _DRM_VBLANK_FLAGS_MASK = ((_DRM_VBLANK_EVENT | _DRM_VBLANK_SIGNAL) | _DRM_VBLANK_SECONDARY) | _DRM_VBLANK_NEXTONMISS;
pub const _DRM_PRE_MODESET = @as(c_int, 1);
pub const _DRM_POST_MODESET = @as(c_int, 2);
pub const DRM_CAP_DUMB_BUFFER = @as(c_int, 0x1);
pub const DRM_CAP_VBLANK_HIGH_CRTC = @as(c_int, 0x2);
pub const DRM_CAP_DUMB_PREFERRED_DEPTH = @as(c_int, 0x3);
pub const DRM_CAP_DUMB_PREFER_SHADOW = @as(c_int, 0x4);
pub const DRM_CAP_PRIME = @as(c_int, 0x5);
pub const DRM_PRIME_CAP_IMPORT = @as(c_int, 0x1);
pub const DRM_PRIME_CAP_EXPORT = @as(c_int, 0x2);
pub const DRM_CAP_TIMESTAMP_MONOTONIC = @as(c_int, 0x6);
pub const DRM_CAP_ASYNC_PAGE_FLIP = @as(c_int, 0x7);
pub const DRM_CAP_CURSOR_WIDTH = @as(c_int, 0x8);
pub const DRM_CAP_CURSOR_HEIGHT = @as(c_int, 0x9);
pub const DRM_CAP_ADDFB2_MODIFIERS = @as(c_int, 0x10);
pub const DRM_CAP_PAGE_FLIP_TARGET = @as(c_int, 0x11);
pub const DRM_CAP_CRTC_IN_VBLANK_EVENT = @as(c_int, 0x12);
pub const DRM_CAP_SYNCOBJ = @as(c_int, 0x13);
pub const DRM_CAP_SYNCOBJ_TIMELINE = @as(c_int, 0x14);
pub const DRM_CAP_ATOMIC_ASYNC_PAGE_FLIP = @as(c_int, 0x15);
pub const DRM_CLIENT_CAP_STEREO_3D = @as(c_int, 1);
pub const DRM_CLIENT_CAP_UNIVERSAL_PLANES = @as(c_int, 2);
pub const DRM_CLIENT_CAP_ATOMIC = @as(c_int, 3);
pub const DRM_CLIENT_CAP_ASPECT_RATIO = @as(c_int, 4);
pub const DRM_CLIENT_CAP_WRITEBACK_CONNECTORS = @as(c_int, 5);
pub const DRM_CLIENT_CAP_CURSOR_PLANE_HOTSPOT = @as(c_int, 6);
pub const DRM_RDWR = @compileError("unable to translate macro: undefined identifier `O_RDWR`");
// ./drm.h:878:9
pub const DRM_CLOEXEC = @compileError("unable to translate macro: undefined identifier `O_CLOEXEC`");
// ./drm.h:879:9
pub const DRM_SYNCOBJ_CREATE_SIGNALED = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_SYNCOBJ_FD_TO_HANDLE_FLAGS_IMPORT_SYNC_FILE = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_SYNCOBJ_HANDLE_TO_FD_FLAGS_EXPORT_SYNC_FILE = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_SYNCOBJ_WAIT_FLAGS_WAIT_ALL = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_SYNCOBJ_WAIT_FLAGS_WAIT_FOR_SUBMIT = @as(c_int, 1) << @as(c_int, 1);
pub const DRM_SYNCOBJ_WAIT_FLAGS_WAIT_AVAILABLE = @as(c_int, 1) << @as(c_int, 2);
pub const DRM_SYNCOBJ_WAIT_FLAGS_WAIT_DEADLINE = @as(c_int, 1) << @as(c_int, 3);
pub const DRM_SYNCOBJ_QUERY_FLAGS_LAST_SUBMITTED = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_CRTC_SEQUENCE_RELATIVE = @as(c_int, 0x00000001);
pub const DRM_CRTC_SEQUENCE_NEXT_ON_MISS = @as(c_int, 0x00000002);
pub const _DRM_MODE_H = "";
pub const DRM_CONNECTOR_NAME_LEN = @as(c_int, 32);
pub const DRM_DISPLAY_MODE_LEN = @as(c_int, 32);
pub const DRM_PROP_NAME_LEN = @as(c_int, 32);
pub const DRM_MODE_TYPE_BUILTIN = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_MODE_TYPE_CLOCK_C = (@as(c_int, 1) << @as(c_int, 1)) | DRM_MODE_TYPE_BUILTIN;
pub const DRM_MODE_TYPE_CRTC_C = (@as(c_int, 1) << @as(c_int, 2)) | DRM_MODE_TYPE_BUILTIN;
pub const DRM_MODE_TYPE_PREFERRED = @as(c_int, 1) << @as(c_int, 3);
pub const DRM_MODE_TYPE_DEFAULT = @as(c_int, 1) << @as(c_int, 4);
pub const DRM_MODE_TYPE_USERDEF = @as(c_int, 1) << @as(c_int, 5);
pub const DRM_MODE_TYPE_DRIVER = @as(c_int, 1) << @as(c_int, 6);
pub const DRM_MODE_TYPE_ALL = (DRM_MODE_TYPE_PREFERRED | DRM_MODE_TYPE_USERDEF) | DRM_MODE_TYPE_DRIVER;
pub const DRM_MODE_FLAG_PHSYNC = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_MODE_FLAG_NHSYNC = @as(c_int, 1) << @as(c_int, 1);
pub const DRM_MODE_FLAG_PVSYNC = @as(c_int, 1) << @as(c_int, 2);
pub const DRM_MODE_FLAG_NVSYNC = @as(c_int, 1) << @as(c_int, 3);
pub const DRM_MODE_FLAG_INTERLACE = @as(c_int, 1) << @as(c_int, 4);
pub const DRM_MODE_FLAG_DBLSCAN = @as(c_int, 1) << @as(c_int, 5);
pub const DRM_MODE_FLAG_CSYNC = @as(c_int, 1) << @as(c_int, 6);
pub const DRM_MODE_FLAG_PCSYNC = @as(c_int, 1) << @as(c_int, 7);
pub const DRM_MODE_FLAG_NCSYNC = @as(c_int, 1) << @as(c_int, 8);
pub const DRM_MODE_FLAG_HSKEW = @as(c_int, 1) << @as(c_int, 9);
pub const DRM_MODE_FLAG_BCAST = @as(c_int, 1) << @as(c_int, 10);
pub const DRM_MODE_FLAG_PIXMUX = @as(c_int, 1) << @as(c_int, 11);
pub const DRM_MODE_FLAG_DBLCLK = @as(c_int, 1) << @as(c_int, 12);
pub const DRM_MODE_FLAG_CLKDIV2 = @as(c_int, 1) << @as(c_int, 13);
pub const DRM_MODE_FLAG_3D_MASK = @as(c_int, 0x1f) << @as(c_int, 14);
pub const DRM_MODE_FLAG_3D_NONE = @as(c_int, 0) << @as(c_int, 14);
pub const DRM_MODE_FLAG_3D_FRAME_PACKING = @as(c_int, 1) << @as(c_int, 14);
pub const DRM_MODE_FLAG_3D_FIELD_ALTERNATIVE = @as(c_int, 2) << @as(c_int, 14);
pub const DRM_MODE_FLAG_3D_LINE_ALTERNATIVE = @as(c_int, 3) << @as(c_int, 14);
pub const DRM_MODE_FLAG_3D_SIDE_BY_SIDE_FULL = @as(c_int, 4) << @as(c_int, 14);
pub const DRM_MODE_FLAG_3D_L_DEPTH = @as(c_int, 5) << @as(c_int, 14);
pub const DRM_MODE_FLAG_3D_L_DEPTH_GFX_GFX_DEPTH = @as(c_int, 6) << @as(c_int, 14);
pub const DRM_MODE_FLAG_3D_TOP_AND_BOTTOM = @as(c_int, 7) << @as(c_int, 14);
pub const DRM_MODE_FLAG_3D_SIDE_BY_SIDE_HALF = @as(c_int, 8) << @as(c_int, 14);
pub const DRM_MODE_PICTURE_ASPECT_NONE = @as(c_int, 0);
pub const DRM_MODE_PICTURE_ASPECT_4_3 = @as(c_int, 1);
pub const DRM_MODE_PICTURE_ASPECT_16_9 = @as(c_int, 2);
pub const DRM_MODE_PICTURE_ASPECT_64_27 = @as(c_int, 3);
pub const DRM_MODE_PICTURE_ASPECT_256_135 = @as(c_int, 4);
pub const DRM_MODE_CONTENT_TYPE_NO_DATA = @as(c_int, 0);
pub const DRM_MODE_CONTENT_TYPE_GRAPHICS = @as(c_int, 1);
pub const DRM_MODE_CONTENT_TYPE_PHOTO = @as(c_int, 2);
pub const DRM_MODE_CONTENT_TYPE_CINEMA = @as(c_int, 3);
pub const DRM_MODE_CONTENT_TYPE_GAME = @as(c_int, 4);
pub const DRM_MODE_FLAG_PIC_AR_MASK = @as(c_int, 0x0F) << @as(c_int, 19);
pub const DRM_MODE_FLAG_PIC_AR_NONE = DRM_MODE_PICTURE_ASPECT_NONE << @as(c_int, 19);
pub const DRM_MODE_FLAG_PIC_AR_4_3 = DRM_MODE_PICTURE_ASPECT_4_3 << @as(c_int, 19);
pub const DRM_MODE_FLAG_PIC_AR_16_9 = DRM_MODE_PICTURE_ASPECT_16_9 << @as(c_int, 19);
pub const DRM_MODE_FLAG_PIC_AR_64_27 = DRM_MODE_PICTURE_ASPECT_64_27 << @as(c_int, 19);
pub const DRM_MODE_FLAG_PIC_AR_256_135 = DRM_MODE_PICTURE_ASPECT_256_135 << @as(c_int, 19);
pub const DRM_MODE_FLAG_ALL = (((((((((((DRM_MODE_FLAG_PHSYNC | DRM_MODE_FLAG_NHSYNC) | DRM_MODE_FLAG_PVSYNC) | DRM_MODE_FLAG_NVSYNC) | DRM_MODE_FLAG_INTERLACE) | DRM_MODE_FLAG_DBLSCAN) | DRM_MODE_FLAG_CSYNC) | DRM_MODE_FLAG_PCSYNC) | DRM_MODE_FLAG_NCSYNC) | DRM_MODE_FLAG_HSKEW) | DRM_MODE_FLAG_DBLCLK) | DRM_MODE_FLAG_CLKDIV2) | DRM_MODE_FLAG_3D_MASK;
pub const DRM_MODE_DPMS_ON = @as(c_int, 0);
pub const DRM_MODE_DPMS_STANDBY = @as(c_int, 1);
pub const DRM_MODE_DPMS_SUSPEND = @as(c_int, 2);
pub const DRM_MODE_DPMS_OFF = @as(c_int, 3);
pub const DRM_MODE_SCALE_NONE = @as(c_int, 0);
pub const DRM_MODE_SCALE_FULLSCREEN = @as(c_int, 1);
pub const DRM_MODE_SCALE_CENTER = @as(c_int, 2);
pub const DRM_MODE_SCALE_ASPECT = @as(c_int, 3);
pub const DRM_MODE_DITHERING_OFF = @as(c_int, 0);
pub const DRM_MODE_DITHERING_ON = @as(c_int, 1);
pub const DRM_MODE_DITHERING_AUTO = @as(c_int, 2);
pub const DRM_MODE_DIRTY_OFF = @as(c_int, 0);
pub const DRM_MODE_DIRTY_ON = @as(c_int, 1);
pub const DRM_MODE_DIRTY_ANNOTATE = @as(c_int, 2);
pub const DRM_MODE_LINK_STATUS_GOOD = @as(c_int, 0);
pub const DRM_MODE_LINK_STATUS_BAD = @as(c_int, 1);
pub const DRM_MODE_ROTATE_0 = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_MODE_ROTATE_90 = @as(c_int, 1) << @as(c_int, 1);
pub const DRM_MODE_ROTATE_180 = @as(c_int, 1) << @as(c_int, 2);
pub const DRM_MODE_ROTATE_270 = @as(c_int, 1) << @as(c_int, 3);
pub const DRM_MODE_ROTATE_MASK = ((DRM_MODE_ROTATE_0 | DRM_MODE_ROTATE_90) | DRM_MODE_ROTATE_180) | DRM_MODE_ROTATE_270;
pub const DRM_MODE_REFLECT_X = @as(c_int, 1) << @as(c_int, 4);
pub const DRM_MODE_REFLECT_Y = @as(c_int, 1) << @as(c_int, 5);
pub const DRM_MODE_REFLECT_MASK = DRM_MODE_REFLECT_X | DRM_MODE_REFLECT_Y;
pub const DRM_MODE_CONTENT_PROTECTION_UNDESIRED = @as(c_int, 0);
pub const DRM_MODE_CONTENT_PROTECTION_DESIRED = @as(c_int, 1);
pub const DRM_MODE_CONTENT_PROTECTION_ENABLED = @as(c_int, 2);
pub const DRM_MODE_PRESENT_TOP_FIELD = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_MODE_PRESENT_BOTTOM_FIELD = @as(c_int, 1) << @as(c_int, 1);
pub const DRM_MODE_ENCODER_NONE = @as(c_int, 0);
pub const DRM_MODE_ENCODER_DAC = @as(c_int, 1);
pub const DRM_MODE_ENCODER_TMDS = @as(c_int, 2);
pub const DRM_MODE_ENCODER_LVDS = @as(c_int, 3);
pub const DRM_MODE_ENCODER_TVDAC = @as(c_int, 4);
pub const DRM_MODE_ENCODER_VIRTUAL = @as(c_int, 5);
pub const DRM_MODE_ENCODER_DSI = @as(c_int, 6);
pub const DRM_MODE_ENCODER_DPMST = @as(c_int, 7);
pub const DRM_MODE_ENCODER_DPI = @as(c_int, 8);
pub const DRM_MODE_CONNECTOR_Unknown = @as(c_int, 0);
pub const DRM_MODE_CONNECTOR_VGA = @as(c_int, 1);
pub const DRM_MODE_CONNECTOR_DVII = @as(c_int, 2);
pub const DRM_MODE_CONNECTOR_DVID = @as(c_int, 3);
pub const DRM_MODE_CONNECTOR_DVIA = @as(c_int, 4);
pub const DRM_MODE_CONNECTOR_Composite = @as(c_int, 5);
pub const DRM_MODE_CONNECTOR_SVIDEO = @as(c_int, 6);
pub const DRM_MODE_CONNECTOR_LVDS = @as(c_int, 7);
pub const DRM_MODE_CONNECTOR_Component = @as(c_int, 8);
pub const DRM_MODE_CONNECTOR_9PinDIN = @as(c_int, 9);
pub const DRM_MODE_CONNECTOR_DisplayPort = @as(c_int, 10);
pub const DRM_MODE_CONNECTOR_HDMIA = @as(c_int, 11);
pub const DRM_MODE_CONNECTOR_HDMIB = @as(c_int, 12);
pub const DRM_MODE_CONNECTOR_TV = @as(c_int, 13);
pub const DRM_MODE_CONNECTOR_eDP = @as(c_int, 14);
pub const DRM_MODE_CONNECTOR_VIRTUAL = @as(c_int, 15);
pub const DRM_MODE_CONNECTOR_DSI = @as(c_int, 16);
pub const DRM_MODE_CONNECTOR_DPI = @as(c_int, 17);
pub const DRM_MODE_CONNECTOR_WRITEBACK = @as(c_int, 18);
pub const DRM_MODE_CONNECTOR_SPI = @as(c_int, 19);
pub const DRM_MODE_CONNECTOR_USB = @as(c_int, 20);
pub const DRM_MODE_PROP_PENDING = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_MODE_PROP_RANGE = @as(c_int, 1) << @as(c_int, 1);
pub const DRM_MODE_PROP_IMMUTABLE = @as(c_int, 1) << @as(c_int, 2);
pub const DRM_MODE_PROP_ENUM = @as(c_int, 1) << @as(c_int, 3);
pub const DRM_MODE_PROP_BLOB = @as(c_int, 1) << @as(c_int, 4);
pub const DRM_MODE_PROP_BITMASK = @as(c_int, 1) << @as(c_int, 5);
pub const DRM_MODE_PROP_LEGACY_TYPE = ((DRM_MODE_PROP_RANGE | DRM_MODE_PROP_ENUM) | DRM_MODE_PROP_BLOB) | DRM_MODE_PROP_BITMASK;
pub const DRM_MODE_PROP_EXTENDED_TYPE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x0000ffc0, .hex);
pub inline fn DRM_MODE_PROP_TYPE(n: anytype) @TypeOf(n << @as(c_int, 6)) {
    _ = &n;
    return n << @as(c_int, 6);
}
pub const DRM_MODE_PROP_OBJECT = DRM_MODE_PROP_TYPE(@as(c_int, 1));
pub const DRM_MODE_PROP_SIGNED_RANGE = DRM_MODE_PROP_TYPE(@as(c_int, 2));
pub const DRM_MODE_PROP_ATOMIC = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x80000000, .hex);
pub const DRM_MODE_OBJECT_CRTC = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xcccccccc, .hex);
pub const DRM_MODE_OBJECT_CONNECTOR = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xc0c0c0c0, .hex);
pub const DRM_MODE_OBJECT_ENCODER = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xe0e0e0e0, .hex);
pub const DRM_MODE_OBJECT_MODE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xdededede, .hex);
pub const DRM_MODE_OBJECT_PROPERTY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xb0b0b0b0, .hex);
pub const DRM_MODE_OBJECT_FB = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xfbfbfbfb, .hex);
pub const DRM_MODE_OBJECT_BLOB = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xbbbbbbbb, .hex);
pub const DRM_MODE_OBJECT_PLANE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xeeeeeeee, .hex);
pub const DRM_MODE_OBJECT_ANY = @as(c_int, 0);
pub const DRM_MODE_FB_INTERLACED = @as(c_int, 1) << @as(c_int, 0);
pub const DRM_MODE_FB_MODIFIERS = @as(c_int, 1) << @as(c_int, 1);
pub const DRM_MODE_FB_DIRTY_ANNOTATE_COPY = @as(c_int, 0x01);
pub const DRM_MODE_FB_DIRTY_ANNOTATE_FILL = @as(c_int, 0x02);
pub const DRM_MODE_FB_DIRTY_FLAGS = @as(c_int, 0x03);
pub const DRM_MODE_FB_DIRTY_MAX_CLIPS = @as(c_int, 256);
pub const DRM_MODE_CURSOR_BO = @as(c_int, 0x01);
pub const DRM_MODE_CURSOR_MOVE = @as(c_int, 0x02);
pub const DRM_MODE_CURSOR_FLAGS = @as(c_int, 0x03);
pub const DRM_MODE_PAGE_FLIP_EVENT = @as(c_int, 0x01);
pub const DRM_MODE_PAGE_FLIP_ASYNC = @as(c_int, 0x02);
pub const DRM_MODE_PAGE_FLIP_TARGET_ABSOLUTE = @as(c_int, 0x4);
pub const DRM_MODE_PAGE_FLIP_TARGET_RELATIVE = @as(c_int, 0x8);
pub const DRM_MODE_PAGE_FLIP_TARGET = DRM_MODE_PAGE_FLIP_TARGET_ABSOLUTE | DRM_MODE_PAGE_FLIP_TARGET_RELATIVE;
pub const DRM_MODE_PAGE_FLIP_FLAGS = (DRM_MODE_PAGE_FLIP_EVENT | DRM_MODE_PAGE_FLIP_ASYNC) | DRM_MODE_PAGE_FLIP_TARGET;
pub const DRM_MODE_ATOMIC_TEST_ONLY = @as(c_int, 0x0100);
pub const DRM_MODE_ATOMIC_NONBLOCK = @as(c_int, 0x0200);
pub const DRM_MODE_ATOMIC_ALLOW_MODESET = @as(c_int, 0x0400);
pub const DRM_MODE_ATOMIC_FLAGS = (((DRM_MODE_PAGE_FLIP_EVENT | DRM_MODE_PAGE_FLIP_ASYNC) | DRM_MODE_ATOMIC_TEST_ONLY) | DRM_MODE_ATOMIC_NONBLOCK) | DRM_MODE_ATOMIC_ALLOW_MODESET;
pub const FORMAT_BLOB_CURRENT = @as(c_int, 1);
pub const DRM_IOCTL_BASE = 'd';
pub inline fn DRM_IO(nr: anytype) @TypeOf(_IO(DRM_IOCTL_BASE, nr)) {
    _ = &nr;
    return _IO(DRM_IOCTL_BASE, nr);
}
pub inline fn DRM_IOR(nr: anytype, @"type": anytype) @TypeOf(_IOR(DRM_IOCTL_BASE, nr, @"type")) {
    _ = &nr;
    _ = &@"type";
    return _IOR(DRM_IOCTL_BASE, nr, @"type");
}
pub inline fn DRM_IOW(nr: anytype, @"type": anytype) @TypeOf(_IOW(DRM_IOCTL_BASE, nr, @"type")) {
    _ = &nr;
    _ = &@"type";
    return _IOW(DRM_IOCTL_BASE, nr, @"type");
}
pub inline fn DRM_IOWR(nr: anytype, @"type": anytype) @TypeOf(_IOWR(DRM_IOCTL_BASE, nr, @"type")) {
    _ = &nr;
    _ = &@"type";
    return _IOWR(DRM_IOCTL_BASE, nr, @"type");
}
pub const DRM_IOCTL_VERSION = DRM_IOWR(@as(c_int, 0x00), struct_drm_version);
pub const DRM_IOCTL_GET_UNIQUE = DRM_IOWR(@as(c_int, 0x01), struct_drm_unique);
pub const DRM_IOCTL_GET_MAGIC = DRM_IOR(@as(c_int, 0x02), struct_drm_auth);
pub const DRM_IOCTL_IRQ_BUSID = DRM_IOWR(@as(c_int, 0x03), struct_drm_irq_busid);
pub const DRM_IOCTL_GET_MAP = DRM_IOWR(@as(c_int, 0x04), struct_drm_map);
pub const DRM_IOCTL_GET_CLIENT = DRM_IOWR(@as(c_int, 0x05), struct_drm_client);
pub const DRM_IOCTL_GET_STATS = DRM_IOR(@as(c_int, 0x06), struct_drm_stats);
pub const DRM_IOCTL_SET_VERSION = DRM_IOWR(@as(c_int, 0x07), struct_drm_set_version);
pub const DRM_IOCTL_MODESET_CTL = DRM_IOW(@as(c_int, 0x08), struct_drm_modeset_ctl);
pub const DRM_IOCTL_GEM_CLOSE = DRM_IOW(@as(c_int, 0x09), struct_drm_gem_close);
pub const DRM_IOCTL_GEM_FLINK = DRM_IOWR(@as(c_int, 0x0a), struct_drm_gem_flink);
pub const DRM_IOCTL_GEM_OPEN = DRM_IOWR(@as(c_int, 0x0b), struct_drm_gem_open);
pub const DRM_IOCTL_GET_CAP = DRM_IOWR(@as(c_int, 0x0c), struct_drm_get_cap);
pub const DRM_IOCTL_SET_CLIENT_CAP = DRM_IOW(@as(c_int, 0x0d), struct_drm_set_client_cap);
pub const DRM_IOCTL_SET_UNIQUE = DRM_IOW(@as(c_int, 0x10), struct_drm_unique);
pub const DRM_IOCTL_AUTH_MAGIC = DRM_IOW(@as(c_int, 0x11), struct_drm_auth);
pub const DRM_IOCTL_BLOCK = DRM_IOWR(@as(c_int, 0x12), struct_drm_block);
pub const DRM_IOCTL_UNBLOCK = DRM_IOWR(@as(c_int, 0x13), struct_drm_block);
pub const DRM_IOCTL_CONTROL = DRM_IOW(@as(c_int, 0x14), struct_drm_control);
pub const DRM_IOCTL_ADD_MAP = DRM_IOWR(@as(c_int, 0x15), struct_drm_map);
pub const DRM_IOCTL_ADD_BUFS = DRM_IOWR(@as(c_int, 0x16), struct_drm_buf_desc);
pub const DRM_IOCTL_MARK_BUFS = DRM_IOW(@as(c_int, 0x17), struct_drm_buf_desc);
pub const DRM_IOCTL_INFO_BUFS = DRM_IOWR(@as(c_int, 0x18), struct_drm_buf_info);
pub const DRM_IOCTL_MAP_BUFS = DRM_IOWR(@as(c_int, 0x19), struct_drm_buf_map);
pub const DRM_IOCTL_FREE_BUFS = DRM_IOW(@as(c_int, 0x1a), struct_drm_buf_free);
pub const DRM_IOCTL_RM_MAP = DRM_IOW(@as(c_int, 0x1b), struct_drm_map);
pub const DRM_IOCTL_SET_SAREA_CTX = DRM_IOW(@as(c_int, 0x1c), struct_drm_ctx_priv_map);
pub const DRM_IOCTL_GET_SAREA_CTX = DRM_IOWR(@as(c_int, 0x1d), struct_drm_ctx_priv_map);
pub const DRM_IOCTL_SET_MASTER = DRM_IO(@as(c_int, 0x1e));
pub const DRM_IOCTL_DROP_MASTER = DRM_IO(@as(c_int, 0x1f));
pub const DRM_IOCTL_ADD_CTX = DRM_IOWR(@as(c_int, 0x20), struct_drm_ctx);
pub const DRM_IOCTL_RM_CTX = DRM_IOWR(@as(c_int, 0x21), struct_drm_ctx);
pub const DRM_IOCTL_MOD_CTX = DRM_IOW(@as(c_int, 0x22), struct_drm_ctx);
pub const DRM_IOCTL_GET_CTX = DRM_IOWR(@as(c_int, 0x23), struct_drm_ctx);
pub const DRM_IOCTL_SWITCH_CTX = DRM_IOW(@as(c_int, 0x24), struct_drm_ctx);
pub const DRM_IOCTL_NEW_CTX = DRM_IOW(@as(c_int, 0x25), struct_drm_ctx);
pub const DRM_IOCTL_RES_CTX = DRM_IOWR(@as(c_int, 0x26), struct_drm_ctx_res);
pub const DRM_IOCTL_ADD_DRAW = DRM_IOWR(@as(c_int, 0x27), struct_drm_draw);
pub const DRM_IOCTL_RM_DRAW = DRM_IOWR(@as(c_int, 0x28), struct_drm_draw);
pub const DRM_IOCTL_DMA = DRM_IOWR(@as(c_int, 0x29), struct_drm_dma);
pub const DRM_IOCTL_LOCK = DRM_IOW(@as(c_int, 0x2a), struct_drm_lock);
pub const DRM_IOCTL_UNLOCK = DRM_IOW(@as(c_int, 0x2b), struct_drm_lock);
pub const DRM_IOCTL_FINISH = DRM_IOW(@as(c_int, 0x2c), struct_drm_lock);
pub const DRM_IOCTL_PRIME_HANDLE_TO_FD = DRM_IOWR(@as(c_int, 0x2d), struct_drm_prime_handle);
pub const DRM_IOCTL_PRIME_FD_TO_HANDLE = DRM_IOWR(@as(c_int, 0x2e), struct_drm_prime_handle);
pub const DRM_IOCTL_AGP_ACQUIRE = DRM_IO(@as(c_int, 0x30));
pub const DRM_IOCTL_AGP_RELEASE = DRM_IO(@as(c_int, 0x31));
pub const DRM_IOCTL_AGP_ENABLE = DRM_IOW(@as(c_int, 0x32), struct_drm_agp_mode);
pub const DRM_IOCTL_AGP_INFO = DRM_IOR(@as(c_int, 0x33), struct_drm_agp_info);
pub const DRM_IOCTL_AGP_ALLOC = DRM_IOWR(@as(c_int, 0x34), struct_drm_agp_buffer);
pub const DRM_IOCTL_AGP_FREE = DRM_IOW(@as(c_int, 0x35), struct_drm_agp_buffer);
pub const DRM_IOCTL_AGP_BIND = DRM_IOW(@as(c_int, 0x36), struct_drm_agp_binding);
pub const DRM_IOCTL_AGP_UNBIND = DRM_IOW(@as(c_int, 0x37), struct_drm_agp_binding);
pub const DRM_IOCTL_SG_ALLOC = DRM_IOWR(@as(c_int, 0x38), struct_drm_scatter_gather);
pub const DRM_IOCTL_SG_FREE = DRM_IOW(@as(c_int, 0x39), struct_drm_scatter_gather);
pub const DRM_IOCTL_WAIT_VBLANK = DRM_IOWR(@as(c_int, 0x3a), union_drm_wait_vblank);
pub const DRM_IOCTL_CRTC_GET_SEQUENCE = DRM_IOWR(@as(c_int, 0x3b), struct_drm_crtc_get_sequence);
pub const DRM_IOCTL_CRTC_QUEUE_SEQUENCE = DRM_IOWR(@as(c_int, 0x3c), struct_drm_crtc_queue_sequence);
pub const DRM_IOCTL_UPDATE_DRAW = DRM_IOW(@as(c_int, 0x3f), struct_drm_update_draw);
pub const DRM_IOCTL_MODE_GETRESOURCES = DRM_IOWR(@as(c_int, 0xA0), struct_drm_mode_card_res);
pub const DRM_IOCTL_MODE_GETCRTC = DRM_IOWR(@as(c_int, 0xA1), struct_drm_mode_crtc);
pub const DRM_IOCTL_MODE_SETCRTC = DRM_IOWR(@as(c_int, 0xA2), struct_drm_mode_crtc);
pub const DRM_IOCTL_MODE_CURSOR = DRM_IOWR(@as(c_int, 0xA3), struct_drm_mode_cursor);
pub const DRM_IOCTL_MODE_GETGAMMA = DRM_IOWR(@as(c_int, 0xA4), struct_drm_mode_crtc_lut);
pub const DRM_IOCTL_MODE_SETGAMMA = DRM_IOWR(@as(c_int, 0xA5), struct_drm_mode_crtc_lut);
pub const DRM_IOCTL_MODE_GETENCODER = DRM_IOWR(@as(c_int, 0xA6), struct_drm_mode_get_encoder);
pub const DRM_IOCTL_MODE_GETCONNECTOR = DRM_IOWR(@as(c_int, 0xA7), struct_drm_mode_get_connector);
pub const DRM_IOCTL_MODE_ATTACHMODE = DRM_IOWR(@as(c_int, 0xA8), struct_drm_mode_mode_cmd);
pub const DRM_IOCTL_MODE_DETACHMODE = DRM_IOWR(@as(c_int, 0xA9), struct_drm_mode_mode_cmd);
pub const DRM_IOCTL_MODE_GETPROPERTY = DRM_IOWR(@as(c_int, 0xAA), struct_drm_mode_get_property);
pub const DRM_IOCTL_MODE_SETPROPERTY = DRM_IOWR(@as(c_int, 0xAB), struct_drm_mode_connector_set_property);
pub const DRM_IOCTL_MODE_GETPROPBLOB = DRM_IOWR(@as(c_int, 0xAC), struct_drm_mode_get_blob);
pub const DRM_IOCTL_MODE_GETFB = DRM_IOWR(@as(c_int, 0xAD), struct_drm_mode_fb_cmd);
pub const DRM_IOCTL_MODE_ADDFB = DRM_IOWR(@as(c_int, 0xAE), struct_drm_mode_fb_cmd);
pub const DRM_IOCTL_MODE_RMFB = DRM_IOWR(@as(c_int, 0xAF), c_uint);
pub const DRM_IOCTL_MODE_PAGE_FLIP = DRM_IOWR(@as(c_int, 0xB0), struct_drm_mode_crtc_page_flip);
pub const DRM_IOCTL_MODE_DIRTYFB = DRM_IOWR(@as(c_int, 0xB1), struct_drm_mode_fb_dirty_cmd);
pub const DRM_IOCTL_MODE_CREATE_DUMB = DRM_IOWR(@as(c_int, 0xB2), struct_drm_mode_create_dumb);
pub const DRM_IOCTL_MODE_MAP_DUMB = DRM_IOWR(@as(c_int, 0xB3), struct_drm_mode_map_dumb);
pub const DRM_IOCTL_MODE_DESTROY_DUMB = DRM_IOWR(@as(c_int, 0xB4), struct_drm_mode_destroy_dumb);
pub const DRM_IOCTL_MODE_GETPLANERESOURCES = DRM_IOWR(@as(c_int, 0xB5), struct_drm_mode_get_plane_res);
pub const DRM_IOCTL_MODE_GETPLANE = DRM_IOWR(@as(c_int, 0xB6), struct_drm_mode_get_plane);
pub const DRM_IOCTL_MODE_SETPLANE = DRM_IOWR(@as(c_int, 0xB7), struct_drm_mode_set_plane);
pub const DRM_IOCTL_MODE_ADDFB2 = DRM_IOWR(@as(c_int, 0xB8), struct_drm_mode_fb_cmd2);
pub const DRM_IOCTL_MODE_OBJ_GETPROPERTIES = DRM_IOWR(@as(c_int, 0xB9), struct_drm_mode_obj_get_properties);
pub const DRM_IOCTL_MODE_OBJ_SETPROPERTY = DRM_IOWR(@as(c_int, 0xBA), struct_drm_mode_obj_set_property);
pub const DRM_IOCTL_MODE_CURSOR2 = DRM_IOWR(@as(c_int, 0xBB), struct_drm_mode_cursor2);
pub const DRM_IOCTL_MODE_ATOMIC = DRM_IOWR(@as(c_int, 0xBC), struct_drm_mode_atomic);
pub const DRM_IOCTL_MODE_CREATEPROPBLOB = DRM_IOWR(@as(c_int, 0xBD), struct_drm_mode_create_blob);
pub const DRM_IOCTL_MODE_DESTROYPROPBLOB = DRM_IOWR(@as(c_int, 0xBE), struct_drm_mode_destroy_blob);
pub const DRM_IOCTL_SYNCOBJ_CREATE = DRM_IOWR(@as(c_int, 0xBF), struct_drm_syncobj_create);
pub const DRM_IOCTL_SYNCOBJ_DESTROY = DRM_IOWR(@as(c_int, 0xC0), struct_drm_syncobj_destroy);
pub const DRM_IOCTL_SYNCOBJ_HANDLE_TO_FD = DRM_IOWR(@as(c_int, 0xC1), struct_drm_syncobj_handle);
pub const DRM_IOCTL_SYNCOBJ_FD_TO_HANDLE = DRM_IOWR(@as(c_int, 0xC2), struct_drm_syncobj_handle);
pub const DRM_IOCTL_SYNCOBJ_WAIT = DRM_IOWR(@as(c_int, 0xC3), struct_drm_syncobj_wait);
pub const DRM_IOCTL_SYNCOBJ_RESET = DRM_IOWR(@as(c_int, 0xC4), struct_drm_syncobj_array);
pub const DRM_IOCTL_SYNCOBJ_SIGNAL = DRM_IOWR(@as(c_int, 0xC5), struct_drm_syncobj_array);
pub const DRM_IOCTL_MODE_CREATE_LEASE = DRM_IOWR(@as(c_int, 0xC6), struct_drm_mode_create_lease);
pub const DRM_IOCTL_MODE_LIST_LESSEES = DRM_IOWR(@as(c_int, 0xC7), struct_drm_mode_list_lessees);
pub const DRM_IOCTL_MODE_GET_LEASE = DRM_IOWR(@as(c_int, 0xC8), struct_drm_mode_get_lease);
pub const DRM_IOCTL_MODE_REVOKE_LEASE = DRM_IOWR(@as(c_int, 0xC9), struct_drm_mode_revoke_lease);
pub const DRM_IOCTL_SYNCOBJ_TIMELINE_WAIT = DRM_IOWR(@as(c_int, 0xCA), struct_drm_syncobj_timeline_wait);
pub const DRM_IOCTL_SYNCOBJ_QUERY = DRM_IOWR(@as(c_int, 0xCB), struct_drm_syncobj_timeline_array);
pub const DRM_IOCTL_SYNCOBJ_TRANSFER = DRM_IOWR(@as(c_int, 0xCC), struct_drm_syncobj_transfer);
pub const DRM_IOCTL_SYNCOBJ_TIMELINE_SIGNAL = DRM_IOWR(@as(c_int, 0xCD), struct_drm_syncobj_timeline_array);
pub const DRM_IOCTL_MODE_GETFB2 = DRM_IOWR(@as(c_int, 0xCE), struct_drm_mode_fb_cmd2);
pub const DRM_IOCTL_SYNCOBJ_EVENTFD = DRM_IOWR(@as(c_int, 0xCF), struct_drm_syncobj_eventfd);
pub const DRM_IOCTL_MODE_CLOSEFB = DRM_IOWR(@as(c_int, 0xD0), struct_drm_mode_closefb);
pub const DRM_COMMAND_BASE = @as(c_int, 0x40);
pub const DRM_COMMAND_END = @as(c_int, 0xA0);
pub const DRM_EVENT_VBLANK = @as(c_int, 0x01);
pub const DRM_EVENT_FLIP_COMPLETE = @as(c_int, 0x02);
pub const DRM_EVENT_CRTC_SEQUENCE = @as(c_int, 0x03);
pub inline fn fourcc_code(a: anytype, b: anytype, c: anytype, d: anytype) @TypeOf(((@import("std").zig.c_translation.cast(__u32, a) | (@import("std").zig.c_translation.cast(__u32, b) << @as(c_int, 8))) | (@import("std").zig.c_translation.cast(__u32, c) << @as(c_int, 16))) | (@import("std").zig.c_translation.cast(__u32, d) << @as(c_int, 24))) {
    _ = &a;
    _ = &b;
    _ = &c;
    _ = &d;
    return ((@import("std").zig.c_translation.cast(__u32, a) | (@import("std").zig.c_translation.cast(__u32, b) << @as(c_int, 8))) | (@import("std").zig.c_translation.cast(__u32, c) << @as(c_int, 16))) | (@import("std").zig.c_translation.cast(__u32, d) << @as(c_int, 24));
}
pub const DRM_FORMAT_BIG_ENDIAN = @as(c_uint, 1) << @as(c_int, 31);
pub const DRM_FORMAT_INVALID = @as(c_int, 0);
pub const DRM_FORMAT_C1 = fourcc_code('C', '1', ' ', ' ');
pub const DRM_FORMAT_C2 = fourcc_code('C', '2', ' ', ' ');
pub const DRM_FORMAT_C4 = fourcc_code('C', '4', ' ', ' ');
pub const DRM_FORMAT_C8 = fourcc_code('C', '8', ' ', ' ');
pub const DRM_FORMAT_D1 = fourcc_code('D', '1', ' ', ' ');
pub const DRM_FORMAT_D2 = fourcc_code('D', '2', ' ', ' ');
pub const DRM_FORMAT_D4 = fourcc_code('D', '4', ' ', ' ');
pub const DRM_FORMAT_D8 = fourcc_code('D', '8', ' ', ' ');
pub const DRM_FORMAT_R1 = fourcc_code('R', '1', ' ', ' ');
pub const DRM_FORMAT_R2 = fourcc_code('R', '2', ' ', ' ');
pub const DRM_FORMAT_R4 = fourcc_code('R', '4', ' ', ' ');
pub const DRM_FORMAT_R8 = fourcc_code('R', '8', ' ', ' ');
pub const DRM_FORMAT_R10 = fourcc_code('R', '1', '0', ' ');
pub const DRM_FORMAT_R12 = fourcc_code('R', '1', '2', ' ');
pub const DRM_FORMAT_R16 = fourcc_code('R', '1', '6', ' ');
pub const DRM_FORMAT_RG88 = fourcc_code('R', 'G', '8', '8');
pub const DRM_FORMAT_GR88 = fourcc_code('G', 'R', '8', '8');
pub const DRM_FORMAT_RG1616 = fourcc_code('R', 'G', '3', '2');
pub const DRM_FORMAT_GR1616 = fourcc_code('G', 'R', '3', '2');
pub const DRM_FORMAT_RGB332 = fourcc_code('R', 'G', 'B', '8');
pub const DRM_FORMAT_BGR233 = fourcc_code('B', 'G', 'R', '8');
pub const DRM_FORMAT_XRGB4444 = fourcc_code('X', 'R', '1', '2');
pub const DRM_FORMAT_XBGR4444 = fourcc_code('X', 'B', '1', '2');
pub const DRM_FORMAT_RGBX4444 = fourcc_code('R', 'X', '1', '2');
pub const DRM_FORMAT_BGRX4444 = fourcc_code('B', 'X', '1', '2');
pub const DRM_FORMAT_ARGB4444 = fourcc_code('A', 'R', '1', '2');
pub const DRM_FORMAT_ABGR4444 = fourcc_code('A', 'B', '1', '2');
pub const DRM_FORMAT_RGBA4444 = fourcc_code('R', 'A', '1', '2');
pub const DRM_FORMAT_BGRA4444 = fourcc_code('B', 'A', '1', '2');
pub const DRM_FORMAT_XRGB1555 = fourcc_code('X', 'R', '1', '5');
pub const DRM_FORMAT_XBGR1555 = fourcc_code('X', 'B', '1', '5');
pub const DRM_FORMAT_RGBX5551 = fourcc_code('R', 'X', '1', '5');
pub const DRM_FORMAT_BGRX5551 = fourcc_code('B', 'X', '1', '5');
pub const DRM_FORMAT_ARGB1555 = fourcc_code('A', 'R', '1', '5');
pub const DRM_FORMAT_ABGR1555 = fourcc_code('A', 'B', '1', '5');
pub const DRM_FORMAT_RGBA5551 = fourcc_code('R', 'A', '1', '5');
pub const DRM_FORMAT_BGRA5551 = fourcc_code('B', 'A', '1', '5');
pub const DRM_FORMAT_RGB565 = fourcc_code('R', 'G', '1', '6');
pub const DRM_FORMAT_BGR565 = fourcc_code('B', 'G', '1', '6');
pub const DRM_FORMAT_RGB888 = fourcc_code('R', 'G', '2', '4');
pub const DRM_FORMAT_BGR888 = fourcc_code('B', 'G', '2', '4');
pub const DRM_FORMAT_XRGB8888 = fourcc_code('X', 'R', '2', '4');
pub const DRM_FORMAT_XBGR8888 = fourcc_code('X', 'B', '2', '4');
pub const DRM_FORMAT_RGBX8888 = fourcc_code('R', 'X', '2', '4');
pub const DRM_FORMAT_BGRX8888 = fourcc_code('B', 'X', '2', '4');
pub const DRM_FORMAT_ARGB8888 = fourcc_code('A', 'R', '2', '4');
pub const DRM_FORMAT_ABGR8888 = fourcc_code('A', 'B', '2', '4');
pub const DRM_FORMAT_RGBA8888 = fourcc_code('R', 'A', '2', '4');
pub const DRM_FORMAT_BGRA8888 = fourcc_code('B', 'A', '2', '4');
pub const DRM_FORMAT_XRGB2101010 = fourcc_code('X', 'R', '3', '0');
pub const DRM_FORMAT_XBGR2101010 = fourcc_code('X', 'B', '3', '0');
pub const DRM_FORMAT_RGBX1010102 = fourcc_code('R', 'X', '3', '0');
pub const DRM_FORMAT_BGRX1010102 = fourcc_code('B', 'X', '3', '0');
pub const DRM_FORMAT_ARGB2101010 = fourcc_code('A', 'R', '3', '0');
pub const DRM_FORMAT_ABGR2101010 = fourcc_code('A', 'B', '3', '0');
pub const DRM_FORMAT_RGBA1010102 = fourcc_code('R', 'A', '3', '0');
pub const DRM_FORMAT_BGRA1010102 = fourcc_code('B', 'A', '3', '0');
pub const DRM_FORMAT_XRGB16161616 = fourcc_code('X', 'R', '4', '8');
pub const DRM_FORMAT_XBGR16161616 = fourcc_code('X', 'B', '4', '8');
pub const DRM_FORMAT_ARGB16161616 = fourcc_code('A', 'R', '4', '8');
pub const DRM_FORMAT_ABGR16161616 = fourcc_code('A', 'B', '4', '8');
pub const DRM_FORMAT_XRGB16161616F = fourcc_code('X', 'R', '4', 'H');
pub const DRM_FORMAT_XBGR16161616F = fourcc_code('X', 'B', '4', 'H');
pub const DRM_FORMAT_ARGB16161616F = fourcc_code('A', 'R', '4', 'H');
pub const DRM_FORMAT_ABGR16161616F = fourcc_code('A', 'B', '4', 'H');
pub const DRM_FORMAT_AXBXGXRX106106106106 = fourcc_code('A', 'B', '1', '0');
pub const DRM_FORMAT_YUYV = fourcc_code('Y', 'U', 'Y', 'V');
pub const DRM_FORMAT_YVYU = fourcc_code('Y', 'V', 'Y', 'U');
pub const DRM_FORMAT_UYVY = fourcc_code('U', 'Y', 'V', 'Y');
pub const DRM_FORMAT_VYUY = fourcc_code('V', 'Y', 'U', 'Y');
pub const DRM_FORMAT_AYUV = fourcc_code('A', 'Y', 'U', 'V');
pub const DRM_FORMAT_AVUY8888 = fourcc_code('A', 'V', 'U', 'Y');
pub const DRM_FORMAT_XYUV8888 = fourcc_code('X', 'Y', 'U', 'V');
pub const DRM_FORMAT_XVUY8888 = fourcc_code('X', 'V', 'U', 'Y');
pub const DRM_FORMAT_VUY888 = fourcc_code('V', 'U', '2', '4');
pub const DRM_FORMAT_VUY101010 = fourcc_code('V', 'U', '3', '0');
pub const DRM_FORMAT_Y210 = fourcc_code('Y', '2', '1', '0');
pub const DRM_FORMAT_Y212 = fourcc_code('Y', '2', '1', '2');
pub const DRM_FORMAT_Y216 = fourcc_code('Y', '2', '1', '6');
pub const DRM_FORMAT_Y410 = fourcc_code('Y', '4', '1', '0');
pub const DRM_FORMAT_Y412 = fourcc_code('Y', '4', '1', '2');
pub const DRM_FORMAT_Y416 = fourcc_code('Y', '4', '1', '6');
pub const DRM_FORMAT_XVYU2101010 = fourcc_code('X', 'V', '3', '0');
pub const DRM_FORMAT_XVYU12_16161616 = fourcc_code('X', 'V', '3', '6');
pub const DRM_FORMAT_XVYU16161616 = fourcc_code('X', 'V', '4', '8');
pub const DRM_FORMAT_Y0L0 = fourcc_code('Y', '0', 'L', '0');
pub const DRM_FORMAT_X0L0 = fourcc_code('X', '0', 'L', '0');
pub const DRM_FORMAT_Y0L2 = fourcc_code('Y', '0', 'L', '2');
pub const DRM_FORMAT_X0L2 = fourcc_code('X', '0', 'L', '2');
pub const DRM_FORMAT_YUV420_8BIT = fourcc_code('Y', 'U', '0', '8');
pub const DRM_FORMAT_YUV420_10BIT = fourcc_code('Y', 'U', '1', '0');
pub const DRM_FORMAT_XRGB8888_A8 = fourcc_code('X', 'R', 'A', '8');
pub const DRM_FORMAT_XBGR8888_A8 = fourcc_code('X', 'B', 'A', '8');
pub const DRM_FORMAT_RGBX8888_A8 = fourcc_code('R', 'X', 'A', '8');
pub const DRM_FORMAT_BGRX8888_A8 = fourcc_code('B', 'X', 'A', '8');
pub const DRM_FORMAT_RGB888_A8 = fourcc_code('R', '8', 'A', '8');
pub const DRM_FORMAT_BGR888_A8 = fourcc_code('B', '8', 'A', '8');
pub const DRM_FORMAT_RGB565_A8 = fourcc_code('R', '5', 'A', '8');
pub const DRM_FORMAT_BGR565_A8 = fourcc_code('B', '5', 'A', '8');
pub const DRM_FORMAT_NV12 = fourcc_code('N', 'V', '1', '2');
pub const DRM_FORMAT_NV21 = fourcc_code('N', 'V', '2', '1');
pub const DRM_FORMAT_NV16 = fourcc_code('N', 'V', '1', '6');
pub const DRM_FORMAT_NV61 = fourcc_code('N', 'V', '6', '1');
pub const DRM_FORMAT_NV24 = fourcc_code('N', 'V', '2', '4');
pub const DRM_FORMAT_NV42 = fourcc_code('N', 'V', '4', '2');
pub const DRM_FORMAT_NV15 = fourcc_code('N', 'V', '1', '5');
pub const DRM_FORMAT_NV20 = fourcc_code('N', 'V', '2', '0');
pub const DRM_FORMAT_NV30 = fourcc_code('N', 'V', '3', '0');
pub const DRM_FORMAT_P210 = fourcc_code('P', '2', '1', '0');
pub const DRM_FORMAT_P010 = fourcc_code('P', '0', '1', '0');
pub const DRM_FORMAT_P012 = fourcc_code('P', '0', '1', '2');
pub const DRM_FORMAT_P016 = fourcc_code('P', '0', '1', '6');
pub const DRM_FORMAT_P030 = fourcc_code('P', '0', '3', '0');
pub const DRM_FORMAT_Q410 = fourcc_code('Q', '4', '1', '0');
pub const DRM_FORMAT_Q401 = fourcc_code('Q', '4', '0', '1');
pub const DRM_FORMAT_YUV410 = fourcc_code('Y', 'U', 'V', '9');
pub const DRM_FORMAT_YVU410 = fourcc_code('Y', 'V', 'U', '9');
pub const DRM_FORMAT_YUV411 = fourcc_code('Y', 'U', '1', '1');
pub const DRM_FORMAT_YVU411 = fourcc_code('Y', 'V', '1', '1');
pub const DRM_FORMAT_YUV420 = fourcc_code('Y', 'U', '1', '2');
pub const DRM_FORMAT_YVU420 = fourcc_code('Y', 'V', '1', '2');
pub const DRM_FORMAT_YUV422 = fourcc_code('Y', 'U', '1', '6');
pub const DRM_FORMAT_YVU422 = fourcc_code('Y', 'V', '1', '6');
pub const DRM_FORMAT_YUV444 = fourcc_code('Y', 'U', '2', '4');
pub const DRM_FORMAT_YVU444 = fourcc_code('Y', 'V', '2', '4');
pub const DRM_FORMAT_MOD_VENDOR_NONE = @as(c_int, 0);
pub const DRM_FORMAT_MOD_VENDOR_INTEL = @as(c_int, 0x01);
pub const DRM_FORMAT_MOD_VENDOR_AMD = @as(c_int, 0x02);
pub const DRM_FORMAT_MOD_VENDOR_NVIDIA = @as(c_int, 0x03);
pub const DRM_FORMAT_MOD_VENDOR_SAMSUNG = @as(c_int, 0x04);
pub const DRM_FORMAT_MOD_VENDOR_QCOM = @as(c_int, 0x05);
pub const DRM_FORMAT_MOD_VENDOR_VIVANTE = @as(c_int, 0x06);
pub const DRM_FORMAT_MOD_VENDOR_BROADCOM = @as(c_int, 0x07);
pub const DRM_FORMAT_MOD_VENDOR_ARM = @as(c_int, 0x08);
pub const DRM_FORMAT_MOD_VENDOR_ALLWINNER = @as(c_int, 0x09);
pub const DRM_FORMAT_MOD_VENDOR_AMLOGIC = @as(c_int, 0x0a);
pub const DRM_FORMAT_RESERVED = (@as(c_ulonglong, 1) << @as(c_int, 56)) - @as(c_int, 1);
pub inline fn fourcc_mod_get_vendor(modifier: anytype) @TypeOf((modifier >> @as(c_int, 56)) & @as(c_int, 0xff)) {
    _ = &modifier;
    return (modifier >> @as(c_int, 56)) & @as(c_int, 0xff);
}
pub const fourcc_mod_is_vendor = @compileError("unable to translate macro: undefined identifier `DRM_FORMAT_MOD_VENDOR_`");
// ./drm_fourcc.h:432:9
pub const fourcc_mod_code = @compileError("unable to translate macro: undefined identifier `DRM_FORMAT_MOD_VENDOR_`");
// ./drm_fourcc.h:435:9
pub const DRM_FORMAT_MOD_GENERIC_16_16_TILE = DRM_FORMAT_MOD_SAMSUNG_16_16_TILE;
pub const DRM_FORMAT_MOD_INVALID = @compileError("unable to translate macro: undefined identifier `NONE`");
// ./drm_fourcc.h:478:9
pub const DRM_FORMAT_MOD_LINEAR = @compileError("unable to translate macro: undefined identifier `NONE`");
// ./drm_fourcc.h:488:9
pub const DRM_FORMAT_MOD_NONE = @as(c_int, 0);
pub const I915_FORMAT_MOD_X_TILED = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:517:9
pub const I915_FORMAT_MOD_Y_TILED = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:535:9
pub const I915_FORMAT_MOD_Yf_TILED = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:550:9
pub const I915_FORMAT_MOD_Y_TILED_CCS = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:569:9
pub const I915_FORMAT_MOD_Yf_TILED_CCS = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:570:9
pub const I915_FORMAT_MOD_Y_TILED_GEN12_RC_CCS = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:581:9
pub const I915_FORMAT_MOD_Y_TILED_GEN12_MC_CCS = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:594:9
pub const I915_FORMAT_MOD_Y_TILED_GEN12_RC_CCS_CC = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:613:9
pub const I915_FORMAT_MOD_4_TILED = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:624:9
pub const I915_FORMAT_MOD_4_TILED_DG2_RC_CCS = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:634:9
pub const I915_FORMAT_MOD_4_TILED_DG2_MC_CCS = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:646:9
pub const I915_FORMAT_MOD_4_TILED_DG2_RC_CCS_CC = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:660:9
pub const I915_FORMAT_MOD_4_TILED_MTL_RC_CCS = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:671:9
pub const I915_FORMAT_MOD_4_TILED_MTL_MC_CCS = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:684:9
pub const I915_FORMAT_MOD_4_TILED_MTL_RC_CCS_CC = @compileError("unable to translate macro: undefined identifier `INTEL`");
// ./drm_fourcc.h:703:9
pub const DRM_FORMAT_MOD_SAMSUNG_64_32_TILE = @compileError("unable to translate macro: undefined identifier `SAMSUNG`");
// ./drm_fourcc.h:718:9
pub const DRM_FORMAT_MOD_SAMSUNG_16_16_TILE = @compileError("unable to translate macro: undefined identifier `SAMSUNG`");
// ./drm_fourcc.h:727:9
pub const DRM_FORMAT_MOD_QCOM_COMPRESSED = @compileError("unable to translate macro: undefined identifier `QCOM`");
// ./drm_fourcc.h:740:9
pub const DRM_FORMAT_MOD_QCOM_TILED3 = @compileError("unable to translate macro: undefined identifier `QCOM`");
// ./drm_fourcc.h:753:9
pub const DRM_FORMAT_MOD_QCOM_TILED2 = @compileError("unable to translate macro: undefined identifier `QCOM`");
// ./drm_fourcc.h:761:9
pub const DRM_FORMAT_MOD_VIVANTE_TILED = @compileError("unable to translate macro: undefined identifier `VIVANTE`");
// ./drm_fourcc.h:772:9
pub const DRM_FORMAT_MOD_VIVANTE_SUPER_TILED = @compileError("unable to translate macro: undefined identifier `VIVANTE`");
// ./drm_fourcc.h:784:9
pub const DRM_FORMAT_MOD_VIVANTE_SPLIT_TILED = @compileError("unable to translate macro: undefined identifier `VIVANTE`");
// ./drm_fourcc.h:793:9
pub const DRM_FORMAT_MOD_VIVANTE_SPLIT_SUPER_TILED = @compileError("unable to translate macro: undefined identifier `VIVANTE`");
// ./drm_fourcc.h:802:9
pub const VIVANTE_MOD_TS_64_4 = @as(c_ulonglong, 1) << @as(c_int, 48);
pub const VIVANTE_MOD_TS_64_2 = @as(c_ulonglong, 2) << @as(c_int, 48);
pub const VIVANTE_MOD_TS_128_4 = @as(c_ulonglong, 3) << @as(c_int, 48);
pub const VIVANTE_MOD_TS_256_4 = @as(c_ulonglong, 4) << @as(c_int, 48);
pub const VIVANTE_MOD_TS_MASK = @as(c_ulonglong, 0xf) << @as(c_int, 48);
pub const VIVANTE_MOD_COMP_DEC400 = @as(c_ulonglong, 1) << @as(c_int, 52);
pub const VIVANTE_MOD_COMP_MASK = @as(c_ulonglong, 0xf) << @as(c_int, 52);
pub const VIVANTE_MOD_EXT_MASK = VIVANTE_MOD_TS_MASK | VIVANTE_MOD_COMP_MASK;
pub const DRM_FORMAT_MOD_NVIDIA_TEGRA_TILED = @compileError("unable to translate macro: undefined identifier `NVIDIA`");
// ./drm_fourcc.h:840:9
pub const DRM_FORMAT_MOD_NVIDIA_BLOCK_LINEAR_2D = @compileError("unable to translate macro: undefined identifier `NVIDIA`");
// ./drm_fourcc.h:925:9
pub inline fn DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(v: anytype) @TypeOf(DRM_FORMAT_MOD_NVIDIA_BLOCK_LINEAR_2D(@as(c_int, 0), @as(c_int, 0), @as(c_int, 0), @as(c_int, 0), v)) {
    _ = &v;
    return DRM_FORMAT_MOD_NVIDIA_BLOCK_LINEAR_2D(@as(c_int, 0), @as(c_int, 0), @as(c_int, 0), @as(c_int, 0), v);
}
pub const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_ONE_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(@as(c_int, 0));
pub const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_TWO_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(@as(c_int, 1));
pub const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_FOUR_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(@as(c_int, 2));
pub const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_EIGHT_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(@as(c_int, 3));
pub const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_SIXTEEN_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(@as(c_int, 4));
pub const DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK_THIRTYTWO_GOB = DRM_FORMAT_MOD_NVIDIA_16BX2_BLOCK(@as(c_int, 5));
pub const __fourcc_mod_broadcom_param_shift = @as(c_int, 8);
pub const __fourcc_mod_broadcom_param_bits = @as(c_int, 48);
pub const fourcc_mod_broadcom_code = @compileError("unable to translate macro: undefined identifier `BROADCOM`");
// ./drm_fourcc.h:993:9
pub inline fn fourcc_mod_broadcom_param(m: anytype) c_int {
    _ = &m;
    return @import("std").zig.c_translation.cast(c_int, (m >> __fourcc_mod_broadcom_param_shift) & ((@as(c_ulonglong, 1) << __fourcc_mod_broadcom_param_bits) - @as(c_int, 1)));
}
pub inline fn fourcc_mod_broadcom_mod(m: anytype) @TypeOf(m & ~(((@as(c_ulonglong, 1) << __fourcc_mod_broadcom_param_bits) - @as(c_int, 1)) << __fourcc_mod_broadcom_param_shift)) {
    _ = &m;
    return m & ~(((@as(c_ulonglong, 1) << __fourcc_mod_broadcom_param_bits) - @as(c_int, 1)) << __fourcc_mod_broadcom_param_shift);
}
pub const DRM_FORMAT_MOD_BROADCOM_VC4_T_TILED = @compileError("unable to translate macro: undefined identifier `BROADCOM`");
// ./drm_fourcc.h:1021:9
pub inline fn DRM_FORMAT_MOD_BROADCOM_SAND32_COL_HEIGHT(v: anytype) @TypeOf(fourcc_mod_broadcom_code(@as(c_int, 2), v)) {
    _ = &v;
    return fourcc_mod_broadcom_code(@as(c_int, 2), v);
}
pub inline fn DRM_FORMAT_MOD_BROADCOM_SAND64_COL_HEIGHT(v: anytype) @TypeOf(fourcc_mod_broadcom_code(@as(c_int, 3), v)) {
    _ = &v;
    return fourcc_mod_broadcom_code(@as(c_int, 3), v);
}
pub inline fn DRM_FORMAT_MOD_BROADCOM_SAND128_COL_HEIGHT(v: anytype) @TypeOf(fourcc_mod_broadcom_code(@as(c_int, 4), v)) {
    _ = &v;
    return fourcc_mod_broadcom_code(@as(c_int, 4), v);
}
pub inline fn DRM_FORMAT_MOD_BROADCOM_SAND256_COL_HEIGHT(v: anytype) @TypeOf(fourcc_mod_broadcom_code(@as(c_int, 5), v)) {
    _ = &v;
    return fourcc_mod_broadcom_code(@as(c_int, 5), v);
}
pub const DRM_FORMAT_MOD_BROADCOM_SAND32 = DRM_FORMAT_MOD_BROADCOM_SAND32_COL_HEIGHT(@as(c_int, 0));
pub const DRM_FORMAT_MOD_BROADCOM_SAND64 = DRM_FORMAT_MOD_BROADCOM_SAND64_COL_HEIGHT(@as(c_int, 0));
pub const DRM_FORMAT_MOD_BROADCOM_SAND128 = DRM_FORMAT_MOD_BROADCOM_SAND128_COL_HEIGHT(@as(c_int, 0));
pub const DRM_FORMAT_MOD_BROADCOM_SAND256 = DRM_FORMAT_MOD_BROADCOM_SAND256_COL_HEIGHT(@as(c_int, 0));
pub const DRM_FORMAT_MOD_BROADCOM_UIF = @compileError("unable to translate macro: undefined identifier `BROADCOM`");
// ./drm_fourcc.h:1088:9
pub const DRM_FORMAT_MOD_ARM_CODE = @compileError("unable to translate macro: undefined identifier `ARM`");
// ./drm_fourcc.h:1111:9
pub const DRM_FORMAT_MOD_ARM_TYPE_AFBC = @as(c_int, 0x00);
pub const DRM_FORMAT_MOD_ARM_TYPE_MISC = @as(c_int, 0x01);
pub inline fn DRM_FORMAT_MOD_ARM_AFBC(__afbc_mode: anytype) @TypeOf(DRM_FORMAT_MOD_ARM_CODE(DRM_FORMAT_MOD_ARM_TYPE_AFBC, __afbc_mode)) {
    _ = &__afbc_mode;
    return DRM_FORMAT_MOD_ARM_CODE(DRM_FORMAT_MOD_ARM_TYPE_AFBC, __afbc_mode);
}
pub const AFBC_FORMAT_MOD_BLOCK_SIZE_MASK = @as(c_int, 0xf);
pub const AFBC_FORMAT_MOD_BLOCK_SIZE_16x16 = @as(c_ulonglong, 1);
pub const AFBC_FORMAT_MOD_BLOCK_SIZE_32x8 = @as(c_ulonglong, 2);
pub const AFBC_FORMAT_MOD_BLOCK_SIZE_64x4 = @as(c_ulonglong, 3);
pub const AFBC_FORMAT_MOD_BLOCK_SIZE_32x8_64x4 = @as(c_ulonglong, 4);
pub const AFBC_FORMAT_MOD_YTR = @as(c_ulonglong, 1) << @as(c_int, 4);
pub const AFBC_FORMAT_MOD_SPLIT = @as(c_ulonglong, 1) << @as(c_int, 5);
pub const AFBC_FORMAT_MOD_SPARSE = @as(c_ulonglong, 1) << @as(c_int, 6);
pub const AFBC_FORMAT_MOD_CBR = @as(c_ulonglong, 1) << @as(c_int, 7);
pub const AFBC_FORMAT_MOD_TILED = @as(c_ulonglong, 1) << @as(c_int, 8);
pub const AFBC_FORMAT_MOD_SC = @as(c_ulonglong, 1) << @as(c_int, 9);
pub const AFBC_FORMAT_MOD_DB = @as(c_ulonglong, 1) << @as(c_int, 10);
pub const AFBC_FORMAT_MOD_BCH = @as(c_ulonglong, 1) << @as(c_int, 11);
pub const AFBC_FORMAT_MOD_USM = @as(c_ulonglong, 1) << @as(c_int, 12);
pub const DRM_FORMAT_MOD_ARM_TYPE_AFRC = @as(c_int, 0x02);
pub inline fn DRM_FORMAT_MOD_ARM_AFRC(__afrc_mode: anytype) @TypeOf(DRM_FORMAT_MOD_ARM_CODE(DRM_FORMAT_MOD_ARM_TYPE_AFRC, __afrc_mode)) {
    _ = &__afrc_mode;
    return DRM_FORMAT_MOD_ARM_CODE(DRM_FORMAT_MOD_ARM_TYPE_AFRC, __afrc_mode);
}
pub const AFRC_FORMAT_MOD_CU_SIZE_MASK = @as(c_int, 0xf);
pub const AFRC_FORMAT_MOD_CU_SIZE_16 = @as(c_ulonglong, 1);
pub const AFRC_FORMAT_MOD_CU_SIZE_24 = @as(c_ulonglong, 2);
pub const AFRC_FORMAT_MOD_CU_SIZE_32 = @as(c_ulonglong, 3);
pub inline fn AFRC_FORMAT_MOD_CU_SIZE_P0(__afrc_cu_size: anytype) @TypeOf(__afrc_cu_size) {
    _ = &__afrc_cu_size;
    return __afrc_cu_size;
}
pub inline fn AFRC_FORMAT_MOD_CU_SIZE_P12(__afrc_cu_size: anytype) @TypeOf(__afrc_cu_size << @as(c_int, 4)) {
    _ = &__afrc_cu_size;
    return __afrc_cu_size << @as(c_int, 4);
}
pub const AFRC_FORMAT_MOD_LAYOUT_SCAN = @as(c_ulonglong, 1) << @as(c_int, 8);
pub const DRM_FORMAT_MOD_ARM_16X16_BLOCK_U_INTERLEAVED = DRM_FORMAT_MOD_ARM_CODE(DRM_FORMAT_MOD_ARM_TYPE_MISC, @as(c_ulonglong, 1));
pub const DRM_FORMAT_MOD_ALLWINNER_TILED = @compileError("unable to translate macro: undefined identifier `ALLWINNER`");
// ./drm_fourcc.h:1349:9
pub const __fourcc_mod_amlogic_layout_mask = @as(c_int, 0xff);
pub const __fourcc_mod_amlogic_options_shift = @as(c_int, 8);
pub const __fourcc_mod_amlogic_options_mask = @as(c_int, 0xff);
pub const DRM_FORMAT_MOD_AMLOGIC_FBC = @compileError("unable to translate macro: undefined identifier `AMLOGIC`");
// ./drm_fourcc.h:1376:9
pub const AMLOGIC_FBC_LAYOUT_BASIC = @as(c_ulonglong, 1);
pub const AMLOGIC_FBC_LAYOUT_SCATTER = @as(c_ulonglong, 2);
pub const AMLOGIC_FBC_OPTION_MEM_SAVING = @as(c_ulonglong, 1) << @as(c_int, 0);
pub const AMD_FMT_MOD = @compileError("unable to translate macro: undefined identifier `AMD`");
// ./drm_fourcc.h:1470:9
pub inline fn IS_AMD_FMT_MOD(val: anytype) @TypeOf((val >> @as(c_int, 56)) == DRM_FORMAT_MOD_VENDOR_AMD) {
    _ = &val;
    return (val >> @as(c_int, 56)) == DRM_FORMAT_MOD_VENDOR_AMD;
}
pub const AMD_FMT_MOD_TILE_VER_GFX9 = @as(c_int, 1);
pub const AMD_FMT_MOD_TILE_VER_GFX10 = @as(c_int, 2);
pub const AMD_FMT_MOD_TILE_VER_GFX10_RBPLUS = @as(c_int, 3);
pub const AMD_FMT_MOD_TILE_VER_GFX11 = @as(c_int, 4);
pub const AMD_FMT_MOD_TILE_VER_GFX12 = @as(c_int, 5);
pub const AMD_FMT_MOD_TILE_GFX9_64K_S = @as(c_int, 9);
pub const AMD_FMT_MOD_TILE_GFX9_64K_D = @as(c_int, 10);
pub const AMD_FMT_MOD_TILE_GFX9_64K_S_X = @as(c_int, 25);
pub const AMD_FMT_MOD_TILE_GFX9_64K_D_X = @as(c_int, 26);
pub const AMD_FMT_MOD_TILE_GFX9_64K_R_X = @as(c_int, 27);
pub const AMD_FMT_MOD_TILE_GFX11_256K_R_X = @as(c_int, 31);
pub const AMD_FMT_MOD_TILE_GFX12_64K_2D = @as(c_int, 3);
pub const AMD_FMT_MOD_TILE_GFX12_256K_2D = @as(c_int, 4);
pub const AMD_FMT_MOD_DCC_BLOCK_64B = @as(c_int, 0);
pub const AMD_FMT_MOD_DCC_BLOCK_128B = @as(c_int, 1);
pub const AMD_FMT_MOD_DCC_BLOCK_256B = @as(c_int, 2);
pub const AMD_FMT_MOD_TILE_VERSION_SHIFT = @as(c_int, 0);
pub const AMD_FMT_MOD_TILE_VERSION_MASK = @as(c_int, 0xFF);
pub const AMD_FMT_MOD_TILE_SHIFT = @as(c_int, 8);
pub const AMD_FMT_MOD_TILE_MASK = @as(c_int, 0x1F);
pub const AMD_FMT_MOD_DCC_SHIFT = @as(c_int, 13);
pub const AMD_FMT_MOD_DCC_MASK = @as(c_int, 0x1);
pub const AMD_FMT_MOD_DCC_RETILE_SHIFT = @as(c_int, 14);
pub const AMD_FMT_MOD_DCC_RETILE_MASK = @as(c_int, 0x1);
pub const AMD_FMT_MOD_DCC_PIPE_ALIGN_SHIFT = @as(c_int, 15);
pub const AMD_FMT_MOD_DCC_PIPE_ALIGN_MASK = @as(c_int, 0x1);
pub const AMD_FMT_MOD_DCC_INDEPENDENT_64B_SHIFT = @as(c_int, 16);
pub const AMD_FMT_MOD_DCC_INDEPENDENT_64B_MASK = @as(c_int, 0x1);
pub const AMD_FMT_MOD_DCC_INDEPENDENT_128B_SHIFT = @as(c_int, 17);
pub const AMD_FMT_MOD_DCC_INDEPENDENT_128B_MASK = @as(c_int, 0x1);
pub const AMD_FMT_MOD_DCC_MAX_COMPRESSED_BLOCK_SHIFT = @as(c_int, 18);
pub const AMD_FMT_MOD_DCC_MAX_COMPRESSED_BLOCK_MASK = @as(c_int, 0x3);
pub const AMD_FMT_MOD_GFX12_DCC_MAX_COMPRESSED_BLOCK_SHIFT = @as(c_int, 3);
pub const AMD_FMT_MOD_GFX12_DCC_MAX_COMPRESSED_BLOCK_MASK = @as(c_int, 0x3);
pub const AMD_FMT_MOD_DCC_CONSTANT_ENCODE_SHIFT = @as(c_int, 20);
pub const AMD_FMT_MOD_DCC_CONSTANT_ENCODE_MASK = @as(c_int, 0x1);
pub const AMD_FMT_MOD_PIPE_XOR_BITS_SHIFT = @as(c_int, 21);
pub const AMD_FMT_MOD_PIPE_XOR_BITS_MASK = @as(c_int, 0x7);
pub const AMD_FMT_MOD_BANK_XOR_BITS_SHIFT = @as(c_int, 24);
pub const AMD_FMT_MOD_BANK_XOR_BITS_MASK = @as(c_int, 0x7);
pub const AMD_FMT_MOD_PACKERS_SHIFT = @as(c_int, 27);
pub const AMD_FMT_MOD_PACKERS_MASK = @as(c_int, 0x7);
pub const AMD_FMT_MOD_RB_SHIFT = @as(c_int, 30);
pub const AMD_FMT_MOD_RB_MASK = @as(c_int, 0x7);
pub const AMD_FMT_MOD_PIPE_SHIFT = @as(c_int, 33);
pub const AMD_FMT_MOD_PIPE_MASK = @as(c_int, 0x7);
pub const AMD_FMT_MOD_SET = @compileError("unable to translate macro: undefined identifier `AMD_FMT_MOD_`");
// ./drm_fourcc.h:1579:9
pub const AMD_FMT_MOD_GET = @compileError("unable to translate macro: undefined identifier `AMD_FMT_MOD_`");
// ./drm_fourcc.h:1581:9
pub const AMD_FMT_MOD_CLEAR = @compileError("unable to translate macro: undefined identifier `AMD_FMT_MOD_`");
// ./drm_fourcc.h:1583:9
pub const drm_clip_rect = struct_drm_clip_rect;
pub const drm_drawable_info = struct_drm_drawable_info;
pub const drm_tex_region = struct_drm_tex_region;
pub const drm_hw_lock = struct_drm_hw_lock;
pub const drm_version = struct_drm_version;
pub const drm_unique = struct_drm_unique;
pub const drm_list = struct_drm_list;
pub const drm_block = struct_drm_block;
pub const drm_control = struct_drm_control;
pub const drm_map_type = enum_drm_map_type;
pub const drm_map_flags = enum_drm_map_flags;
pub const drm_ctx_priv_map = struct_drm_ctx_priv_map;
pub const drm_map = struct_drm_map;
pub const drm_client = struct_drm_client;
pub const drm_stat_type = enum_drm_stat_type;
pub const drm_stats = struct_drm_stats;
pub const drm_lock_flags = enum_drm_lock_flags;
pub const drm_lock = struct_drm_lock;
pub const drm_dma_flags = enum_drm_dma_flags;
pub const drm_buf_desc = struct_drm_buf_desc;
pub const drm_buf_info = struct_drm_buf_info;
pub const drm_buf_free = struct_drm_buf_free;
pub const drm_buf_pub = struct_drm_buf_pub;
pub const drm_buf_map = struct_drm_buf_map;
pub const drm_dma = struct_drm_dma;
pub const drm_ctx_flags = enum_drm_ctx_flags;
pub const drm_ctx = struct_drm_ctx;
pub const drm_ctx_res = struct_drm_ctx_res;
pub const drm_draw = struct_drm_draw;
pub const drm_update_draw = struct_drm_update_draw;
pub const drm_auth = struct_drm_auth;
pub const drm_irq_busid = struct_drm_irq_busid;
pub const drm_vblank_seq_type = enum_drm_vblank_seq_type;
pub const drm_wait_vblank_request = struct_drm_wait_vblank_request;
pub const drm_wait_vblank_reply = struct_drm_wait_vblank_reply;
pub const drm_wait_vblank = union_drm_wait_vblank;
pub const drm_modeset_ctl = struct_drm_modeset_ctl;
pub const drm_agp_mode = struct_drm_agp_mode;
pub const drm_agp_buffer = struct_drm_agp_buffer;
pub const drm_agp_binding = struct_drm_agp_binding;
pub const drm_agp_info = struct_drm_agp_info;
pub const drm_scatter_gather = struct_drm_scatter_gather;
pub const drm_set_version = struct_drm_set_version;
pub const drm_gem_close = struct_drm_gem_close;
pub const drm_gem_flink = struct_drm_gem_flink;
pub const drm_gem_open = struct_drm_gem_open;
pub const drm_get_cap = struct_drm_get_cap;
pub const drm_set_client_cap = struct_drm_set_client_cap;
pub const drm_prime_handle = struct_drm_prime_handle;
pub const drm_syncobj_create = struct_drm_syncobj_create;
pub const drm_syncobj_destroy = struct_drm_syncobj_destroy;
pub const drm_syncobj_handle = struct_drm_syncobj_handle;
pub const drm_syncobj_transfer = struct_drm_syncobj_transfer;
pub const drm_syncobj_wait = struct_drm_syncobj_wait;
pub const drm_syncobj_timeline_wait = struct_drm_syncobj_timeline_wait;
pub const drm_syncobj_eventfd = struct_drm_syncobj_eventfd;
pub const drm_syncobj_array = struct_drm_syncobj_array;
pub const drm_syncobj_timeline_array = struct_drm_syncobj_timeline_array;
pub const drm_crtc_get_sequence = struct_drm_crtc_get_sequence;
pub const drm_crtc_queue_sequence = struct_drm_crtc_queue_sequence;
pub const drm_mode_modeinfo = struct_drm_mode_modeinfo;
pub const drm_mode_card_res = struct_drm_mode_card_res;
pub const drm_mode_crtc = struct_drm_mode_crtc;
pub const drm_mode_set_plane = struct_drm_mode_set_plane;
pub const drm_mode_get_plane = struct_drm_mode_get_plane;
pub const drm_mode_get_plane_res = struct_drm_mode_get_plane_res;
pub const drm_mode_get_encoder = struct_drm_mode_get_encoder;
pub const drm_mode_subconnector = enum_drm_mode_subconnector;
pub const drm_mode_get_connector = struct_drm_mode_get_connector;
pub const drm_mode_property_enum = struct_drm_mode_property_enum;
pub const drm_mode_get_property = struct_drm_mode_get_property;
pub const drm_mode_connector_set_property = struct_drm_mode_connector_set_property;
pub const drm_mode_obj_get_properties = struct_drm_mode_obj_get_properties;
pub const drm_mode_obj_set_property = struct_drm_mode_obj_set_property;
pub const drm_mode_get_blob = struct_drm_mode_get_blob;
pub const drm_mode_fb_cmd = struct_drm_mode_fb_cmd;
pub const drm_mode_fb_cmd2 = struct_drm_mode_fb_cmd2;
pub const drm_mode_fb_dirty_cmd = struct_drm_mode_fb_dirty_cmd;
pub const drm_mode_mode_cmd = struct_drm_mode_mode_cmd;
pub const drm_mode_cursor = struct_drm_mode_cursor;
pub const drm_mode_cursor2 = struct_drm_mode_cursor2;
pub const drm_mode_crtc_lut = struct_drm_mode_crtc_lut;
pub const drm_color_ctm = struct_drm_color_ctm;
pub const drm_color_lut = struct_drm_color_lut;
pub const drm_plane_size_hint = struct_drm_plane_size_hint;
pub const hdr_metadata_infoframe = struct_hdr_metadata_infoframe;
pub const hdr_output_metadata = struct_hdr_output_metadata;
pub const drm_mode_crtc_page_flip = struct_drm_mode_crtc_page_flip;
pub const drm_mode_crtc_page_flip_target = struct_drm_mode_crtc_page_flip_target;
pub const drm_mode_create_dumb = struct_drm_mode_create_dumb;
pub const drm_mode_map_dumb = struct_drm_mode_map_dumb;
pub const drm_mode_destroy_dumb = struct_drm_mode_destroy_dumb;
pub const drm_mode_atomic = struct_drm_mode_atomic;
pub const drm_format_modifier_blob = struct_drm_format_modifier_blob;
pub const drm_format_modifier = struct_drm_format_modifier;
pub const drm_mode_create_blob = struct_drm_mode_create_blob;
pub const drm_mode_destroy_blob = struct_drm_mode_destroy_blob;
pub const drm_mode_create_lease = struct_drm_mode_create_lease;
pub const drm_mode_list_lessees = struct_drm_mode_list_lessees;
pub const drm_mode_get_lease = struct_drm_mode_get_lease;
pub const drm_mode_revoke_lease = struct_drm_mode_revoke_lease;
pub const drm_mode_rect = struct_drm_mode_rect;
pub const drm_mode_closefb = struct_drm_mode_closefb;
pub const drm_event = struct_drm_event;
pub const drm_event_vblank = struct_drm_event_vblank;
pub const drm_event_crtc_sequence = struct_drm_event_crtc_sequence;
