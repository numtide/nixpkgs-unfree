{
  description = "nixpkgs with the unfree bits enabled";

  nixConfig = {
    extra-substituters = [
      "https://nixpkgs-unfree.cachix.org"
      "https://nixpkgs-unfree-some.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      "nixpkgs-unfree-some.cachix.org-1:VL4L7ryUJUg0wuhY+oXFcRfOjCU9UHwDM8Ih+tokGXs="
    ];
  };

  outputs = inputs@{ self, nixpkgs }:
    let
      # Support the same list of systems as upstream.
      systems = lib.systems.supported.hydra;

      lib = nixpkgs.lib;

      eachSystem = lib.genAttrs systems;
      eachPython = lib.genAttrs [ "python38" "python39" "python310" ];

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
            effects = {
              packageTests = eachSystem (system:
                eachPython (python:
                  {
                    pytorch = self.legacyPackages.${system}.${python}.pkgs.pytorch.tests;
                  })
              );
            };
          };
        };
      };
    };
}
