# nixpkgs-unfree - nixpkgs with the unfree bits enabled

**STATUS: alpha**

The [nixpkgs](https://github.com/NixOS/nixpkgs) project contains package
definitions for free and unfree packages but only builds free packages. This
project is complementary. We're enabling the unfree bits and pushing those to
our cache.  It also makes the flake use-case a bit easier to use.

Initially, this project spawned from the reflections drawn in and is now
expanding to provide a wider set of features.

## Features

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
  inputs.nixpkgs.inputs.nixpkgs.follows = "nixpkgs-unstable";

  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  # Optionally, pull pre-built binaries from this project's cache
  nixConfig.extra-substituters = [ "https://numtide.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" ];

  outputs = { self, nixpkgs, ... }: { ... };
}
```

For new flakes, you can use also use our templates like this:

``` console
$ nix flake init -t github:numtide/nixpkgs-unfree
$ nix flake init -t github:numtide/nixpkgs-unfree#devShell # for mkShell based setup
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

### Supported channels

The following channels are updated daily (more in the future):

* nixos-unstable
* nixpkgs-unstable
* nixos-24.05

### FAQ

## nixpkgs instances

This repository includes a trace warning for code that `import nixpkgs`.

In general, it's best to avoid creating new instances of nixpkgs. See
<https://zimbatm.com/notes/1000-instances-of-nixpkgs> for a more thorough
explanation.

If another input depends on it, you can also bypass the warning by passing the
real nixpkgs to it.

Before:
```nix
{
  inputs.nixpkgs.url = "github:numtide/nixpkgs-unfree?ref=nixos-unstable";

  inputs.otherdep.url = "github:otheruser/otherdep";
  inputs.otherdep.inputs.nixpkgs.follows = "nixpkgs";
}
```

Assuming that "otherdep" creates a new instance of nixpkgs, change the inputs
to:

```nix
{
  inputs.nixpkgs.url = "github:numtide/nixpkgs-unfree?ref=nixos-unstable";

  inputs.otherdep.url = "github:otheruser/otherdep";
  inputs.otherdep.inputs.nixpkgs.follows = "nixpkgs/nixpkgs";
}
```

With that, it will access the same version of nixpkgs as the main project.

## Credits

The first implementation of that idea was done by @domenkozar at
<https://github.com/cachix/nixpkgs-unfree-redistributable>.

## Terms and Conditions

All the code in this repository is published under the MIT and will always
remain under an OSI-compliant license.

If you're interested in supporting this project,
[get in touch!](https://numtide.com/#contact).
