{
  description = "Flake with nixpkgs-unfree";

  inputs = {
    nixpkgs.url = "github:numtide/nixpkgs-unfree";
  };

  nixConfig.extra-substituters = [ "https://numtide.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" ];

  outputs = inputs@{ nixpkgs, ... }: {

  };
}
