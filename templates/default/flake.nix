{
  description = "Flake with nixpkgs-unfree";

  inputs = {
    nixpkgs.url = "github:numtide/nixpkgs-unfree";
  };

  outputs = inputs@{ nixpkgs, ... }: {

  };
}
