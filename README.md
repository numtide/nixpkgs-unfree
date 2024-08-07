# nixpkgs-unfree - nixpkgs with the unfree bits enabled

**STATUS: alpha**

The [nixpkgs](https://github.com/NixOS/nixpkgs) project contains package
definitions for free and unfree packages but only builds free packages. This
project is complementary. We're enabling the unfree bits and making the flake
use-case a bit easier to use.

In the future, we would also like to evolve this project to build and cache
the unfree packages.

## Features

### Nix run

Thanks to this flake, it's shorter to run unfree packages. Eg:

```console
$ nix run github:numtide/nixpkgs-unfree/nixos-unstable#slack
```

Vs:

```console
$ NIXPKGS_ALLOW_UNFREE=1 nix run nixpkgs/nixos-unstable#slack --impure
```

See the [supported channels](#supported-channels) section to find out which channels are being synched.

### Flake usage

If your flake depends on unfree packages, you can point it to this
project to avoid creating more instances of nixpkgs. See
<https://discourse.nixos.org/t/1000-instances-of-nixpkgs/17347> for a more
in-depth explanation of the issue.

Here is how you can replace your instance of nixpkgs with unfree packages
enabled:

```nix
{
  inputs.nixpkgs.url = "github:numtide/nixpkgs-unfree?ref=nixos-unstable";

  inputs.otherdep.url = "github:otheruser/otherdep";
  inputs.otherdep.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, ... }: { ... };
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

  outputs = { self, nixpkgs, nixpkgs-unfree }: { ... };
}
```

### Flake templates

For new flakes, you can use also use our templates like this:

``` console
$ nix flake init -t github:numtide/nixpkgs-unfree
$ nix flake init -t github:numtide/nixpkgs-unfree#devShell # for mkShell based setup
```

## FAQ

### nixpkgs instances

This repository includes a trace warning for code that `import nixpkgs`.

If another input depends on it, you can bypass the warning by passing the
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
