# Returns an attribute set of packages to build
{ nixpkgs, system }:
let
  lib = nixpkgs.lib;

  pkgs = import nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  };

  # Turn this on to debug things.
  debug = false;

  trace = if debug then builtins.trace else (msg: value: value);

  # Tweaked version of nixpkgs/maintainers/scripts/check-hydra-by-maintainer.nix
  #
  # It traverses nixpkgs recursively, respecting recurseForDerivations and 
  # returns a list of name/value pairs of all the packages matching "cond"
  packagesWith =
    prefix: cond: set:
    lib.flatten (
      lib.mapAttrsToList (
        key: v:
        let
          name = "${prefix}${key}";
          result = builtins.tryEval (
            if lib.isDerivation v && cond name v then
              # Skip packages whose closure fails on evaluation.
              # This happens for pkgs like `python27Packages.djangoql`
              # that have disabled Python pkgs as dependencies.
              builtins.seq v.outPath [ (lib.nameValuePair name v) ]
            else if
              v.recurseForDerivations or false || v.recurseForRelease or false
            # Recurse
            then
              packagesWith "${name}_" cond v
            else
              [ ]
          );
        in
        if result.success then trace name result.value else [ ]
      ) set
    );

  isUnfree = pkg: lib.lists.any (l: !(l.free or true)) (lib.lists.toList (pkg.meta.license or [ ]));

  isSource =
    key: pkg: !lib.lists.any (x: !(x.isSource)) (lib.lists.toList (pkg.meta.sourceProvenance or [ ]));

  isNotLinuxKernel = key: !(lib.hasPrefix "linuxKernel" key || lib.hasPrefix "linuxPackages" key);

  isNotCudaPackage = key: !(lib.hasPrefix "cuda" key);

  select =
    key: pkg: (isUnfree pkg) && (isSource key pkg) && (isNotCudaPackage key) && (isNotLinuxKernel key);

  packages = packagesWith "" (key: select key) pkgs;
in
# Returns the recursive set of packages as checks
lib.listToAttrs packages
