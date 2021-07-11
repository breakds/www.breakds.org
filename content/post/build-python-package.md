---
# Documentation: https://sourcethemes.com/academic/docs/managing-content/

title: "On Packaging Python Application with Nix"
subtitle: ""
summary: ""
authors: [breakds]
tags: ["python", "package", "nixos"]
categories: ["nix", "python", "dev"]
date: 2021-07-10T10:24:04-08:00
lastmod: 2021-07-10T18:16:04-08:00
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

# Background

It is usually quite easy to package python modules with Nix. Most of the time, all you need to do is list the dependencies. Still, I have run across challenges that take a long time to solve on a few instances, and I would like to take this opportunity to document and share the solutions. I hope this information i useful to anyone that package Python libraries or applications.

# The FAQs

## How to test build a python module packaged as a Nix derivation?

The short ansewr is, use [nix-build](https://nixos.org/manual/nix/unstable/command-ref/nix-build.html). But what to pass as arguments to `nix-build` depends on how you organize your derviation.

The common case is that you write your derviation as a function. For example, suppose I have packaged `gdown` with the following `gdown.nix`

#### gdown.nix
```nix
{ lib
, buildPythonApplication
, fetchPypi
, filelock
, requests
, tqdm
, setuptools
, six
}:

buildPythonApplication rec {
  pname = "gdown";
  version = "3.13.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "d5f9389539673875712beba4936c4ace95d24324953c6f0408a858c534c0bf21";
  };

  propagatedBuildInputs = [ filelock requests tqdm setuptools six ];

  meta = with lib; {
    description = "A CLI tool for downloading large files from Google Drive";
    homepage = "https://github.com/wkentaro/gdown";
    license = licenses.mit;
    maintainers = with maintainers; [ breakds ];
  };
}
```

In order to build this derivation, I need to supply the arguments to the function, which includes `flilelock` (another python module drivation), `buildPythonApplication` (a helper function) and so on. One could find all of them in `python3Packages` (to be more specific, `pkgs.python3Packages`). Therefore, the way I test build the above derivation would be:

```bash
$ nix-build -E 'with import <nixpkgs> {}; pkgs.python3Packages.callPackage ./gdown.nix {}'
```

If the build is successful, the resulting package will appear in your `/nix/store`. Also `nix-build` will kindly create a symbolic link in your current directory called `result` to the package in the `/nix/store` so you do not have to navigate through it to find your package.

## How to build a package if it is provided as wheel?

[PyPI](https://pypi.org/) used to offer all the python packages as source code. As seen in the above example, `buildPythonPackage`, `buildPythonApplication` and `fetchPyi` work pretty well with that.

However, there is a trend that more and more python packages are distributed as [Python Wheels](https://pythonwheels.com/), usually because they relies on extensions written in C and C++ and the authors choose to distribute compiled artifacts.

It is still recommended to package your python modules directly from the source because compiling from the source gives you (and the users of the the module) the most flexibility w.r.t. architectures and systems. However, in some cases you might still want to package a python module from the wheels because:

1. You only care about a certain architecture and a certain system (usually `Linux` + `x86_64`), and/or
2. Packaging from source requires significantly more effort

An example would be packaging [rectangle-packer](https://pypi.org/project/rectangle-packer/). In the following derivation I packaged it with the wheels from Pypi. Note that the wheels is very explicit about python versions, so you have to explicitly specify the URL to fetch based on that. I used `isPy37`, `isPy38` and `isPy39` to choose the right URL.

#### rectangle-packer.nix

```nix
{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, isPy39
, isPy38
, isPy37 }:

assert (isPy39 || isPy38 || isPy37);

let urls = {
      "2.0.1" = {
        py37 = {
          url = https://files.pythonhosted.org/packages/62/24/9ddaf1d3e0e88d9866a0d67ad5d3c9d3f82ea5f819435d76f6654e1fddf2/rectangle_packer-2.0.1-cp37-cp37m-manylinux2010_x86_64.whl;
          sha256 = "0gfcmwr7k1ifrmk7mwzfzyp8hh163mrjik572xn1d4j53l78qq5h";
        };

        py38 = {
          url = https://files.pythonhosted.org/packages/a5/83/13f95641e7920c471aff5db609e8ccff1f4204783aff63ff4fd51229389e/rectangle_packer-2.0.1-cp38-cp38-manylinux2010_x86_64.whl;
          sha256 = "00z2dnjv5pl44szv8plwlrillc3l7xajv6ncdf5sqxkb0g0r3kc6";
        };

        py39 = {
          url = https://files.pythonhosted.org/packages/c6/f3/2ca57636419c42b9a698a6378ed99a61bcff863db53a1ec40f0edd996099/rectangle_packer-2.0.1-cp39-cp39-manylinux2010_x86_64.whl;
          sha256 = "1kxy7kqs6j9p19aklx57zjsbmnrvqngs6zdi2s8c4qvshm3zzayk";
        };
      };
    };
in buildPythonPackage rec {
  pname = "rectangle-packer";
  version = "2.0.1";
  format = "wheel";

  src = builtins.fetchurl (with urls."${version}"; if isPy37 then py37 else if isPy38 then py38 else py39);

  propagatedBuildInputs = [ setuptools ];

  meta = with lib; {
    description = ''
      Given a set of rectangles with fixed orientations, find a bounding box of 
      minimum area that contains them all with no overlap.
    '';
    homepage = "https://github.com/Penlect/rectangle-packer";
    license = licenses.mit;
    maintainers = with maintainers; [ breakds ];
  };
}
```

Aside from the obvious `format = "wheel"` here, there is another caveats that I have to point out. Building wheels requires the use of `src` and it does not recognize `srcs` at all.

## The package is built successfully, but it panics about not finding "libstdc++.so.6" when being imported?

This usually happens as an side effect coming from packaging a wheel-based python module. The pre-compiled artifacts in the wheel have pretty strong assumptions on where to find the shared libraries (e.g. `/usr/lib`) but in Nix have them in `/nix/store` instead. This problem can happen more often if the user of your python module runs NixOS, which does not even have a `/usr/lib` at all.

I posted [this question](https://discourse.nixos.org/t/packaging-python-packages-which-depends-on-libstdc-so-6/12532) on [NixOS Dicourse](https://discourse.nixos.org/t/packaging-python-packages-which-depends-on-libstdc-so-6/12532) and **brogos** kindly shared a solution that works great.

The trick is to add a step in building the derivation called "Patch ELF", which automatically fixes the issue of finding shared objects in `/nix/store`. Addding such step turns out to be very simple in 2 steps:

1. Add `autoPatchelfHook` to `nativeBuildInputs`
2. Add the missing libraries to `buildInputs`, and for `libstdc++.so.6` it is `stdenv.cc.cc.lib`.

As you can see the post, an example derviation that packages `blspy` looks like

#### blspy.nix

```nix
in buildPythonPackage rec {
  pname = "blspy";
  version = "1.0.1";

  format = "wheel";

  src = builtins.fetchurl {
    inherit url;
    sha256 = "1mms0by14v7lxcskm0x5r3gyfw1ixyaf00h6l1ld65zsp1pp0ys9";
  };

  buildInputs = [ stdenv.cc.cc.lib ];

  propagatedBuildInputs = [ setuptools ];

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];  

  meta = with lib; {
    description = "BLS Signatures implementation";
    homepage = "https://github.com/Chia-Network/bls-signatures";
    license = licenses.asl20;
    maintainers = with maintainers; [ breakds ];
  };
}
```

## What is the difference between `buildPythonPackage` and `buildPythonApplication`?

As [Jon Ringer](https://github.com/jonringer) pointed out, just look at how the two are defined:

```nix
  buildPythonPackage = makeOverridablePythonPackage ( makeOverridable (callPackage ../development/interpreters/python/mk-python-derivation.nix {
    inherit namePrefix;     # We want Python libraries to be named like e.g. "python3.6-${name}"
    inherit toPythonModule; # Libraries provide modules
  }));

  buildPythonApplication = makeOverridablePythonPackage ( makeOverridable (callPackage ../development/interpreters/python/mk-python-derivation.nix {
    namePrefix = "";        # Python applications should not have any prefix
    toPythonModule = x: x;  # Application does not provide modules.
  }));
```

Both of them are just sepciailization of `mk-python-derivation.nix`, where `buildPythonApplication` did a bit more to **NOT** propagate the python modules.

# Want more?

Leave a comment if you run into some other problems, and I can potentially add them in a later revision of the post. Happy hacking!
