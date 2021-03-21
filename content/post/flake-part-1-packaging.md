---

title: "Nix Flakes by Example, Part 1"
subtitle: "A simple package"
summary: ""
authors: [breakds]
tags: ["nix", "flake", "derivation", "nixos", "package"]
categories: ["nixos"]
date: 2021-03-19T10:00:04-08:00
lastmod: 2021-03-19T10:37:04-08:00
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

If you are a Nix user, you probably already have heard about [Nix
Flakes](https://nixos.wiki/wiki/Flakes). There are already many great
posts about it, among them we have the author of flakes - Eelco
Dolstra's

1. [Nix Flakes, Part 1: An Introduction And
   Tutorial](https://www.tweag.io/blog/2020-05-25-flakes/)
2. [Nix Flakes, Part 2: Evaluation
   Caching](https://www.tweag.io/blog/2020-06-25-eval-cache/)
3. [Nix Flakes, Part 3: Managing NixOS
   Systems](https://www.tweag.io/blog/2020-07-31-nixos-flakes/)
   
   
I plan to start a new series talking about the more practical side of
flakes, i.e. how to use it to solve my day-to-day pain point, one
example per post. This is the first part of the series, in which I
will talk about how to package with flakes.

## Nix Software Packaging The Old Way

Suppose we have a very simple application `hello-repeater`, that
periodically prints `Hello, <name of your choice>` on the screen to
greet someone. You can find the source code
[here](https://github.com/breakds/flake-example-hello-repeater/tree/c+%2B-code-alone),
but it is just as simple as:

``` cpp
#include <cstdio>
#include <chrono>
#include <thread>

int main(int argc, char **argv) {
  while (true) {
    printf("Hello, sir!\n");
    std::this_thread::sleep_for(std::chrono::seconds(5));
  }
  return 0;
}
```

A typical use case is that I will need to create a package
(derivation) out of it and use the package in another project or a
NixOS configuration. This means I will need to write a `.nix` file to
package it like this:

```nix
{ pkgs, stdenv, cmake, ... }:

stdenv.mkDerivation {
  pname = "hello-repeater";
  version = "1.0.0";
  src = pkgs.fetchgit {
    url = "https://github.com/breakds/flake-example-hello-repeater.git";
    rev = "c++-code-alone";
    sha256 = "sha256-/3tT3jBmWLaENcBRQhi2o3DHbBp2yiYsq2HMD/OYXNU=";
  };

  nativeBuildInputs = [
    cmake
  ];
}
```

And then I can add this as a dependency by calling `callPackage` on
it. So far so good.

**The problem**: Imagine the case when I have to use this package in 5
different projects or NixOS configurations, and they live in 5
different git repos. It does not make sense to replicate the above
`.nix` file 5 times!


Ideally, you only want to define that package once, preferrably in the
original software's repo. Althgouh it is possible to work that around
without having to use Nix Flakes, but I think Nix Flakes provides one
of the most elegant way to deal with that. Let's dive in!

## Preparation

You will first need to [enable
flakes](https://nixos.wiki/wiki/Flakes). Since I am running NixOS, it
is as simple as adding the following to my NixOS configuration with a
`nixos-rebuild switch`:

``` nix
nix = {
  package = pkgs.nixFlakes;
  extraOptions = ''
    experimental-features = nix-command flakes
  '';
};
```

## Packaging with `flake.nix`

Let's add a `flake.nix` to **the root** of our software's repo. You
can go ahead and `touch` it or use the following command to create it
from a template and modify it:

```
nix flake init 
```

Our first `flake.nix` looks like this:

```
{
  description = "Package the hello repeater.";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello-repeater =
      let pkgs = import nixpkgs {
            system = "x86_64-linux";
          };
      in pkgs.stdenv.mkDerivation {
        pname = "hello-repeater";
        version = "1.0.0";
        src = pkgs.fetchgit {
          url = "https://github.com/breakds/flake-example-hello-repeater.git";
          rev = "c++-code-alone";
          sha256 = "sha256-/3tT3jBmWLaENcBRQhi2o3DHbBp2yiYsq2HMD/OYXNU=";
        };

        nativeBuildInputs = with pkgs; [
          cmake
        ];
      };
  };
}
```

Let me explain it a bit. The whole purpose of this `flake.nix` is to
provide a package called `hello-repeater`. To achieve that, we need to
specify `outputs`.

The variable `outputs` is defined as a function that returns an
**attribute set**, where our package (derivation) is defined under
`packages.x86_64-linux.hello-repeater`. The code that actally defines
the derivation is not interesting, as it is merely a copy of the above
derivation with a specialized `pkgs` derived from `nixpkgs`.

**Q**: Why the attribute path `packages.x86_64-linux.hello-repeater`?
Is it some kind of convention?

**A**: Yes it is a Nix flakes convention to put the packages you want
to expose at `packages.<system>.<package-name>`. The type of such
attributes must be
[derivation](https://nixos.org/manual/nix/unstable/expressions/derivations.html).
There are quite a few [other special attribute
paths](https://github.com/NixOS/nix/blob/a93916b1905cd7b968e92cd94a3e4a595bff2e0f/src/nix/flake-check.md),
and we will talk about them later in this series.

**Q**: What is `<system>` in `packages.<system>.<package-name>`?

**A**: A package can be built under different systems, and we put them
under each `<system>` attribute for all the systems that we want the
package to support. In the above example we only enabled it for
`x86_64-linux`, which stands for 64 bit Linux on X86 architecture CPU.
In the next post, we will talk more about different systems.


## Play With the Flake

So that's all the code we need to write today. The full repo snapshot
can be found at this [git
tag](https://github.com/breakds/flake-example-hello-repeater/tree/single-flake).

So now it is time to introduce the two frequently used commands to
operate with flakes: `nix flake show` and `nix build`.


### Command - `nix flake show`

You can use the command 

``` bash
$ nix flake show <specify-your-flake>
```

to show the structure of the `outputs` of the flake. How to specify a
flake then? There are multiple ways.

1. If you want to specify a local flake on your machine, just use the
   **absolute** or **relative** path to the root directory that
   contains the `flake.nix`. Examples:
   
   ``` bash
   .  # The flake in the current directory
   
   ../projects/my-proj  # The flake at a relative path

   /home/myname/projects/my-proj  # The flake at an absolute path
   ```
   
   The is extremely useful when you are still developing the software
   and flake, and simply want to test them locally.
   
   **NOTE**: You will need to make sure all the `.nix` files
   (including the `flake.nix`) are **already tracked** by `git` before
   referring to them locally.
   
2. If you want to specify a remote flake from GitHub, follow the examples below:

    ``` bash
    # Specify a github repo 
    github:breakds/flake-example-hello-repeater
    
    # Specify a tagged commit called "single-flake" of a github repo
    github:breakds/flake-example-hello-repeater/single-flake
    ```

3. There are many other variations of specifying a flake as well. See
   [this
   reference](https://github.com/NixOS/nix/blob/master/src/nix/flake.md)
   for a full list of them.
   
You can now test by running the following command from the root of the **local** repo:

```
flake-example-hello-repeater> $ nix flake show .
github:breakds/flake-example-hello-repeater/4959ddd073f9f1ebf7532044d5f3f515470b4d44
└───packages
    └───x86_64-linux
        └───hello-repeater: package 'hello-repeater-1.0.0'
```

or just show the remote repo's flake with

``` bash
$ nix flake show github:breakds/flake-example-hello-repeater
github:breakds/flake-example-hello-repeater/4959ddd073f9f1ebf7532044d5f3f515470b4d44
└───packages
    └───x86_64-linux
        └───hello-repeater: package 'hello-repeater-1.0.0'

```

and if you want to specify the tag/commit as well

``` bash
$ nix flake show github:breakds/flake-example-hello-repeater/4959ddd073f9f1ebf7532044d5f3f515470b4d44
github:breakds/flake-example-hello-repeater/4959ddd073f9f1ebf7532044d5f3f515470b4d44
└───packages
    └───x86_64-linux
        └───hello-repeater: package 'hello-repeater-1.0.0'
```

### Command - `nix build`

The next command is useful to actually build the flake. The syntax to
call that command looks like:

```bash
$ nix build <specify-your-flake>#<specify-the-target>
```

We are already familiar with how to specify the flake. Specifying the
target to build is even simpler - you can just specify the attribute
path under `outputs`. In the above case, the path to the attribute is

``` nix
packages.x86_64-linux.hello-repeater
```

Note that you can only specify an attribute as build target if its
type is derviation. 

So from the root of this repo, you can actually run (using `.` to
specify the flake, and `packages.x86_64-linux.hello-repeater` to
specify the build target) the command below to build the package
`hello-repeater` locally:

``` bash
flake-example-hello-repeater> $ nix build .#packages.x86_64-linux.hello-repeater
```

This command will build the package as `result`, the same as what you
used to see after a `nix-build`. You will find the executable at
`result/bin/hello-repeater`, and you can even run it to see it repeats
the greeting every 5 seconds.

Apparently you can build it from a remote repo as well with

``` bash
$ nix build github:breakds/flake-example-hello-repeater#packages.x86_64-linux.hello-repeater
```

### Save some typing in `nix build`

You actually do not have to specify the full attribute path to the
target when you are running `nix build`. You could actually run the
command below from a 64 bit Linux to achieve the same build:

``` bash
flake-example-hello-repeater> $ nix build .#hello-repeater
```

It actually knows to find the package name under
`packages.<current-system>`, where the current system is evaluated as
the host system, i.e. `x86_64-linux` in this case. This saves a bit of
boiler plate like `packages.x86_64-linux`.

### Implicit build with `defaultPackage`

Sometimes you will want to specify `defaultPackage.<system>` (yes,
default packages are also specified by system) in addition to
`packages`. This tells `nix build` what target to build if you just
specify the flake without any targets.

In the above example we just need to add one line:

``` nix
{
  description = "Package the hello repeater.";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello-repeater =
      let pkgs = import nixpkgs {
            system = "x86_64-linux";
          };
      in pkgs.stdenv.mkDerivation {
        pname = "hello-repeater";
        version = "1.0.0";
        src = pkgs.fetchgit {
          url = "https://github.com/breakds/flake-example-hello-repeater.git";
          rev = "c++-code-alone";
          sha256 = "sha256-/3tT3jBmWLaENcBRQhi2o3DHbBp2yiYsq2HMD/OYXNU=";
        };

        nativeBuildInputs = with pkgs; [
          cmake
        ];
      };

    # Specify the default package
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello-repeater; # <- add this
  };
}
```

Note that how we use `self` to refer to the `outputs` itself and to
refer to the package `hello-repeater` (that is the beauty of `nix`
too). The updated repo can be find at [this git
tag](https://github.com/breakds/flake-example-hello-repeater/tree/add-default-package).

Now you can build the package locally from the repo's root with

``` bash
$ nix build .
```

or remotely with

``` bash
$ nix build github:breakds/flake-example-hello-repeater
```

without having to specify the package explicitly at all.


## Summary

In this post we went over the basics of how to use nix flakes to
package a software into derivation. If you are new to nix flakes, I am
sure you still have many questions. Stay tuned and we will try to
answer them in the following posts of the series. May the flakes be
with you!
