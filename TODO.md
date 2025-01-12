# Wayland Client Reworking

- [x] Output all generated code into a single `protocols.zig`
    - this should eliminate namespacing and inter-protocol type resolution issues
- [x] Move protocol interaction into `wl-client` (99% done)
- [x] Clean up `main.zig`
- [ ] Fix compile errors
- [ ] Move `wl-msg.zig` back into main module?
- [ ] Revisit build script
- [ ] Keyboard & Mouse input
