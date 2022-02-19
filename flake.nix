{

  description = "nixpkgs, but with allowUnfree = true";

  outputs = { self, nixpkgs }:
    let
      # Only support systems for which we have a CI for.
      systems = [ "x86_64-linux" ];

      lib = nixpkgs.lib;

      eachSystem = lib.genAttrs systems;

      x = eachSystem (system:
        import ./. {
          nixpkgs = import nixpkgs {
            inherit system;
            config = { allowUnfree = true; };
          };
          lib = nixpkgs.lib;
          # Should not be needed
          system = null;
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
