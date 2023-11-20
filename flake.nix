{
  description = "nixpkgs with the unfree bits enabled";

  nixConfig.extra-substituters = [ "https://numtide.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" ];

  outputs = inputs@{ self, nixpkgs }:
    let
      # Support the same list of systems as upstream.
      systems = lib.systems.flakeExposed;

      lib = nixpkgs.lib;

      eachSystem = lib.genAttrs systems;
    in
    {
      # Inherit from upstream
      inherit (nixpkgs) lib nixosModules htmlDocs;

      # Expose our own unfree overrides
      overlays.default = import ./overlay.nix;

      # But replace legacyPackages with the unfree version
      legacyPackages = eachSystem (system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
            cudaSupport = true;
          };
          overlays = [ self.overlays.default ];
        }
      );

      templates = {
        devShell = {
          description = "devshell with nixpkgs-unfree";
          path = ./templates/dev-shell;
        };
        default = {
          description = "flake with nixpkgs-unfree";
          path = ./templates/default;
        };
      };

      devShells = eachSystem (system: {
        default = with self.legacyPackages.${system};
          mkShell {
            packages = [
              jq
              nix-eval-jobs
            ];
          };
      });

      # And load all the unfree+redistributable packages as checks
      checks = eachSystem (system: import ./checks.nix { nixpkgs = self.legacyPackages.${system}; });
    };
}
