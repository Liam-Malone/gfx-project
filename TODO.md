# Wayland Client Reworking

- [x] Output all generated code into a single `protocols.zig`
    - this should eliminate namespacing and inter-protocol type resolution issues
- [-] Move protocol interaction into `wl-client`, keep type map in `wl-interface.zig`
- [ ] Maybe move `wl-msg.zig` back into main module?
