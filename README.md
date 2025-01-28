# Graphics Project

This is a hobby project in which I am exploring everything related to creating, interactive, graphical (3D) programs to run on modern linux desktop systems.

This involves:

- Connecting to the host Wayland compositor
- Request creation of a window
- Processing & responding to system events
- Processing & responding to user inputs
- Rendering & presenting frames to the screen


To accomplish all this (without relying on external libraries), I needed to:

- Write my own tool to generate code based from a given list of wayland protocol specifications ([found here](./src/wl-bindgen.zig)).
- Write my own framework for communicating with the wayland compositor through the wayland wire protocol ([found here](./src/wl-msg.zig)).
- Write a tool for parsing xkb_v1 keyboard keymap formats ([found here](./src/xkb.zig)).
- Use Vulkan to create and write to the on-GPU buffers to render to the screen.


## Goals

- [x] Basic Window
- [x] Vulkan-Based Rendering
- [x] Input Event Handling
- [ ] Hello Triangle
- [ ] Texture/Image Rendering
- [ ] Text/Font Rendering
- [ ] Rendering 3D Objects & Scenes
- [ ] Lighting Simulation


#### Next Steps

- [-] System event queue
- [-] Hello Triangle
- [ ] (?) Switch from VkImage -> Vulkan Surface
- [ ] Vulkan Synchronization
- [ ] Vulkan Swapchain Creation Pipeline
- [ ] Image loading/rendering


### Potential Future Goals

- [ ] Cross Platform Support (Mac/Windows)
- [ ] Game (/Engine) Based on This Project


### Milestones Hit:

- 01:00am - 04/12/2024: First Vulkan Rendered Window
![First screenshot of the GPU-rendered blank window](./assets/screenshots/first_vk-window.jpeg)

- 01:00am - 08/12/2024: Fixed Coloring For a Proper Background Clearing
![GIF of screen-clearing working as intended](./assets/videos/clear-demo.gif)
