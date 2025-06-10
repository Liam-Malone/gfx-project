{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs = { self, nixpkgs, zig }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            lldb
            libinput
            man-pages
            mesa
            shaderc
            valgrind
            vkdisplayinfo
            vulkan-extension-layer
            vulkan-loader
            vulkan-tools
            vulkan-headers
            vulkan-validation-layers
            zig.packages.${system}.master-2025-06-09
          ];
        };
      });
    };
}
