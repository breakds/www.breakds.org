+++
title = "The Intuitive Policy Gradient"
description = "Notes on deriving the policy gradient theorem"
date = 2025-02-08
draft = false
[taxonomies]
tags = ["policy gradient", "reinforcement learning", "machine learning"]
[extra]
keywords = "policy gradient, rl, reinforcement learning, machine learning"
toc = true
series = ""
math = true
math_auto_render = true
+++

This post talks about the policy gradient theorem, which summarizes my attempt to derive it in an intuive approach. This is based on the derivation from Richard Sutton's RL book, with a focus on its application in deep reinforcement learning. This assumes basic knowledge about Markov decision process (MDP), reinforcement learning (RL) and neural networks. You should be familar with the concept of policy and value function.

# The Motivation

**Question**: What problem does the policy gradient theorem try to solve?

Let's talk about it.

A straight-forward thinking on how to solve the RL problem is modeling the policy as a neural network parametrized by $\theta$. 
Given a state $s$ as input, the neural network should output the probability distribution of the actions.

$$
\pi(a|s;\theta) \text{ where } \sum_a \pi(a|s;\theta) = 1
$$

We hope that after training, such policy $\pi(a|s;\theta)$ will be very high if $a$ is optimal. 
Under this formulation, it appears that as long as we can find a good loss function, we can just backpropagate, find a (near) optimal $\theta$ and profit.

Except for that, there is no straight-forward way to find such a loss function. This is because unlike supervised learning, in MDP settings we are only 
getting indirect signals from the rewards. But fear no more! The Policy Gradient theorem is our ticket to find the right loss function, and with that
loss function we can then take gradients w.r.t. $\theta$.

# The Problem Setup

Let's setup the RL problem with terminologies first. We are trying to find the optimal policy $\pi(a|s;\theta)$ for an MDP with an underlying transition function

$$
p(s_{t+1}, r_t|s_t, a_t) \text{ s.t. } \sum_{s_{t+1}, r_t} p(s_{t+1}, r_t|s_t, a_t) = 1
$$

The meaning of the above is that standing at state $s_t$, if we take an action $a_t$, there will be a probability of $p(s_{t+1}, r_t|s_t, a_t)$ to transtion to the state $s_{t+1}$,
with a reward of $r_t$. Here $r_t$ means that this reward is for the action taken at step $t$. 

There are times when we do not care about the reward but only the state transition. In such cases we are looking at the **state transition function**

$$
p(s_{t+1} | s_t, a_t) = \sum_{r_t} p(s_{t+1}, r_t|s_t, a_t)
$$

It is also obvious that the state transition function sums to 1, i.e., $\sum_{s_{t+1}} p(s_{t+1} | s_t, a_t) = 1$.

It is assumed that although we know the underlying transition function exists, we **do not have direct access** to them due to the fact that there are usually a lot of 
actions (a large action space) and/or a lot of states (a large state space).

# (Taking) The Policy's Graident 

## Loss Function Candidate: The Value Function

For any state $s$, the policy $\pi(a|s;\theta)$ will induce a state value function

$$
V^\pi(s) = \mathbb{E}_{a \sim \pi(\cdot|s;\theta)}[q^\pi(s, a)]
$$

Here,

1. $V^\pi(s)$ is the $\pi$-induced **state value function**. It is the **expected** total return if we stick to the policy $\pi(a|s;\theta)$, starting from a specific state $s$;
2. similar, $q^\pi(s, a)$ is the $\pi$-induced **state-action value function**. It is the **expected** total return if we stick to the policy $\pi(a|s;\theta)$, starting from a specific state $s$ and taking $a$ as the next action.

Note that both $V^\pi(s)$ and $q^\pi(s, a)$ depend on $\theta$. Since the end goal of solving the RL problem here is just to **maximize** $V^\pi(s)$, we can't help but think:
Can we just use $V^\pi(s)$ as the loss fucntion? Unfortunately no, because we do not have a close form representation of $V^\pi(s)$ either. 

However, we can still try to take the gradient of $V^\pi(s)$ w.r.t. $\theta$ to see how we can actually **maximize** $V^\pi(s)$. Spoiler: we will actually find something useful!

## The Gradient

By definition above, we have

$$
\begin{align*}
\nabla_\theta V^\pi(s) &= \nabla_\theta \mathbb{E}_{a \sim \pi(\cdot | s; \theta)}\left[ q^\pi(s, a)\right] \\\\
&= \stackrel{\scriptsize\text{expand $\mathbb{E}$ because its distribution depends on $\theta$, the one we are taking gradient on}}{\nabla _\theta \left(  \sum_a \pi(a|s;\theta) \cdot q^\pi(s, a)\right)} \\\\
&= \left( \sum_a \nabla _\theta \pi(a|s; \theta) \cdot q^\pi(s, a)\right) + \left( \sum_a \pi(a|s; \theta) \cdot \nabla _\theta q^\pi(s, a)\right)
\end{align*}
$$




