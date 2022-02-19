# TODO: move these overrides into a nixpkgs config option
final: prev: {
  cudatoolkit = prev.cudatoolkit_11;

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
}
