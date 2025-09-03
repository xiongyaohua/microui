{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-flake = {
      url = "github:mitchellh/zig-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    zls-flake = {
      url = "github:zigtools/zls/0.15.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        zig-overlay.follows = "zig-flake";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      zig-flake,
      zls-flake,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        zig = zig-flake.packages.${system}.default;
        zls = zls-flake.packages.${system}.zls.overrideAttrs (old: {
          nativeBuildInputs = [ zig ];
          # version = "0.15.0";
          # checkPhase = '''';
          # doCheck = false;
        });
        # zls = zls-flake.packages.${system}.zls;
      in
      # with pkgs;
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            zig
            zls
            # pkgs.zig
            # pkgs.zls
            pkgs.lldb
            pkgs.pkg-config
          ];
          buildInputs = [
            pkgs.sdl2-compat
            # pkgs.raylib
            pkgs.libGL
          ];
        };
      }
    );
}
