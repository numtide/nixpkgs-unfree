let
  # Add packages here that we want to build and that are not
  # unfree+redistributable.
  extraChecks = [
    "blas"
    "cudatoolkit"
    "lapack"
    "mpich"
    "openmpi"
    "python3Packages.jaxlibWithCuda"
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
      overlay = final: prev: {
        cudatoolkit = final.cudatoolkit_11;
        cudnn = final.cudnn_cudatoolkit_11;
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
