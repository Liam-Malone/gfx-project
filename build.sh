#!/usr/bin/env bash

build_flags=''

for arg in "$@"; do declare $arg='1'; done
if ! [ -v release ]; then declare debug='1'; fi

# condition checks
if ! [ -v EXE_NAME ]; then declare EXE_NAME='Zig-Gfx'; fi
if ! [ -v ZIG ]; then # this is to alias compiler to v0.14.0-dev...
    if command -v zig &>/dev/null ; then 
        ZIG=zig
    else 
        echo "Error: no Zig compiler found"
        exit
    fi
fi

# half baked
wl_protocols=(linux_dmabuf wayland xdg_decorations xdg_shell)
root_dir=$(pwd)
mkdir -p build/bin
mkdir -p build/tools
mkdir -p build/shaders

if [ -v release ]; then
    echo "[Release Mode]"
    build_mode='ReleaseSafe'
else 
    echo "[Debug Mode]"
    build_mode='Debug'
fi

if [ -v nollvm ]; then build_flags="$build_flags -fno-llvm"; fi

build_flags="$build_flags -O$build_mode"

cd build

# TODO: loop over desired protocols
if [ -v regen ]; then source $root_dir/scripts/codegen.sh && vk_gen && wl_gen ; fi; 
if ! [ -f $root_dir/src/generated/vk.zig ]; then vk_gen ; fi

shader_cmd="glslc --target-env=vulkan1.2 -o $root_dir/build/shaders"
vert_compile="$shader_cmd/vert.spv $root_dir/shaders/simp.vert"
frag_compile="$shader_cmd/frag.spv $root_dir/shaders/simp.frag"

compile="$ZIG build-exe $build_flags \
--dep wl_msg \
--dep wayland \
--dep xdg_shell \
--dep xdg_decoration \
--dep dmabuf \
--dep zigimg \
--dep vulkan \
--dep vertex_shader \
--dep fragment_shader \
-Mroot=$root_dir/src/main.zig $build_flags \
-Mwl_msg=$root_dir/src/wl_msg.zig $build_flags --dep wl_msg \
-Mwayland=$root_dir/src/generated/wayland.zig $build_flags --dep wl_msg \
-Mxdg_shell=$root_dir/src/generated/xdg_shell.zig $build_flags --dep wl_msg \
-Mxdg_decoration=$root_dir/src/generated/xdg_decorations.zig $build_flags --dep wl_msg \
-Mdmabuf=$root_dir/src/generated/linux_dmabuf.zig \
-Mzigimg=$root_dir/deps/zigimg/zigimg.zig \
-Mvulkan=$root_dir/src/generated/vk.zig \
-Mvertex_shader=$root_dir/build/shaders/vert.spv \
-Mfragment_shader=$root_dir/build/shaders/frag.spv \
-lc \
-lvulkan \
--cache-dir $root_dir/.zig-cache \
--global-cache-dir $HOME/.cache/zig \
--name $EXE_NAME \
"

echo "[Compiling Shaders]"
$vert_compile &&
$frag_compile &&
echo "[Compiling Program]" &&
cd bin && $compile && if [ -v run ]; then ./$EXE_NAME ; fi

if [ -f ./$EXE_NAME.o ]; then rm ./$EXE_NAME.o ; fi

cd $root

