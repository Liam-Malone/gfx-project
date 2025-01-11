# Wayland Client Reworking

## Intention

Make the interface of the wayland client easier to work with without requiring, but
still allowing, the user to manage their own registry for interfaces & global objects.

Main application code will no longer be overly concerned with wayland-specific management,
making it simpler to get back onto learning vulkan and focusing on graphics.

## Implementation Tasks

- [-] `interface.zig` map interface names to types and manage registry
- [ ] methods with `new_id` param:
    - [ ] param will be `?u32`
    - [ ] if no id provided (default), use `interface.registry.next_id()`
    - [ ] return value typeof = interface.type_map.get(`interface`) orelse compile error
- [ ] methods of type `destructor` :: call `interface.registry.remove(self.id)`
- [ ] `wl-client` module to present `window` interface and provide `system event` queue

