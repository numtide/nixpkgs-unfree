{
  description = "nixpkgs with the unfree bits enabled";

  nixConfig = {
    extra-substituters = [
      "https://cuda-maintainers.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];
  };

  outputs = inputs@{ self, nixpkgs }:
    let
      # OLD: Support the same list of systems as upstream.
      # systems = lib.systems.supported.hydra; 
      # NEW: Support only the platforms we have builders for
      # ...otherwise hercules dashboard gets too noisy
      systems = [ "x86_64-linux" "i686-linux" ];

      lib = nixpkgs.lib;

      eachSystem = lib.genAttrs systems;

      x = eachSystem (system:
        import ./. {
          inherit system inputs;
          lib = nixpkgs.lib;
        }
      );
    in
    {
      # Inherit from upstream
      inherit (nixpkgs) lib nixosModules htmlDocs;

      # But replace legacyPackages with the unfree version
      legacyPackages = eachSystem (system: x.${system}.legacyPackages);

      # And load all the unfree+redistributable packages as checks
      checks = eachSystem (system: x.${system}.checks);

      # Expose our own unfree overrides
      overlay = ./overlay.nix;

      herculesCI = { ... }: {
        onPush.default = {
          outputs = { ... }: {
            nixpkgs-unfree = self.checks;
          };
        };
      };
    };
}
