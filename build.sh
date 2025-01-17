#!/usr/bin/env bash

build_flags=''

for arg in "$@"; do declare $arg='1'; done
if ! [ -v release ]; then declare debug='1'; fi

# condition checks
if ! [ -v EXE_NAME ]; then declare EXE_NAME='Gfx-Project'; fi
if ! [ -v ZIG ]; then # this is to alias compiler to v0.14.0-dev...
    if command -v zig &>/dev/null ; then 
        ZIG=zig
    else 
        echo "Error: no Zig compiler found"
        exit
    fi
fi

# half baked
root_dir=$PWD
bin_dir="$root_dir/build/bin"
tools_dir="$root_dir/build/tools"
shaders_dir="$root_dir/build/shaders"
mkdir -p $bin_dir
mkdir -p $tools_dir
mkdir -p $shaders_dir

if [ -v release ]; then
    echo "[Release Mode]"
    build_mode='ReleaseSafe'
else 
    echo "[Debug Mode]"
    build_mode='Debug'
fi

if [ -v nollvm ]; then build_flags="$build_flags -fno-llvm -fno-lld"; fi
if [ -v time ]; then build_flags="$build_flags -ftime-report"; fi

build_flags="$build_flags -O$build_mode"

cd build

# TODO: loop over desired protocols
if [ -v regen ]; then source $root_dir/scripts/codegen.sh && vk_gen && wl_gen ../protocols/wayland/*.xml ; fi; 
if ! [ -f $root_dir/src/generated/vk.zig ]; then vk_gen ; fi

shader_cmd="glslc --target-env=vulkan1.2 -o $root_dir/build/shaders"
vert_compile="$shader_cmd/vert.spv $root_dir/shaders/simp.vert"
frag_compile="$shader_cmd/frag.spv $root_dir/shaders/simp.frag"

compile="$ZIG build-exe $build_flags \
--dep vulkan \
-Mroot=$root_dir/src/main.zig $build_flags \
-Mvulkan=$root_dir/src/generated/vk.zig \
-lvulkan \
-lc \
--cache-dir $root_dir/.zig-cache \
--global-cache-dir $HOME/.cache/zig \
--name $EXE_NAME \
"

echo "[Compiling Shaders]"
$vert_compile &&
$frag_compile &&
echo "[Compiling Program]" &&
cd bin && $compile && if [ -v run ]; then cd $root_dir && $root_dir/build/bin/$EXE_NAME ; fi

if [ -f $bin_dir/$EXE_NAME.o ]; then rm $bin_dir/$EXE_NAME.o ; fi

cd $root
