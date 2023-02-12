---
# Documentation: https://sourcethemes.com/academic/docs/managing-content/

title: "VLAN Configuration by Examples"
subtitle: ""
summary: ""
authors: [breakds]
tags: ["networking", "switch", "vlan"]
categories: ["networking", "diy"]
date: 2023-02-11T22:17:04-08:00
lastmod: 2023-02-11T22:17:04-08:00
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

# Why am I writing this?

As I worked on upgrading my home network with a NixOS router, I found myself once again needing to
update the VLAN configuration on my Aruba Instant On 1930 PoE switch. However, I felt hesitant to do
so due to my previous struggles in grasping the concept of VLAN despite reading multiple online
articles.

Fortunately, my friend Hao recommended an informative post on the topic
(https://zhuanlan.zhihu.com/p/545383921) which, combined with an hour of experimentation, finally
allowed me to understand VLAN sufficiently to implement my ideas. In this post, I aim to share my
newfound practical knowledge with examples, hoping to assist others who may have encountered similar
difficulties.

## Example 1: An Unmanaged Switch


A switch, specifically a Layer 2 (L2) switch, is a networking device with several physical ports,
each typically featuring an RJ45 or SFF Ethernet interface. Every port is capable of connecting to a
single device and the switch operates on L2 using MAC addresses.

```
                          Ports
            1   2   3   4   5   6   7   8       
          +---+---+---+---+---+---+---+---+   
          |   |   |   |   |   |   |   |   |   
          +-|-+-|-+-|-+-|-+---+---+---+---+   
            A   B   C   D
```

For example, if you connect devices A, B, C, and D to ports 1, 2, 3, and 4 of an unmanaged switch
(see above), the devices will be interconnected. Device A and B can send packets to each other, as
if they were directly connected with an Ethernet cable.


## Example 2: A Single Virtual Switch (Single VLAN ID)

Packets can be tagged with VLAN IDs. In a managed switch, we can configure the VLANs on each
physical port to change the interconnectivity of it.

Let's assume now the only VLAN IDs that concerns us is VLAN ID = 10. Each physical port can be
configured as either "Tagged" (T), "Untagged" (U) or "Not Participating" (blank). Consider the
example below:

```
                          Ports
            1   2   3   4   5   6   7   8       
          +---+---+---+---+---+---+---+---+   
VLAN 10   | T | U | U |   |   |   |   |   |   
          +-|-+-|-+-|-+-|-+---+---+---+---+   
            A   B   C   D
```

Here port 1 is "Tagged" for VLAN 10, port 2 and 3 are "Untagged" for VLAN 10, and all the other
ports are not participating in the virtual switch VLAN 10. 

1. The device `D` will not be able to send packets to or receive packets from `A`, `B` and `C` via
   the VLAN 10 virtual switch.



