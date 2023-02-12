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

Fortunately, my friend Hao recommended an informative [post on the topic](https://zhuanlan.zhihu.com/p/545383921) which, combined with an hour of experimentation, finally
allowed me to understand VLAN sufficiently to implement my ideas. In this post, I aim to share my
newfound practical knowledge with examples, hoping to assist others who may have encountered similar
difficulties.

**Disclaimer**: Not being a network engineer, my understanding and explanation of VLANs are based on a simplified mental model. While I believe that this model is both easy to understand and accurate enough for practical use, it may not encompass all technical intricacies and complexities of the concept.

# Example 1: An Unmanaged Switch


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

For example, if you connect devices `A`, `B`, `C`, and `D` to ports 1, 2, 3, and
4 of an unmanaged switch (see above), the devices will be interconnected. Device
`A` and `B` can send packets to each other, as if they were directly connected with
an Ethernet cable.


When `A` sends a packet to port 1, it **enters** the switch, and when the packet
reaches `B` via port 2, it **leaves** the switch. In this post, the statement
"`A` and `B` can send packets to each other" means that the packet is not
dropped upon entering the switch via port 1 or upon leaving the switch via port
2 **VLAN rules**.


## Tagged Packet and Untagged Packet

A packet can be tagged with a VLAN ID, which is just an integer. A packet that
has a VLAN ID is called a "tagged packet", and a packet that does not have a
VLAN ID is called an "untagged packet".

# Example 2: Managed Switch with Single VLAN

In this example, let's assume there is only one VLAN ID `10`, and a packet can
either be tagged with `VLAN 10` or untagged.

In a managed switch, each physical port can be configured as "Tagged" (T),
"Untagged" (U), or "Not Participating" (blank) with respect to `VLAN 10`. By
changing the interconnectivity of the ports for a specific VLAN, we can form a
virtual switch for that VLAN. Consider the example below:

```
                          Ports
            1   2   3   4   5   6   7   8       
          +---+---+---+---+---+---+---+---+   
VLAN 10   | T | U | U |   |   |   |   |   |   
          +-|-+-|-+-|-+-|-+---+---+---+---+   
            A   B   C   D
```            

Here, ports 1, 2, and 3 form a virtual switch for `VLAN 10`, with port 1 being
"Tagged" for `VLAN 10`, and ports 2 and 3 being "Untagged" for `VLAN 10`. We can
temporarily ignore the other ports, as they are not participating in the virtual
switch for `VLAN 10`.

The rules for the virtual switch are straightforward. We only need to consider
the behavior of the packet when it enters and leaves the virtual switch.

- If a physical port is "Tagged" for VLAN 10:
  - It only allows packets tagged with VLAN 10 to enter.
  - When a packet leaves this port, it will be tagged with VLAN 10.
- If a physical port is "Untagged" for VLAN 10:
  - It only allows untagged packets to enter.
  - When a packet leaves this port, it will be untagged, regardless of whether
    it was tagged with VLAN 10 before.
  
With these rules in mind, we can understand the behavior of the packet in
different scenarios. For example:

1. If device `A` sends an untagged packet to port 1, it will be dropped because
   port 1 is a tagged port for `VLAN 10` and only accepts packets tagged with
   `VLAN 10`.
2. If device `A` sends a packet tagged with `VLAN 10` to port 1, the packet will
   enter the switch and reach devices `B` and `C` via ports 2 and 3 as untagged
   packets. The tag `VLAN 10` will be stripped when the packet leaves ports 2
   and 3 because they are untagged ports.
3. If device `B` sends an untagged packet to port 2, it will be accepted and
   delivered to device `A` as a packet tagged with `VLAN 10`, and to device `C`
   as an untagged packet.
4. If device `C` sends a packet tagged with `VLAN 10` to port 3, it will be
   dropped because port 3 only accepts untagged packets.


# Example 3: Managed Switch with 2 VLANs

Things become more interesting when there are multiple VLANs. This is also the
reason why people create VLANs: to form many virtual (logical) switches out of a
single physical switch device. The seemingly complicated rules are also not
created for dropping packets. They are here to give the devices options to
choose which virtual switch it want a packet to be sent to.

In this example, let's consider a switch that is configured to form two virtual
switches, one for `VLAN 10` and one for `VLAN 20`.

```
                          Ports
            1   2   3   4   5   6   7   8
          +---+---+---+---+---+---+---+---+
VLAN 10   | T | U | U |   |   |   |   |   |
          +---+---+---+---+---+---+---+---+
VLAN 20   |   |   | T | U |   |   |   |   |
          +---+---+---+---+---+---+---+---+
          |   |   |   |   |   |   |   |   |
          +-|-+-|-+-|-+-|-+---+---+---+---+
            A   B   C   D
```

We can treat the switch as two separate virtual switches: the virtual switch for
`VLAN 10` consists of ports 1, 2, and 3, and the virtual switch for `VLAN 20`
consists of ports 3 and 4. Devices `A` and `B` are both only connected to the
virtual switch for VLAN 10, and can only communicate with each other and with
other devices on that same virtual switch. Device `D` is only connected to the
virtual switch for `VLAN 20`, and can only communicate with other devices on
that virtual switch. Device `C` is connected to both virtual switches through a
shared physical port, port 3.

When each device sends packets, it can now decide which virtual switch to send
them to by tagging the packets accordingly. Once a packet enters a virtual
switch, the rules that control how it leaves the switch **remain the same**.

1. Device `A` can only send packets to the virtual switch for `VLAN 10`, since
   that is the only virtual switch that port 1 participates. In order to send
   packets to the virtual switch for `VLAN 10`, device `A` must tag the packets
   with `VLAN 10`, since port 1 is a "tagged" port for that virtual switch.
2. Similarly, device `B` can only send packets to the virtual switch for `VLAN
   10`, but since port 2 is an "untagged" port for that virtual switch, device
   `B` must send untagged packets to that virtual switch. Any other types of
   packets sent from device B will be dropped.
3. Similarly, device `D` can only send packets to the virtual switch for `VLAN
   20`, and the packets must be untagged to avoid being dropped.
4. Device `C` can choose to send packets to either virtual switch by tagging the
   packets appropriately. Specifically, it can send untagged packets to the
   virtual switch for `VLAN 10`, or packets tagged with `VLAN 20` to the virtual
   switch for `VLAN 20`. Any other types of packets sent from device `C` will be
   dropped.

# Example 4: Sharing Two Physical Ports

Now, let's put what we've learned into practice! Consider the following slightly
different example below:

```
                          Ports
            1   2   3   4   5   6   7   8
          +---+---+---+---+---+---+---+---+
VLAN 10   | T | U | U | T |   |   |   |   |
          +---+---+---+---+---+---+---+---+
VLAN 20   |   |   | T | U |   |   |   |   |
          +---+---+---+---+---+---+---+---+
          |   |   |   |   |   |   |   |   |
          +-|-+-|-+-|-+-|-+---+---+---+---+
            A   B   C   D
```

**Question**: If device `C` want to send a packet to device `D`, what can it do?

Device `C` is connected to port 1 and device `D` is connected to port 4. Both
port 3 and 4 participates in both virtual switches. This means that device `C`
has two choices:

1. Device `C` can send an untagged packet to device `D` via the virtual switch
   for `VLAN 10`. This is possible because port 4 is also a member of the
   virtual switch for `VLAN 10`. However, device `D` will actually receive the
   packet tagged with `VLAN 10`, because port 4 is "tagged" for `VLAN 10`.
2. Alternatively, device `C` can send a packet tagged with `VLAN 20` to device
   `D` via the virtual switch for `VLAN 20`. However, device `D` will actually
   receive the packet untagged, because port 4 is "untagged" for VLAN 20.
   
In this way, device `C` has the flexibility to decide not only which virtual
switch to use but also how the packet should be tagged upon reaching device `D`.


# One Extra Rule: Each Physical Port Can Only Be "Untagged" Once

The following configuration is **invalid** as port 3 is untagged for both `VLAN
10` and `VLAN 20`. Why?

```
                          Ports
            1   2   3   4   5   6   7   8
          +---+---+---+---+---+---+---+---+
VLAN 10   | T | U | U |   |   |   |   |   |
          +---+---+---+---+---+---+---+---+
VLAN 20   |   |   | U | U |   |   |   |   |
          +---+---+---+---+---+---+---+---+
          |   |   |   |   |   |   |   |   |
          +-|-+-|-+-|-+-|-+---+---+---+---+
            A   B   C   D
```

Because packets are not allowed to be duplicated and sent to multiple virtual
switches. Consider the case when device `C` sends an untagged packet to port 3.
It is **undecideable** whether it should go into the switch for `VLAN 10` or the
switch for `VLAN 20`.

Therefore, a configuration where a physical port participates in multiple
virtual switches as an untagged port is not valid.

# Final Example: Designing an One Armed Router

A common use case for VLANs is when you need to use a computer with a single
ethernet port as your router. Normally, a router should have at least two ports,
one for the uplink (the modem that your ISP provides) and one for the downlink
(the rest of your home devices, usually via a switch). In this example, we'll
assume you want to connect two devices: a WiFi access point and a PC.



Normally a router should have at least two ports: one for connecting the uplink
(i.e. the modem that your ISP gives you) and the downlink (the rest of your home
devices, usually via a switch). In this example, let's say we want to connect
two home devices: A WiFi AP and a PC.

To do this, you will need two switches and four ports. We can use `VLAN 10` to
connect the router and the uplink modem, and `VLAN 20` to connect the router,
WiFi AP, and PC.

```
                          Ports
            1   2   3   4   5   6   7   8
          +---+---+---+---+---+---+---+---+
VLAN 10   | U | T |   |   |   |   |   |   |
          +---+---+---+---+---+---+---+---+
VLAN 20   |   | T | U | U |   |   |   |   |
          +---+---+---+---+---+---+---+---+
          |   |   |   |   |   |   |   |   |
          +-|-+-|-+-|-+-|-+---+---+---+---+
          Modem |   |   |
                |   |   |
              Router|   PC 
                    |
                  WiFi AP
```

With this configuration, you can use the PC and WiFi AP simultaneously without
needing a multi-port router.


# Bonus Example: Adding Multiple WiFi Networks with A Single WiFi AP

In my case, I also need to set up 3 separate WiFi networks for personal devices,
IoT devices (i.e. smart home stuff) and for guests on a single WiFi AP. By using
VLANs to separate the personal, IoT, and guest networks, we can ensure that
devices on each network are isolated from each other, providing an extra layer
of security for our home network.

Fortunately my [WiFi
AP](https://www.amazon.com/Aruba-Instant-Indoor-Access-Point/dp/B07V3J5TXJ)
supports VLAN tagging so that I can create `VLAN 30` and `VLAN 40` for the IoT
devices and guest network. This also means adding two more virtual switches to
connect the router and the WiFi AP.

A revised diagram is shown below.

```
                          Ports
            1   2   3   4   5   6   7   8
          +---+---+---+---+---+---+---+---+
VLAN 10   | U | T |   |   |   |   |   |   |   (Uplink)
          +---+---+---+---+---+---+---+---+
VLAN 20   |   | T | U | U |   |   |   |   |   (Personal Network)
          +---+---+---+---+---+---+---+---+
VLAN 30   |   | T | T |   |   |   |   |   |   (IoT Network)
          +---+---+---+---+---+---+---+---+
VLAN 40   |   | T | T |   |   |   |   |   |   (Guest Network)
          +---+---+---+---+---+---+---+---+
          |   |   |   |   |   |   |   |   |
          +-|-+-|-+-|-+-|-+---+---+---+---+
          Modem |   |   |
                |   |   |
              Router|   PC 
                    |
                  WiFi AP
```

Thank you for reading and hope this post helps you!

# Acknowledgement

Special thanks to [ChatGPT](https://chat.openai.com/chat), an AI language model
trained by OpenAI, for helping me revise and improve this post.
