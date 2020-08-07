---
# Documentation: https://sourcethemes.com/academic/docs/managing-content/
# Documentation: https://sourcethemes.com/academic/docs/writing-markdown-latex/

title: "Minimalist's Kalman Filter Derivation, Part I"
subtitle: "1D Kalman Filter"
summary: "Demonstrate the derivation of Kalman Filter in its simplest form: 1 dimensional case."
authors: [breakds]
tags: []
categories: ["robotics", "control", "statistics"]
date: 2020-08-03T20:00:15-08:00
lastmod: 2020-08-03T20:00:15-08:00
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

## Motivation

State estimation has many applications in general robotics, for
example autonomous driving localization and environment prediction.
Kalman filter is a classical yet powerful algorithm that tackles such
problem beautifully. Although there are already many articles,
textbooks and papers on how to derive the algorithm, I found most of
them too heavy on the theoretical side and might be hard for a
first-time learner who comes from an engineering background to follow.
Therefore, I would shamelessly attempt to fill this hole with a series
of posts.

This is going to be the first post of the series that only focuses on
the 1 dimensional case. Future posts will talk about the multi-variate
version of Kalman filter.

**Spoiler:** there will be a lot of math equations. But rest assured,
nothing will exceed the level of basical calculus arithmetics.

## Single Step Prediction

Let's say we have a one dimensional linear Markovian System, whose
transition function is know. This means

1. The state of the system can be represented as a single scalar.
   Let's denote it as $x$.
2. The transition function is a linear function, where the next state
   only depends on the current state. Therefore we can write the
   transition function as 
   
   $$
   x_{t+1} = a  \cdot x_t
   $$

Suppose you have an estimation of $x_t$ in the form of a Gaussian
distribution

$$
x_t \sim N(\hat{x}_t, \sigma_t^2)
$$

Based on that, what is your best-effort guess about the next state
$x_{t+1}$? First of all, the reason that we **can** make such a
prediction of the next state is because the transition function
actually reveals the relationship between $x_t$ and $x_{t+1}$, which
happens to be **linear** in this case. I know that **intuitively**,
you would guess the answer immediately:

$$
x_{t+1} \sim N(a\hat{x}_t, a^2\sigma_t^2)
$$

And that is the correct answer. But how do you prove that? Or more
generally, if we have a random variable $X \sim N(\mu, \sigma^2)$, can
we prove that another random variable that satisfies $Y = aX$ actually
follows the distribution $Y \sim N(a\mu, a^2\sigma^2)$?

Let 

$$
\phi(x) = \frac{1}{\sqrt{2\pi}} \cdot e^{-\frac{1}{2}x^2}
$$

be the **pdf** (probability density function) of a standard gaussian
distribution $N(0, 1)$. It is easy to derive that the **pdf** of a
general gaussian distribution $N(\mu, \sigma^2)$ that $X$ follows
would be

$$
f_X(x) = \frac{1}{\sqrt{2\pi}\sigma} \cdot e^{-\frac{1}{2\sigma^2}(x-\mu)^2} = \frac{1}{\sigma}\phi \left( \frac{x - \mu}{\sigma} \right)
$$

