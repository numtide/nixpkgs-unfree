{ system ? builtins.currentSystem
, inputs ? (builtins.getFlake (builtins.toString ./.)).inputs
, lib ? inputs.nixpkgs.lib
, debug ? false
}:
let
  trace = if debug then builtins.trace else (msg: value: value);

  # cf. Tweaked version of nixpkgs/maintainers/scripts/check-hydra-by-maintainer.nix
  maybeBuildable = v:
    let result = builtins.tryEval
      (
        if lib.isDerivation v then
        # Skip packages whose closure fails on evaluation.
        # This happens for pkgs like `python27Packages.djangoql`
        # that have disabled Python pkgs as dependencies.
          builtins.seq v.outPath [ v ]
        else [ ]
      );
    in if result.success then result.value else [ ];

  isUnfreeRedistributable = licenses:
    lib.lists.any (l: (!l.free or true) && (l.redistributable or false)) licenses;

  hasLicense = pkg:
    pkg ? meta.license;

  hasUnfreeRedistributableLicense = pkg:
    hasLicense pkg &&
    isUnfreeRedistributable (lib.lists.toList pkg.meta.license);

  configs = import ./configs.nix;
  nixpkgsInstances = lib.mapAttrs
    (configName: config: import inputs.nixpkgs ({ inherit system; } // config))
    configs;

  extraPackages = [
    [ "blas" ]
    [ "cudatoolkit" ]
    [ "lapack" ]
    [ "mpich" ]
    [ "nccl" ]
    [ "opencv" ]
    [ "openmpi" ]
    [ "ucx" ]
    [ "blender" ]
    [ "colmapWithCuda" ]
  ];

  pythonAttrs =
    let
      matrix = lib.cartesianProductOfSets
        {
          pkg = [
            "caffe"
            "chainer"
            "cupy"
            "jaxlib"
            "Keras"
            "libgpuarray"
            "mxnet"
            "opencv4"
            "pytorch"
            "pycuda"
            "pyrealsense2WithCuda"
            "torchvision"
            "TheanoWithCuda"
            "tensorflowWithCuda"
            "tensorflow-probability"

          ] ++ [
            # These need to be rebuilt because of MKL
            "numpy"
            "scipy"
          ];
          ps = [
            "python38Packages"
            "python39Packages"
            "python310Packages"
          ];
        };

      mkPath = { pkg, ps }: [ ps pkg ];
    in
    builtins.map
      mkPath
      matrix;

  checks =
    let
      matrix = lib.cartesianProductOfSets
        {
          cfg = builtins.attrNames configs;
          path = extraPackages ++ pythonAttrs;
        };
      supported = builtins.concatMap
        ({ cfg, path }:
          let
            jobName = lib.concatStringsSep "_" ([ cfg ] ++ path);
            package = lib.attrByPath path [ ] nixpkgsInstances.${cfg};
            mbSupported = maybeBuildable package;
          in
          if mbSupported == [ ]
          then [ ]
          else [{ inherit jobName; package = (builtins.head mbSupported); }])
        matrix;
      kvPairs = builtins.map
        ({ jobName, package }: lib.nameValuePair jobName package)
        supported;
    in
    lib.listToAttrs kvPairs;
in
{
  # Export the whole tree
  legacyPackages = nixpkgsInstances.vanilla;

  # Returns the recursive set of unfree but redistributable packages as checks
  inherit checks;
}
