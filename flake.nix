{
  description = "nixpkgs with the unfree bits enabled";

  nixConfig = {
    extra-substituters = [ "https://nixpkgs-unfree.cachix.org" ];
    extra-trusted-public-keys = [ "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs=" ];
  };

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
            cudaSupport = true;
          };
          overlays = [ self.overlays.default ];
        }
      );

      # And load all the unfree+redistributable packages as checks
      checks = eachSystem
        (system:
          let
            pkgs = self.legacyPackages.${system};

            # Turn this on to debug things.
            debug = false;

            trace = if debug then builtins.trace else (msg: value: value);
            # Tweaked version of nixpkgs/maintainers/scripts/check-hydra-by-maintainer.nix
            #
            # It traverses nixpkgs recursively, respecting recurseForDerivations and 
            # returns a list of name/value pairs of all the packages matching "cond"
            packagesWith = prefix: cond: set:
              lib.flatten
                (lib.mapAttrsToList
                  (key: v:
                    let
                      name = "${prefix}${key}";
                      result = builtins.tryEval
                        (
                          if lib.isDerivation v && cond name v then
                          # Skip packages whose closure fails on evaluation.
                          # This happens for pkgs like `python27Packages.djangoql`
                          # that have disabled Python pkgs as dependencies.
                            builtins.seq v.outPath [ (lib.nameValuePair name v) ]
                          else if v.recurseForDerivations or false || v.recurseForRelease or false
                          # Recurse
                          then packagesWith "${name}_" cond v
                          else [ ]
                        );
                    in
                    if result.success
                    then trace name result.value
                    else [ ]
                  )
                  set
                )
            ;

            isUnfreeRedistributable = licenses:
              lib.lists.any (l: (!l.free or true) && (l.redistributable or false)) licenses;

            hasLicense = pkg:
              pkg ? meta.license;

            hasUnfreeRedistributableLicense = pkg:
              hasLicense pkg &&
              isUnfreeRedistributable (lib.lists.toList pkg.meta.license);

            unfreeRedistributablePackages = packagesWith
              ""
              (name: pkg: hasUnfreeRedistributableLicense pkg)
              nixpkgs;

            /* Return an attribute from a nested attribute set.

              Example:
              x = {a = { b = 3; }; }
              getAttr "a.b" x
              => 3
              getAttr "a.floo" x
            */
            getAttr = attrPath:
              let
                attrPath_ = lib.filter lib.isString (builtins.split "\\\." attrPath);
              in
              lib.attrByPath attrPath_ (abort "cannot find attribute '" + attrPath "'");

            extraChecks = map
              (name: lib.nameValuePair (lib.replaceStrings [ "." ] [ "_" ] name) (getAttr name pkgs))
              pkgs.extraChecks;
          in
          # Returns the recursive set of unfree but redistributable packages as checks
          lib.listToAttrs (unfreeRedistributablePackages ++ extraChecks)
        );
    };
}
