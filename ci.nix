# Used by Hercules CI
{ system ? builtins.currentSystem }:
{
  "x86_64-linux" = (import ./. { system = "x86_64-linux"; }).checks // {
    recurseForDerivations = true;
  };
}