Using the trick called [differential form](https://en.wikipedia.org/wiki/Differential_form), the probability of $X$ taking a specific value $x$ is[^1] 

$$
\mathbb{P} [X = x] = f_X(x) \mathrm{d}x = \frac{1}{\sigma}\phi \left( \frac{x - \mu}{\sigma} \right) \mathrm{d} x
$$

Okay, so what does **pdf** of $Y$ (i.e. $\mathbb{P}(Y = y)$) look
like? It turns out that we can easily derive that with a bit
transformation:

$$
\begin{eqnarray}
\mathbb{P} \left[ Y = y \right] &=& \mathbb{P} \left[ X = \frac{y}{a} \right] \\\\\\
&=& f_X \left(\frac{y}{a}\right) \mathrm{d}x \\\\\\
&=& f_X \left(\frac{y}{a}\right) \frac{\mathrm{d}y}{a} \\\\\\
&=& \frac{1}{\sigma}\phi \left( \frac{\frac{y}{a} - \mu}{\sigma} \right) \frac{\mathrm{d}y}{a} \\\\\\
&=& \frac{1}{a\sigma}\phi \left( \frac{y - a\mu}{a\sigma} \right) \mathrm{d}y
\end{eqnarray}
$$

This basically shows that $Y$'s **pdf** is nothing but the **pdf** of
$N(a\mu, a^2\sigma^2)$, hence conclude the proof.

[^1]: An intuitve perspective here that helps understanding that is $f_X(x) \mathrm{d}x$ is actually the area, whose **fundamental unit** is probability!

The above proved conclusion enables us to solve the prediction problem
at the very beginning of this section, 

$$
   \textrm{based on } x_{t+1} = a  \cdot x_t \textrm{ and } x_t \sim N(\hat{x}_t, \sigma_t^2)
$$

$$
   \textrm{we can predict } x_{t+1} \sim N(a\hat{x}_t, a^2\sigma_t^2)
$$

equivalently, this means we can obtain estimation of $x_{t+1}$ (without observing it) as

$$
\begin{cases}
\hat{x}_{t+1} &=& a\hat{x}_t \\\\
\sigma\_{t+1} &=& a^2 \sigma_t^2
\end{cases}
$$

## Uncertainty in Transition Function

Now it is time to introduce one variation on top of the simplest case
we discussed in the previous section. In reality the transition is
usually not perfect, which means that there is an error associated
with it. Mathematically, it means

$$
x_{t+1} = a \cdot x_t + e_t
$$

As usual for simplicity we assume the error is a zero-mean random
variable follows a Gaussian distribution, i.e.

$$
e_t \sim N \left(0, \sigma_{e_t}^2 \right)
$$

How should we revise our prediction under such condition? Remember we
are still solving the following question - if we already have an
estimation of $x_t$ as

$$
x_t \sim N(\hat{x}_t, \sigma_t^2)
$$

what is a good estimation of $x_{t+1}$, given that we know (although
not precisely in this case) the transition function?

Here we are going to introduce another useful idea - the **generative
model**. The **generative model** basically describes the procedure to
get a sample value of a random variable. In this particular case, the
generative model of $x_{t+1}$ consits of:

1. Sample $a \cdot x_t$ out of the distribution $N(a\hat{x}_t, a^2\sigma_t^2)$ (Note that this is the conclusion from the previous section)
2. Sample $e_t$ out of the distribution $N(0, \sigma_{e_t}^2)$
3. Construct $x_{t+1}$ by adding the two sampled values up

So you can see that the **generative model** is basically an
interpretation of the problem formulation, provides no new knowledge
at all. However, with such interpretation it is clear to see that
$x_{t+1}$ as a random variable is basically the sum of two
**independently distributed** gaussian random variables!

I will cheat here by referring to the [generating function based
proof](https://en.wikipedia.org/wiki/Sum_of_normally_distributed_random_variables#:~:text=Independent%20random%20variables,-Let%20X%20and&text=This%20means%20that%20the%20sum,squares%20of%20the%20standard%20deviations)
from wikipedia. As you have probably guessed, the conclusion is that

$$
\textrm{if i.i.d } \begin{cases}
X &\sim N(\mu_X, \sigma_X^2) \\\\
Y &\sim N(\mu_Y, \sigma_Y^2)
\end{cases} \textrm{ then } Z = X + Y \sim N(\mu_X + \mu_Y, \sigma_X^2 + \sigma_Y^2)
$$

By plugging in our generative model, we obtain

$$
x_{t+1} \sim N(a\hat{x}_t, a^2\sigma_t^2 + \sigma_{e_t}^2)
$$

which means such **good prediction** would be

$$
\begin{cases}
\hat{x}_{t+1} &=& a\hat{x}_t \\\\
\sigma\_{t+1} &=& a^2 \sigma_t^2 + \sigma\_{e_t}^2
\end{cases}
$$

Yep, just add the variance of the error to the estimation of variance. Pretty simple, right?


## Let There Be Observations

Okay let's take one more step in the problem formulation, so that it
will be **more realistic**.
