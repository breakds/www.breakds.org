---
# Documentation: https://sourcethemes.com/academic/docs/managing-content/

title: "Packaging (Nightly) Rust Application with Nix"
subtitle: ""
summary: ""
authors: [breakds]
tags: ["rust", "nightly", "package", "nixos"]
categories: ["nix", "rust", "dev"]
date: 2020-02-01T20:24:04-08:00
lastmod: 2020-02-03T09:16:04-08:00
featured: false
draft: false

# Featured image
# To use, add an image named `featured.jpg/png` to your page's folder.
# Focal points: Smart, Center, TopLeft, Top, TopRight, Left, Right, BottomLeft, Bottom, BottomRight.
image:
  caption: ""
  focal_point: ""
  preview_only: false

# Projects (optional).
#   Associate this post with one or more of your projects.
#   Simply enter your project's folder or file name without extension.
#   E.g. `projects = ["internal-project"]` references `content/project/deep-learning/index.md`.
#   Otherwise, set `projects = []`.
projects: []
---

## Introduction

[Rust](https://www.rust-lang.org/) has gained a lot of traction recently. I was
chatting with a friend about building web applications with rust, and mentioned
how [rocket](https://rocket.rs/) makes it easier and enjoyable. I figured it
might be a good time to pick rust up now. It does not take long to refamiliarize
myself with rust and rocket, and I ended up building a tiny and dumb [web
application](https://git.breakds.org/breakds/simple-reflection-server) with it.

My plan was to further polish it and make it a [NixOS](https://nixos.org/)
service, so that I can easily spin it up on all my NixOS powered machines. This
gave me a good execuse to learn to package Rust applications as well. What a
lovely afternoon!

It turns out that packing a rust apllication in Nix is very simple, which is
explained in [Nixpkgs
Doc](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md#compiling-rust-applications-with-cargo)
well. However, if what you are building is based a relatively new nightly
version of rust, it would take some more steps. I am documenting what I learned
in the process here so that you do not have to research this topic again.

**Note**: None of the solutions here originates from me. I am grateful of their
original authors inspiration and effort. The solutions definitely helped me, and
I hope it helps you the reader as well.

## The First Attempt (And Why It Didn't Work)

Following the nixpkgs documentation on packaging Rust application, I finished
the following nix code right away with `buildRustPackage` in the `default.nix`:

```nix
{ stdenv, pkgs, fetchFromGitHub, rustPlatform, ... }:

rustPlatform.buildRustPackage rec {
  pname = "simple-reflection-server";
  version = "1.1.x";

  src = fetchFromGitHub {
    owner = "breakds";
    repo = pname;
    rev = version;
    sha256 = "1y2irlnha0dj63zp3dfbmrhssjj9qdxcl7h5sfr5nxf6dd4vjccg";
  };

  cargoSha256 = "0drf5xnqin26zdyvx9n2zzgahcnrna0y56cphk2pb97qhpakvhbj";
  verifyCargoDeps = true;
}
```

The following command is used to try building the package

```bash
$ nix-build -E "with import <nixpkgs> {}; callPackage ./default.nix {}"
```

Sadly, the build failed right away, for mainly two reasons.

1. The first one is about the `Cargo.lock` file. My `Cargo.lock` file is
   generated with a newer version of Cargo and Rust, so that it is no longer
   parse-able by the relatively old version in `<nixpkgs>` (which tracks 19.09
   channel right now).
2. The second one comes from the fact that the `rustPlatform` in `<nixpkgs>`
   currently offers a stable version of `rust`, while since the web application
   to be packaged is based on `rocket`, it requires a nightly version of `rust`.

It is possible to use `rustup` to downgrade my toolchain for development, which
can solve problem 1 but won't help problem 2. Therefore I need to seek a more
principal solution that can bring a new and nightly version of rust into the
game.

## Mozilla Overlay To the Rescue

Thankfully, Mozilla as the major sponsor of [Rust](https://www.rust-lang.org/),
is also an Nix-friendly company. It provides a set of
[overlays](https://nixos.wiki/wiki/Overlays) that includes mechanism to acquire
latest version of Rust in it, hosted at
[nixpkgs-mozilla](https://github.com/mozilla/nixpkgs-mozilla).

The idea proposed by Daniel (danieldk)
[here](https://discourse.nixos.org/t/how-can-i-use-rustc-unstable-with-rustplatform-buildrustpackage-solved/3526/6)
is straight-forward and effective: instead of use the stock `rustPlatform`,
let's build our own `rustPlatform` with overridden `rust` and `cargo` from the
Mozilla Overlay. I put the following code (slightly modified from Daniel's
original version) in a file called `mk-rust-platform`.

```nix
{ callPackage, fetchFromGitHub, makeRustPlatform }:

{ date, channel }:

let mozillaOverlay = fetchFromGitHub {
      owner = "mozilla";
      repo = "nixpkgs-mozilla";
      rev = "5300241b41243cb8962fad284f0004afad187dad";
      sha256 = "1h3g3817anicwa9705npssvkwhi876zijyyvv4c86qiklrkn5j9w";
    };
    mozilla = callPackage "${mozillaOverlay.out}/package-set.nix" {};
    rustSpecific = (mozilla.rustChannelOf { inherit date channel; }).rust;

in makeRustPlatform {
  cargo = rustSpecific;
  rustc = rustSpecific;
}
```

It basically provides a function to generate `rustPlatform` with specified date
(e.g. `"2020-01-15"`) and channel (e.g. `"nightly"`) of Rust. And now, just
replace the `rustPlatform` in the previous attempt with a specifically produced
one in the `default.nix` for my package:

```nix
{ stdenv, pkgs, fetchFromGitHub, ... }:

let mkRustPlatform = pkgs.callPackage ./mk-rust-platform.nix {};

    rustPlatform = mkRustPlatform {
      date = "2020-01-15";
      channel = "nightly";
    };

in rustPlatform.buildRustPackage rec {
  pname = "simple-reflection-server";
  version = "1.1.x";

  src = fetchFromGitHub {
    owner = "breakds";
    repo = pname;
    rev = version;
    sha256 = "1y2irlnha0dj63zp3dfbmrhssjj9qdxcl7h5sfr5nxf6dd4vjccg";
  };

  cargoSha256 = "0drf5xnqin26zdyvx9n2zzgahcnrna0y56cphk2pb97qhpakvhbj";
  verifyCargoDeps = true;
}
```

This solved the mentioned 2 problems pretty well. There is one catch though,
which is that during the build phase by Cargo, some files will be generated and
written to the `$HOME` directory. It cripples the Nix build because there will
be no `$HOME`, and Nix will complain about

```
error: failed to acquire package cache lock

Caused by:
  failed to open: /homeless-shelter/.cargo/.package-cache
```

Guillaume (GitHub id [layus](https://github.com/layus)) provided a work-around
in the following [GitHub
Issue](https://github.com/NixOS/nixpkgs/issues/61618#issuecomment-499377463) to
temporarily assign a directory to `$HOME` to applease Cargo. This adds one
`export` in the `preConfigure` phase.

```nix
preConfigure = ''
  export HOME=$(mktemp -d)
'';
```

## Handling Resource (Templates) Files

Now the Rust application should be successfully built, and if this already
achieves your purpose - that's good.

However in my case, since the application is a web server with **templates**,
building the binary alone will not get the template files into the final
package, and the binary will fail to generate web pages (Cannot find templates).

It would be a common case when resource files are needed, be it templates,
configurations or other types of data files. I am not sure whether Cargo can or
should do that, but it feels like it is Nix's responsibility to do so. 

The trick I have been using is to have a `postInstall` that copies the templates
into the package, as well as setting the environment variable specific to the
binary (with `makeWrapper`) so that it knows where to find the template files.
This can be done by simply adding the piece of code below into your
`default.nix`.

```
  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    mkdir $out/etc/
    cp -r templates $out/etc
    wrapProgram "$out/bin/simple-reflection-server" \
      --prefix ROCKET_TEMPLATE_DIR : "$out/etc/templates"
  '';
```

Note that in order to use `wrapProgram`, you need `makeWrapper` as one of
`nativeBuildinputs`. The `--prefix`basically translates to

> Whenever you run this program, set the environment variable to this value
> before launching the binary.

## Conclusion

The full working `default.nix` now reads:

```nix
{ stdenv, pkgs, fetchFromGitHub, ... }:

let mkRustPlatform = pkgs.callPackage ./mk-rust-platform.nix {};

    rustPlatform = mkRustPlatform {
      date = "2020-01-15";
      channel = "nightly";
    };

in rustPlatform.buildRustPackage rec {
  pname = "simple-reflection-server";
  version = "1.1.x";

  src = fetchFromGitHub {
    owner = "breakds";
    repo = pname;
    rev = version;
    sha256 = "1y2irlnha0dj63zp3dfbmrhssjj9qdxcl7h5sfr5nxf6dd4vjccg";
  };
  
  nativeBuildInputs = [ makeWrapper ];

  cargoSha256 = "0drf5xnqin26zdyvx9n2zzgahcnrna0y56cphk2pb97qhpakvhbj";
  verifyCargoDeps = true;
  
  preConfigure = ''
    export HOME=$(mktemp -d)
  '';
  
  postInstall = ''
    mkdir $out/etc/
    cp -r templates $out/etc
    wrapProgram "$out/bin/simple-reflection-server" \
      --prefix ROCKET_TEMPLATE_DIR : "$out/etc/templates"
  '';
}
```

And the non-simplified version can be found
[here](https://git.breakds.org/breakds/nixvital/src/branch/master/pkgs/simple-reflection-server/default.nix).

As a relatively new community, Rust is being updated every day so that the
standard process for packaging Rust application might need some time to catch
up. However, I would say that it is basically working without major hacks, and I
am pretty satisified with the current solution.

Happy Hacking!
