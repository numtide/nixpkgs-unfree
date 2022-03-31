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
    [ "cudnn" ]
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

  # List packages that we never want to be even marked as "broken"
  # These will be checked just for x86_64-linux and for one release of python
  neverBreak = lib.mapAttrs
    (cfgName: pkgs:
      let
        # removed packages (like cudatoolkit_6) are just aliases that `throw`:
        notRemoved = pkg: (builtins.tryEval (builtins.seq pkg true)).success;
        cuPrefixae = [
          "cudatoolkit"
          "cudnn"
          "cutensor"
        ];
        isCuPackage = name: package: (notRemoved package) && (builtins.any (p: lib.hasPrefix p name) cuPrefixae);
        cuPackages = lib.filterAttrs isCuPackage pkgs;
        stablePython = "python39Packages";
        pyPackages = lib.genAttrs [
          "pytorch"
          "cupy"
          "jaxlib"
          "tensorflowWithCuda"
        ]
          (name: pkgs.${stablePython}.${name});
      in
      {
        inherit pyPackages;
      } // cuPackages)
    nixpkgsInstances;

  neverBreakOutPaths = lib.collect (a: a ? "_attr-path" && a ? "_out-path")
    (lib.mapAttrsRecursiveCond
      (a: !(a ? "type" && a.type == "derivation"))
      (path: a: { _attr-path = path; _out-path = a.outPath; })
      neverBreak);
  neverBreakReport = nixpkgsInstances.vanilla.writeText "never-break-outpaths.txt" (lib.concatStringsSep "\n"
    (builtins.map
      ({ _attr-path, _out-path }:
        let
          result = builtins.tryEval (builtins.toString _out-path);
          p = if result.success then result.value else "<FAILED>";
        in
        "${lib.concatStringsSep "." _attr-path}: ${p}")
      neverBreakOutPaths));
in
{
  # Export the whole tree
  legacyPackages = nixpkgsInstances.vanilla;

  # Returns the recursive set of unfree but redistributable packages as checks
  inherit checks neverBreak neverBreakReport;
}
