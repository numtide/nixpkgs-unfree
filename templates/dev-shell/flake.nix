{
  description = "Development environment for this project";

  inputs = {
    nixpkgs.url = "github:numtide/nixpkgs-unfree";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      systems = lib.systems.flakeExposed;
      perSystem = { pkgs, ... }: {
        packages.default = pkgs.mkShell {
          packages = [
            pkgs.bashInteractive
          ];
        };
      };
    });
}
