# Gfx Demo

So... after starting out writing a Wayland client with just libwayland in [C](https://github.com/Liam-Malone/wayland_gfx) and in [Zig](https://github.com/Liam-Malone/zig-wayland_gfx), I got curious and decided I'd like to try invoking calls through the wayland socket directly. With no libwaylandx I found [this guide](https://gaultier.github.io/blog/wayland_xrom_scratch.html) on writing a Wayland GUI client from scratch in C, and decided to try following along in Zig.

Once I am satisfied with my aims for this project, I may return to those previous client projects, or I may simply continue to expand this project


## Code Generation

In the process of attaining a basic window, I realized it would be much easier if I didn't have to manually write everything for every interface I want to use. With this goal in mind, I wrote [`wl_gen.zig`](./src/wl_gen.zig) to produce Zig code to use for interacting with the Wayland server, given a wayland xml specification document.


## Goals

- [x] Basic Window
- [x] Vulkan Context
- [ ] Shader Rendering
- [ ] Texture Rendering
- [ ] Input Event Handling
- [ ] 3D Graphics Rendering


#### Next Steps

- [ ] Vulkan Swapchain
- [ ] Window Resizing
- [ ] Wayland File Descriptor Receiving


### Potential Future Goals

- [ ] Abstract Windowing/Input Handling to Standalone Library
- [ ] Cross Platform Support (Mac/Windows)
- [ ] Game (/Engine) Based on This Project


### Milestones Hit:

- 01:00am - 04/12/2024: First Vulkan Rendered Window
![First screenshot of the GPU-rendered blank window](./assets/screenshots/first_vk-window.jpeg)
