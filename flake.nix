{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    zls = {
      url = "github:zigtools/zls";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        zig-overlay.follows = "zig";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      zig,
      zls,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      with pkgs;
      {
        devShells.default = mkShell {
          nativeBuildInputs = [
            # zig.packages.${system}.master
            # zls.packages.${system}.default
            pkgs.zig
            pkgs.zls
          ];
          buildInputs = [
            sdl2-compat
            libGL
          ];
        };
      }
    );
}
