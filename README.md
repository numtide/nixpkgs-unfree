# nixpkgs-unfree - nixpkgs with the unfree bits enabled

**STATUS: alpha**

The [nixpkgs](https://github.com/NixOS/nixpkgs) project contains package
definitions for free and unfree packages but only builds free packages. This
project is complementary. We're enabling the unfree bits and pushing those to
our cache.  It also makes the flake use-case a bit easier to use.

Initially, this project spawned from the reflections drawn in and is now
expanding to provide a wider set of features.

## Features

### Binary cache

The CI is pushing build results to <https://numtide.cachix.org>. The
site provides instructions on adding the cache to your system.

### CUDA / performance packages

Some packages have been changed to use the better-performing proprietary
libraries. Think MPI / Blas / Lapack / ...

To see the full list, look at the [overlay](./overlay.nix).

### Flake usage

If your flake depends on unfree packages, please consider pointing it to this
project to avoid creating more instances of nixpkgs. See
<https://discourse.nixos.org/t/1000-instances-of-nixpkgs/17347> for a more
in-depth explanation of the issue.

Here is how you can replace your instance of nixpkgs with unfree packages
enabled:

```nix
{
  inputs.nixpkgs.url = "github:numtide/nixpkgs-unfree";
  inputs.nixpkgs.inputs.nixpkgs.follows = "github:NixOS/nixpkgs/nixos-unstable";

  # Optionally, pull pre-built binaries from this project's cache
  nixConfig.extra-substituters = [ "https://nixpkgs-unfree.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs=" ];

  outputs = { self, nixpkgs }: { ... };
}
```

Or, potentially, you might want to explicitly access unfree packages and have
a separate instance:

```nix
{
  # The main nixpkgs instance
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # The unfree instance
  inputs.nixpkgs-unfree.url = "github:numtide/nixpkgs-unfree";
  inputs.nixpkgs-unfree.inputs.nixpkgs.follows = "nixpkgs";

  # Optionally, pull pre-built binaries from this project's cache
  nixConfig.extra-substituters = [ "https://numtide.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" ];

  outputs = { self, nixpkgs, nixpkgs-unfree }: { ... };
}
```

### Nix run

Thanks to this flake, it make it easy to run unfree packages. Eg:

```console
$ nix run github:numtide/nixpkgs-unfree/nixos-unstable#slack
```

See the "supported channels" section to find out which channels are being synched.

## Supported channels

FIXME: channel branches are currently force-pushed so they shouldn't be used as pinned sources.

The following channels are updated daily (more in the future):

* nixos-unstable
* nixpkgs-unstable

## Credits

The first implementation of that idea was done by @domenkozar at
<https://github.com/cachix/nixpkgs-unfree-redistributable>.

## Terms and Conditions

All the code in this repository is published under the MIT and will always
remain under an OSI-compliant license.

The binary cache is available for free for non-commercial usage.

If you're interested in supporting this project,
[get in touch!](https://numtide.com/#contact).
