{
  description = "Cal-ITP Data Infrastructure Dev Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          system = system;
          config.allowUnfree = true;
        };
        wrappedUv = pkgs.writeShellScriptBin "uv" ''
          export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
          exec ${pkgs.uv}/bin/uv "$@"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Shell integration caching tool
            nix-direnv

            # Core Python & Packaging
            python311
            wrappedUv
            # uv

            # Standalone Tools
            black
            pre-commit
            nixfmt

            # System / Ops Utilities
            google-cloud-sdk
            terraform
            gdal
            gh
            git
            gnumake
            rsync
            curl
            openssh
          ];
        };
      }
    );
}
