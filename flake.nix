{
  description = "nixpkgs with the unfree bits enabled";

  outputs =
    inputs@{ self, nixpkgs }:
    let
      # Support the same list of systems as upstream.
      systems = lib.systems.flakeExposed;

      hydraSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      lib = nixpkgs.lib;

      eachSystem = lib.genAttrs systems;
    in
    {
      # Inherit from upstream
      inherit (nixpkgs) lib nixosModules htmlDocs;

      # But replace legacyPackages with the unfree version
      legacyPackages = eachSystem (
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
            cudaSupport = true;
          };
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
        default =
          with self.legacyPackages.${system};
          mkShell {
            packages = [
              jq
              nix-eval-jobs
            ];
          };
      });

      # And load all the unfree+redistributable packages as checks
      checks = eachSystem (system: import ./checks.nix { nixpkgs = self.legacyPackages.${system}; });

      hydraJobs = {
        # Re-expose the flake checks as hydra jobs.
        checks = lib.genAttrs hydraSystems (system: self.checks.${system});
      };
    };
}
