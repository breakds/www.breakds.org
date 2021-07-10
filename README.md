# My Blog/Website with Wowchemy Academic Theme

## Build the blog

Currently the blog is built with [Nix Flakes](https://nixos.wiki/wiki/Flakes). To build it, run 

```bash
path/to/www.breakds.org $ nix build .
```

The package is defined in [flake.nix](./flake.nix). After upgrading to Hugo with [go modules](https://golang.org/ref/mod), building it requires downloading the module dependencies (see [go.mod](./go.mod)) which is something that Nix does not allow. To solve this, we choose to [vendor the modules](https://gohugo.io/hugo-modules/use-modules/#vendor-your-modules) by ourselves so that during the build `hugo` will choose to use the modules in [_vendor](./_vendor) direcotry.

Note that when the dependencies change, we need to vendor those modules again to update the [_vendor](./_vendor) direcotry by

```bash
path/to/www.breakds.org $ hugo mod vendor
```
