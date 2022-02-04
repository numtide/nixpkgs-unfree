{

  description = "nixpkgs, but with allowUnfree = true";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
    in
    # Get the instance of nixpkgs
    nixpkgs // {
      # But replace legacyPackages with the unfree version
      legacyPackages = lib.genAttrs lib.systems.supported.hydra (system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        }
      );
    };
}
