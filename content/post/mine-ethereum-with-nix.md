---
# Documentation: https://sourcethemes.com/academic/docs/managing-content/
# Documentation: https://sourcethemes.com/academic/docs/writing-markdown-latex/

title: "How to Mine Ethereum (ETH) with Nix"
subtitle: ""
summary: "A guide to start mining Eth immediately with Nix."
authors: [breakds]
tags: ["ethminer", "nix"]
categories: ["nixos", "ethereum", "mining"]
date: 2020-12-20T10:59:00-08:00
lastmod: 2020-12-20T11:30:00-08:00
featured: true
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

## Background

The price of cryptocurrency is soaring again recently, and as an owner
of several Nvidia GPUs, I thought it would be fun to start mining
them. I consulted my college roommate who is an expert in
cryptocurrency mining. He recommends mining
[ETH](https://ethereum.org/en/eth/), which is the cryptocunrrency of
the [Ethereum](https://ethereum.org/). 


Note that whether it is profitable depends on your GPU, your
electricity cost, and the price of ETH. In my case, I have a [Geforce
GTX 1080
Ti](https://www.nvidia.com/en-sg/geforce/products/10series/geforce-gtx-1080-ti/)
and lives in San Jose (high power cost). This makes mining ETH merely
profitable. However, my [Geforce RTX
3080](https://www.nvidia.com/en-us/geforce/graphics-cards/30-series/rtx-3080/)
would definitely make it a profitable business.


Start mining is super simple with
[Nix](https://github.com/NixOS/nixpkgs). I think the monst important
reason that prevents me from becoming a miner many years ago is how
difficult it seems to deploy the miner. Had I known Nix then, I am
probably already rich now (Stop day dreaming!). 


## Preparation

You need a [wallet](https://ethereum.org/en/wallets/find-wallet/) to
store the ETH you mine. I am using
[MEW](https://www.myetherwallet.com/) but you can choose whatever you
like. The ETH in one wallet can be transferred to another wallet with
no restriction.


A wallet here is basically a private key and a public key. In mining
you give the pool the public key so that the pool knows where to send
the money (ETH) you earn to.


## Run ethminer

The only thing you need is your GPU and a tool called
[ethminer](https://github.com/ethereum-mining/ethminer). Compiling it
from source is challenging if you are not familiar with C++ and CMake.
The good news is that you don't have too, because nixpkgs already
[have
it](https://search.nixos.org/packages?channel=20.09&from=0&size=30&sort=relevance&query=ethminer)!
This means that installing it is as simple as putting it in your
`nix-shell` or `NixOS` configuration, and profit (literally)!


One hiccup is that currently `ethminer` is marked as broken, but I
have submitted a [PR to fix
it](https://github.com/NixOS/nixpkgs/pull/107239). Before the PR is
merged and backported, the workaround is to put this in your
`shell.nix` or `NixOS` configuration:

#### shell.nix
```nix
...
buildInputs = [
  ethminer.override { stdenv = self.clangStdenv; }
]
...
```

#### or in your NixOS configuration
```nix
environment.systemPackages = [
  ethminer.override { stdenv = self.clangStdenv; }
];
```

Once your have this added to your `NixOS` configuration (after
`nixos-rebuild switch`) or when you are in your `nix-shell`, a single
line command is all you need to start.

An example command looks like this

```bash
$ ethminer --farm-recheck 200 --cuda --pool stratum1+tcp://0x0123456789abcdef0123456789abcdef01234567.my1080ti@us2.ethermine.org:4444
```

To explain each parameter

1. `--farm-recheck 200` is to set the interval (`200 ms` in this case)
   of checking with the server whether the problem your miner is
   solving right now has been marked as stale. Solving a stale problem
   does not generate profit.
2. `--cuda` tells the miner to use the CUDA + Nvidia GPU for mining
3. `--pool stratum1+tcp://<your wallet>.<name of your
   worker>@us2.ethermine.org:4444` seems a little complicated, but it
   describes how to setup the wallet and the pool your are joining.
   * In this case, I am using `ethermine.org`'s US West server, with
     address `us2.ethermine.org:4444`.
   * You wallet's public key needs to be there as `<your wallet>`, so
     that the pool knows how to pay you.
   * `<name of your worker>` is just a name you give to this worker.
     This is to distinguish it from the others if you have multiple
     worker.
     
When the program runs scuccessfully, you will see logs on the screen similar to 

```
Dec 20 11:47:58 samaritan ethminer-start[13097]:  m 11:47:58 .ethminer-wrapp 0:49 A23 31.72 Mh - cu0 31.72
Dec 20 11:47:58 samaritan ethminer-start[13097]:  i 11:47:58 .ethminer-wrapp Job: ad0d935e… block 11492204 us2.ethermine.org [172.65.226.101:4444]
Dec 20 11:48:01 samaritan ethminer-start[13097]:  i 11:48:01 .ethminer-wrapp Job: 058942cb… block 11492204 us2.ethermine.org [172.65.226.101:4444]
Dec 20 11:48:03 samaritan ethminer-start[13097]:  m 11:48:03 .ethminer-wrapp 0:49 A23 31.66 Mh - cu0 31.66
Dec 20 11:48:05 samaritan ethminer-start[13097]:  i 11:48:05 .ethminer-wrapp Job: c300a280… block 11492204 us2.ethermine.org [172.65.226.101:4444]
Dec 20 11:48:06 samaritan ethminer-start[13097]:  i 11:48:06 .ethminer-wrapp Job: 42ce69d5… block 11492205 us2.ethermine.org [172.65.226.101:4444]
Dec 20 11:48:07 samaritan ethminer-start[13097]:  i 11:48:07 .ethminer-wrapp Job: 5c997035… block 11492205 us2.ethermine.org [172.65.226.101:4444]
Dec 20 11:48:08 samaritan ethminer-start[13097]:  m 11:48:08 .ethminer-wrapp 0:49 A23 32.05 Mh - cu0 32.05
Dec 20 11:48:11 samaritan ethminer-start[13097]:  i 11:48:11 .ethminer-wrapp Job: 51424d25… block 11492205 us2.ethermine.org [172.65.226.101:4444]
Dec 20 11:48:13 samaritan ethminer-start[13097]:  m 11:48:13 .ethminer-wrapp 0:50 A23 31.96 Mh - cu0 31.96
```

Where the number `32.05 Mh` is the hash rate.

Once your miner is up and running, you can see how it performs by
visiting https://ethermine.org/ and put your wallet address in the
search bar.

Just kill the program if you want to use your GPU for some Gaming or
training some neural network, and re-run the program after that.

If this is already how you want your miner to run, you can stop
reading here.

## NixOS Service

If you are running NixOS, where this can be further simplified. Since
nixpkgs alreayd have the [ethminer service
defined](https://search.nixos.org/options?channel=20.09&from=0&size=30&sort=relevance&query=ethminer), you can just add the following to your NixOS configuration


```nix
  # Eth Mining
  services.ethminer = {
    enable = true;
    recheckInterval = 200;
    toolkit = "cuda";
    wallet = "0x0123456789abcdef0123456789abcedf0.my1080Ti";  # Your own wallet and worker name
    pool = "us2.ethermine.org";
    stratumPort = 4444;
    maxPower = 300;  # Use at most 300 Watts
    registerMail = "";
    rig = "";
  };
```

And after `nixos-rebuild switch` your service should be up and running
with systemd! To temporarily stop it and resume it, do

```
systemctl stop ethminer.service
```

and

```
systemctl start ethminer.service
```

To check how its status

```
systemctl status ethminer.service
```

Enjoy mining!
