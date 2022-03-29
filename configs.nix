{
  vanilla = {
    config.allowUnfree = true;
    config.cudaSupport = true;
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

        suitesparse = prev.suitesparse.override {
          enableCuda = true;
        };

        blas = prev.blas.override {
          blasProvider = final.mkl;
        };

        lapack = prev.lapack.override {
          lapackProvider = final.mkl;
        };
      };
    in
    {
      config.allowUnfree = true;
      config.cudaSupport = true;

      overlays = [ overlay ];
    };
}
