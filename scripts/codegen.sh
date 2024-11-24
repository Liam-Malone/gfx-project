#!/usr/bin/env bash

if ! [ -v ZIG ]; then echo "Error: Environment Variable 'ZIG' Not Set"; exit; fi
if ! [ -v root_dir ]; then echo "Warning: No 'root_dir' set, assuming $(pwd) as project root"; declare root_dir=$(pwd); fi

function vk_gen() {
    exe_name='vulkan-zig-generator'

    mkdir -p tools
    cd tools

    if [ -v build_vk_bindgen ] || ! [ -f ./$exe_name ]; then
        echo "[Building Vulkan Binding Generator]"
        compile_cmd="$ZIG build-exe $build_flags          \
            -Mroot=$root_dir/deps/vulkan-zig/src/main.zig \
            --cache-dir $root_dir/.zig-cache              \
            --global-cache-dir $HOME/.cache/zig           \
            --name $exe_name                              \
            "

        $compile_cmd
    fi
    
    echo "[Generating Vulkan Bindings]"
    ./$exe_name $root_dir/protocols/vulkan/vk.xml $root_dir/src/generated/vk.zig

    cd ..
}

# TODO: pass in pairs of spec + output_filename
function wl_gen() {
    exe_name='wl-zig-bindgen'

    mkdir -p tools
    cd tools

    if [ -v build_wl_bindgen ] || ! [ -f ./$exe_name ]; then
        echo "[Building Wayland Binding Generator]"
        compile_cmd="$ZIG build-exe $build_flags    \
            -Mroot=$root_dir/src/wl-zig-bindgen.zig \
            --cache-dir $root_dir/.zig-cache        \
            --global-cache-dir $HOME/.cache/zig     \
            --name $exe_name                        \
            "

        $compile_cmd
    fi

    echo "[Generating Wayland Bindings]"

    ./$exe_name $root_dir/protocols/wayland/wayland.xml $root_dir/src/generated/wayland.zig
    ./$exe_name $root_dir/protocols/wayland/xdg-shell.xml $root_dir/src/generated/xdg_shell.zig
    ./$exe_name $root_dir/protocols/wayland/xdg-decoration-unstable-v1.xml $root_dir/src/generated/xdg_decorations.zig
    ./$exe_name $root_dir/protocols/wayland/linux-dmabuf-v1.xml $root_dir/src/generated/linux_dmabuf.zig

    cd ..
}

if [ $0 == "./codegen.sh" ]; then
    echo "Running Codegen as Standalone Script"

    for arg in "$@"; do declare $arg='1'; done

    vk_gen
    wl_gen
fi

