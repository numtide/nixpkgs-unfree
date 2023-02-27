{
  description = "Development environment for this project";

  inputs = {
    nixpkgs.url = "github:numtide/nixpkgs-unfree";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  nixConfig.extra-substituters = [ "https://numtide.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" ];

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
