---

title: "Web Development Environment on Specified Version of NodeJS, with Nix"
subtitle: "The nix-shell recipie for web developers"
summary: ""
authors: [breakds, shan]
tags: ["nixos", "nix-shell", "nodejs"]
categories: ["nixos", "dev"]
date: 2020-02-16T15:26:04-08:00
lastmod: 2020-02-16T15:38:04-08:00
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

## The Goal

Web development was fun but setting up the environment can sometimes
be tedious because you might need multiple versions of
[NodeJS](https://nodejs.org/en/) installed (hint: not all npm packages
are compatible with all versions of NodeJS). Many developers uses
[nvm](https://github.com/nvm-sh/nvm) to manage their NodeJS versions,
and it works great.

However, since we are NixOS fans and Nix itself is a great package
management tool, we would like to use it to manage our web development
environment as well.

This article is designed as a tutorial to not only show you the final
configuration, but also how to get ther step by step so that you learn
some tricks along the way.

## Start From A Simple shell.nix

The tool that we will be using today is called
[nix-shell](https://nixos.org/nix/manual/#sec-nix-shell). If you
haven't read it yet, I would highly recommend [Nix
Pill](https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html)'s
chapter on this topic. In one sentence, `nix-shell` can be used to
setup an environment where your packages of choice are installed and
read-to-use, without touching your main environment.

Let's start with a simple `shell.nix` that gives you NodeJS.


#### shell.nix
```nix
let pkgs = import <nixpkgs> {};

in pkgs.mkShell rec {
  name = "webdev";
  
  buildInputs = with pkgs; [
    nodejs yarn
  ];
}    
```

By calling `nix-shell` on this `shell.nix`, you get into a new shell
environment with NodeJS (and [yarn](https://yarnpkg.com/)) installed.
You can easily verify this by

```bash
$ node --version
v12.13.0
```

It gives me `v12.13.0` of NodeJS because I am currently running NixOS
19.09 and this is the default version of NodeJS in it.

## NodeJS 10.x Instead

Everything works fine until we need a NodeJS older than `v12.13.0`. In
this case, if the version you want is `v10.x`, you are lucky because
`<nixpkgs>` has already packaged that for you. Instead of `nodejs`,
you specify explicity `nodejs-10_x` in your `shell.nix`.


#### shell.nix
```nix
let pkgs = import <nixpkgs> {};

in pkgs.mkShell rec {
  name = "webdev";
  
  buildInputs = with pkgs; [
    nodejs-10_x 
    (yarn.override { nodejs = nodejs-10_x })
  ];
}    
```

Oh and if you are using `yarn` like we do, you need to override the
NodeJS package it uses with `yarn.override` so that it'd play nicely
with the older version of `NodeJS`. The default `yarn` uses the
current version of `NodeJS` in `<nixpkgs>`.

## NodeJS, Your OWN Version

The curse of version rises again when some old repo requires `v8.x` of
NodeJS. Unfortunately this version is so old that even `<nixpkgs>`
does not have it (to be fair, it **once** has `nodejs-8_x`, but the
package has been dropped since not long ago).

This is not the end of the world, because as proud NixOS users, we can
always build the package by ourselves. Let's first take a look at how
`v12.x` and `v10.x` are built in `<nixpkgs>`, and it turns out that
they are really simple (`v10.x` as an example):


#### nixpkgs/pkgs/development/web/nodejs/v10.nix
```nix
{ callPackage, openssl, enableNpm ? true }:

let
  buildNodejs = callPackage ./nodejs.nix { inherit openssl; };
in
  buildNodejs {
    inherit enableNpm;
    version = "10.17.0";
    sha256 = "13n5cvb340ba7vwm8il7bjrmpz89h6cibhk9rc3kq9ymdgbnf9j1";
  }
```

All thanks to the this `buildNodejs` helper function. This is the key
to make it possible to build any version of NodeJS.

The first step is to find `buildNodejs` because it is not exposed
directly via `<nixpkgs>`. The above code shows that it is in the file
`pkgs/development/web/nodejs/nodejs.nix`, which is a relative path
w.r.t. `<nixpkgs>`. By calling `callPackage` on it (it is not
necessary but highly recommended to understand how
[callPackage](https://nixos.org/nixos/nix-pills/callpackage-design-pattern.html)
works via another Nix Pill).

As [Lily Ballard](https://discourse.nixos.org/u/lilyball) has pointed
out, below is the best syntax to `callPackage` such file.

```nix
buildNodejs = callPackage <nixpkgs/pkgs/development/web/nodejs/nodejs.nix> {};
```

This makes building `shell.nix` for `v8.x` as simple as

#### shell.nix
```
let pkgs = import <nixpkgs> {};

    buildNodejs = pkgs.callPackage <nixpkgs/pkgs/development/web/nodejs/nodejs.nix> {};
    
    nodejs-8 = buildNodejs {
      enableNpm = true;  # We need npm, do we?
      version = "8.17.0";
      sha256 = "1zzn7s9wpz1cr4vzrr8n6l1mvg6gdvcfm6f24h1ky9rb93drc3av";
    };

in pkgs.mkShell rec {
  name = "webdev";
  
  buildInputs = with pkgs; [
    nodejs-8
    (yarn.override { nodejs = nodejs-8; })
  ];
}    
```

As an usual practice, we need to get the `sha256` for the tarball of
NodeJS. In worst case, You can build it once and wait for the error
message to tell you the correct `sha256`.


## Bring Them All

To be able to switch between multiple versions of NodeJS, the above
`shell.nix` can be extended to include multiple version and the user
can set `nodejs-current` to whichever is needed. 

#### shell.nix

```nix
let pkgs = import <nixpkgs> {};

    buildNodejs = pkgs.callPackage <nixpkgs/pkgs/development/web/nodejs/nodejs.nix> {};

    nodejs-12 = buildNodejs {
      enableNpm = true;
      version = "12.13.0";
      sha256 = "1xmy73q3qjmy68glqxmfrk6baqk655py0cic22h1h0v7rx0iaax8";
    };

    nodejs-10 = buildNodejs {
      enableNpm = true;
      version = "10.19.0";
      sha256 = "0sginvcsf7lrlzsnpahj4bj1f673wfvby8kaxgvzlrbb7sy229v2";
    };

    nodejs-8 = buildNodejs {
      enableNpm = true;
      version = "8.17.0";
      sha256 = "1zzn7s9wpz1cr4vzrr8n6l1mvg6gdvcfm6f24h1ky9rb93drc3av";
    };

    nodejs-current = nodejs-12;

in pkgs.mkShell rec {
  name = "webdev";
  
  buildInputs = with pkgs; [
    nodejs-current
    (yarn.override { nodejs = nodejs-current; })
  ];
}
```

And you can find the full source code that we actually use
[here](https://git.breakds.org/breakds/nixvital/src/branch/master/shells/webdev/shell.nix).
If you are also looking into have a determinsitic web development
environment, we hope this tiny tutortial helps.
