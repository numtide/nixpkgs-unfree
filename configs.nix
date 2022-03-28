let
  # Add packages here that we want to build and that are not
  # unfree+redistributable.
  extraChecks = [
    "blas"
    "cudatoolkit"
    "lapack"
    "mpich"
    "openmpi"
    "python3Packages.colmapWithCuda"
    "python3Packages.jaxlibWithCuda"
    "python3Packages.pytorch"
    "python3Packages.tensorflowWithCuda"
    "ucx"
  ];
in
{
  vanilla =
    let
      overlay =
        final: prev: {
          inherit extraChecks;
        };
    in
    {
      config.allowUnfree = true;
      config.cudaSupport = true;
      overlays = [ overlay ];
    };

  mklCuda11 =
    let
      potentialNames = {
        cudnn = [ "cudnn_cudatoolkit_11" "cudnn_8_3_cudatoolkit_11" ];
      };

      tryByName = pkgs: name: if builtins.hasAttr name pkgs then [ pkgs.${name} ] else [ ];
      byAnyName = pkgs: name: builtins.head (pkgs.lib.concatMap (tryByName pkgs) potentialNames.${name});

      overlay = final: prev: {
        cudatoolkit = final.cudatoolkit_11;
        cudnn = byAnyName final "cudnn";
        cutensor = final.cutensor_cudatoolkit_11;

        mpich = prev.mpich.override {
          ch4backend = final.ucx;
        };

        openmpi = prev.openmpi.override {
          cudaSupport = true;
        };

        ucx = prev.ucx.override {
          enableCuda = true;
        };

        blas = prev.blas.override {
          blasProvider = final.mkl;
        };

        lapack = prev.lapack.override {
          lapackProvider = final.mkl;
        };

        inherit extraChecks;
      };
    in
    {
      config.allowUnfree = true;
      config.cudaSupport = true;

      overlays = [ overlay ];
    };
}
