{

  description = "nixpkgs, but with allowUnfree = true";

  nixConfig = {
    extra-substituters = [ "https://nixpkgs-unfree.cachix.org" ];
    extra-trusted-public-keys = [ "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs=" ];
  };

  outputs = inputs@{ self, nixpkgs }:
    let
      # Support the same list of systems as upstream.
      systems = lib.systems.supported.hydra;

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
    };
}
