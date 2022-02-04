# nixpkgs-unfree - nixpkgs with the unfree bits enabled

One downside of the ideas laid down in
https://discourse.nixos.org/t/1000-instances-of-nixpkgs/17347 is that there is
no way to access unfree nixpkgs packages without creating a new instance of
it. This flake proposes to be the default way to explicitly request unfree
packages.

## Usage

### Flake

Here is how you can replace your instance of nixpkgs with unfree packages
enabled:

```nix
{
  inputs.nixpkgs.url = "github:numtide/nixpkgs-unfree";
  inputs.nixpkgs.inputs.nixpkgs.follows = "github:NixOS/nixpkgs/nixos-unstable";
}
```

Or potentially you might want to explicitly access unfree packages and have a
separate instance:

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

### Nix run

Thanks to this flake, it becomes now possible to run unfree packages. Eg:

```console
$ nix run --no-write-lock-file github:numtide/nixpkgs-unfree#slack
```

## Missing features

* Keep nixpkgs channels in sync. See #1
* allow broken and other types of packages as well?

## License

MIT
