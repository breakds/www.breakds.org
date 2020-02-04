---
# Documentation: https://sourcethemes.com/academic/docs/managing-content/

title: "Declarative Docker Container Service in NixOS"
subtitle: "Replace docker-compose with Nix"
summary: ""
authors: [breakds]
tags: ["docker", "service", "filerun", "nixos"]
categories: ["nixos", "docker"]
date: 2020-02-10T14:10:04-08:00
lastmod: 2020-02-04T09:37:04-08:00
featured: false
draft: true

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

## Why Declarative Configurations?

One of the biggest convenience you have in NixOS is that many of the
services you want to run are already coded as a "service". This means
that you can easily spin up a service like openssh with

```nix
services.openssh.enable = true;
```

In fact, you can find a whole lot of such predefined services with
`services.` prefix in the [NixOS
Options](https://nixos.org/nixos/options.html#services.) site.

I was able to use either predefined services or customized service to
bring up gitea, hydra and even the website itself. 
