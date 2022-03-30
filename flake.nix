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

      inherit (nixpkgs) lib;

      systems = [ "x86_64-linux" ];

      eachSystem = lib.genAttrs systems;

      x = eachSystem (system:
        import ./. {
          inherit system inputs lib;
        }
      );
    in
    {
      # Inherit from upstream
      inherit (nixpkgs) lib nixosModules htmlDocs;

      # But replace legacyPackages with the unfree version
      legacyPackages = eachSystem (system: x.${system}.legacyPackages);

      # And load all the unfree+redistributable packages as checks
      checks =
        let
          defaultChecks = eachSystem (system: x.${system}.checks);

          # I know, looks dense
          neverBreak = lib.listToAttrs (builtins.map
            ({ check-never-breaks, package }: lib.nameValuePair (lib.concatStringsSep "_" check-never-breaks) package)
            (lib.collect
              (a: a ? "check-never-breaks")
              (lib.mapAttrsRecursiveCond
                (a: !(a ? "type" && a.type == "derivation"))
                (path: package: { check-never-breaks = [ "never-break" ] ++ path; inherit package; })
                x.x86_64-linux.neverBreak)));
        in
        lib.recursiveUpdate defaultChecks {
          x86_64-linux = neverBreak;
        };

      # Expose our own unfree overrides
      overlay = builtins.head x."x86_64-linux".overlays;

      herculesCI = { ... }: {
        onPush.default.outputs = {
          defaultChecks = eachSystem (system: x.${system}.checks);
        };
      };
    };
}
