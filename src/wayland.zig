pub const Display = struct {
    pub const OpCodes = enum(u16) {
        get_registry = 1,
    };
    pub const ObjectID: u32 = 1;
};

pub const Registry = struct {
    pub const OpCodes = enum(u16) {
        bind = 1,
    };
    pub const EventGlobal: u16 = 0;
    pub const GlobalRemove: u16 = 1;
};

pub const OpCodes = struct {
    pub const registry_bind: u16 = 0;
    pub const surface_commit: u16 = 0;
    pub const shm_create_pool: u16 = 0;
    pub const shm_pool_create_buffer: u16 = 0;

    pub const surface_attach: u16 = 1;
    pub const display_get_registry: u16 = 1;
    pub const compositor_create_surface: u16 = 1;

    pub const xdg_surface_get_toplevel: u16 = 1;
    pub const xdg_wm_base_get_xdg_surface: u16 = 2;
    pub const xdg_wm_base_pong: u16 = 3;
    pub const xdg_surface_ack_configure: u16 = 4;
};

pub const ObjectIDs = struct {
    pub const display: u32 = 1;
    pub const registry: u32 = 2;
};

// constants taken from: https://gaultier.github.io/blog/wayland_from_scratch.html

pub const wl_registry_bind_opcode: u16 = 0;
pub const wl_surface_commit_opcode: u16 = 6;
pub const wl_compositor_create_surface_opcode: u16 = 0;
pub const wl_shm_pool_create_buffer_opcode: u16 = 0;
pub const wl_shm_create_pool_opcode: u16 = 0;
pub const wl_display_get_registry_opcode: u16 = 1;
pub const wl_surface_attach_opcode: u16 = 1;

pub const wl_buffer_event_release: u16 = 0;
pub const wl_registry_event_global: u16 = 0;
pub const wl_display_error_event: u16 = 0;

pub const xdg_wm_base_pong_opcode: u16 = 3;
pub const xdg_surface_ack_configure_opcode: u16 = 4;
pub const xdg_wm_base_get_xdg_surface_opcode: u16 = 2;
pub const xdg_wm_base_event_ping: u16 = 0;
pub const xdg_toplevel_event_configure: u16 = 0;
pub const xdg_toplevel_event_close: u16 = 1;
pub const xdg_surface_event_configure: u16 = 0;
pub const xdg_surface_get_toplevel_opcode: u16 = 1;

pub const shm_pool_event_format: u16 = 0;
pub const display_object_id: u32 = 1;
pub const format_xrgb8888: u32 = 1;
pub const header_size: u32 = 8;

pub const color_channels: u32 = 4;
