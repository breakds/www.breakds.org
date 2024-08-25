+++
title = "Minimalist's Kalman Filter Derivation, Part I"
description = ""
date = 2020-08-03
draft = false
[taxonomies]
tags = ["robotics", "control", "statistics"]
[extra]
keywords = "robotics, control, statistics, kalman"
toc = true
series = ""
math = true
math_auto_render = true
+++


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
\begin{darray}{rcl}
\mathbb{P} \left[ Y = y \right] &=& \mathbb{P} \left[ X = \frac{y}{a} \right] \\\\\\
&=& f_X \left(\frac{y}{a}\right) \mathrm{d}x \\\\\\
&=& f_X \left(\frac{y}{a}\right) \frac{\mathrm{d}y}{a} \\\\\\
&=& \frac{1}{\sigma}\phi \left( \frac{\frac{y}{a} - \mu}{\sigma} \right) \frac{\mathrm{d}y}{a} \\\\\\
&=& \frac{1}{a\sigma}\phi \left( \frac{y - a\mu}{a\sigma} \right) \mathrm{d}y
\end{darray}
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
x_{t+1} \sim N(a\hat{x}_t, a^2\sigma\_t^2 + \sigma\_{e_t}^2)
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

So we know how to predict $x_{t+1}$ given $x_t$, which is great. This
means that if we happen to know the initial state of the system,
$x_0$, we can start to predict $x_1$, and then $x_2$, ..., till any
$x_t$, which will be

$$
\begin{cases}
\hat{x}_t &=& a^t\hat{x}_t \\\\
\sigma\_t &=& a \cdot (a \cdot ( a \cdots) + \sigma\_{e\_{t-2}}^2) + \sigma\_{e\_{t-1}}^2
\end{cases}
$$

As we can see, there is one fatal problem in the above prediction. As
$t$ grows, our estimation will be less precise because the variance is
going to grow very quickly. This is because ecah time we make
prediction for one more step, the variance of error will be added to
it. To see it more clearly, when $a=1$, we will have

$$
\sigma\_t = \sigma\_{e\_0}^2 + \sigma\_{e\_1}^2 + \cdots + \sigma\_{e\_{t-1}}^2
$$

It is easy to understand this **error accumulation** intuitively. As
we make more predictions, we are not getting new information about the
system. Think about it - if you only know what a cat looks like when
it is 1-week old, how can you precisely predict how it looks like when
he is 3 years old? If you only know your weight before COVID-19
keeping us at home, how do you precisely estimate your current weight?
The key here is that you need **constant** feedback to guide your
estimation when it gets 

Okay let's take one more step in the problem formulation, so that it
will be **more realistic**. Now we are allowed to take measurement of
the system via an **observation function**. In the weight example,
this translates to you are allowed to weigh yourself with an electric
scale every now and then. It seems that with the method to take
measurement, we do not need to estimate the state anymore, we can
simply observe the readings and get the precise value! Except for that
in reality the measurement is usually not always accurate. Therefore,
the **observation function** has an associated **error** as well.
Assuming a **linear** observation function, we will have the readings
mathematically as:

$$
y_t = h_t \cdot x_t + r_t, \textrm{ where } r_t \sim N \left(0, \sigma_{r_t} \right)
$$

Note that when you take measurement at time $t + 1$, you can directly
observe $y_{t+1}$ (though $y_{t+1}$ is not $x_{t+1}$, and the latter
is what we want to estimate). The question now becomes: how to make a
good estimation about $x_{t+1}$, given

- A good estiamtion of the previous state $x_t$, and
- The current measurement reading $y_t$

Let's first find the **generative model** interpretation of this. We
can see that $y_{t+1}$ is generated in the following 3 steps:

1. Sample $x_{t+1} = a \cdot x_t + e_t$ out of the distribution $N(a\hat{x}_t, a^2\sigma_t^2 + \sigma\_{e_t}^2)$ (Note that this is the conclusion from the previous section)
2. Sample $r_{t+1}$ out of the distribution $N(0, \sigma_{r_{t+1}}^2)$
3. Directly compute $y_{t+1} = h_{t+1} \cdot x_{t+1} + r_{t+1}$

Let's stop for a while to take a closer look at the above generative
model. The distribution $N(a\hat{x}\_t, a^2\sigma\_t^2 + \sigma\_{e_t}^2)$ comes from the conclusion of the previous section,
which represents the best[^2] estimation of $x_{t+1}$ we can get based
**pure prediction**. The mean and variance of this distribution will
be used quite a lot in the derivation below, so it is good to give it
some name. Let

$$
\begin{cases}
x'_{t+1} &=& a\hat{x}_t \\\\
\sigma'^2\_{t+1} &=& a^2 \sigma_t^2 + \sigma\_{e_t}^2
\end{cases}
$$

Note that both $x'_{t+1}$ and $sigma'\_{t+1}$ are determinsitic
values, i.e. neither of them is random variable.

[^2]: I am being informal here as we haven't formally defined what
    **the best** estimation means. We will likely get to this topic in
    the future, so bear with me for now.


Although the above generative model is about generating $y_{t+1}$, it
is $x_{t+1}$ that we actually want to estimate. We can do this by
deriving the **pdf** of $x_{t+1}$. The following derivation will
likely seem very tedious, but I will try to be clear on each step and
trust me, this will be the last challenge in this post!

Given that we have observed $y_{t+1} = y$, what is the probability of
$x_{t+1} = x$? Such probability can be written as

$$
\forall x, \mathbb{P} [ x_{t+1} = x \mid y_{t+1} = y] = f_{x_{t+1}}(x) \mathrm{d}x
$$


where $f_{x_{t+1}}(x)$ is the unknown (yet) **pdf** of $x_{t+1}$ that
we want to derive. Also note that there is $\forall x$ in the
statement, which is **very important**. It means that the equation
holds for every single $x$.

By applying Bayes's law, the left hand side can also be transformed as

$$
\begin{darray}{rcl}
\forall x,  \mathbb{P} [ x_{t+1} = x \mid y_{t+1} = y] &=& \frac{\mathbb{P}[y_{t+1}=y \mid x_{t+1} = x] \mathbb{P}[x_{t+1} = x]}{\mathbb{P}[y_{t+1} = y]} \\\\
&=& \frac{\mathbb{P}[r_{t+1} = y - h_{t+1}x] \mathbb{P}[x_{t+1} = x]}{\mathbb{P}[y_{t+1} = y]}
\end{darray}
$$

So there are 3 items on the right hand side. Let's crack them one by
one. 

The simplest one here is $\mathbb{P}[y_{t+1} = y]$. Since it does not
depend on $x$, this can be just written as 

$$
\mathbb{P}[y_{t+1} = y] = \mathrm{Const} \cdot dy
$$

Next comes $\mathbb{P}[x_{t+1} = x]$, without conditioning on the
value of $y_{t+1}$. This is the **pure prediction** we discussed
above, which $ \sim N(x'\_{t+1}, \sigma'^2\_{t+1})$. Therefore it is
simply

$$
\mathbb{P}[x_{t+1} = x] = \mathrm{Const} \cdot \exp\left(-\frac{(x-x'\_{t+1})^2}{2\sigma'^2_{t+1}}\right) \mathrm{d} x
$$

The last one $\mathbb{P}[r_{t+1} = y - h_{t+1}x]$ is about $r_{t+1}$,
which happens to be following a Gaussian distirbution as well (even
better, the mean is zero)! This means

$$
\begin{darray}{rcl}
\mathbb{P}[r_{t+1} = y - h_{t+1}x] &=& \mathrm{Const} \cdot \exp \left( -\frac{(y - h_{t+1}x)^2}{2\sigma^2\_{r_{t+1}}}  \right) \mathrm{d}r \\\\
&=& \mathrm{Const} \cdot \exp \left( -\frac{(y - h_{t+1}x)^2}{2\sigma^2\_{r_{t+1}}}  \right) (\mathrm{d}y - h_{t+1}\mathrm{d}x)
\end{darray}
$$

Note $\mathrm{d}r$ can be written as the form above because of
differential form arithmetics. It is good to understand the rules
behind them, but when you get familiar with the rules, they are just
no more strange than the rules you use to take derivatives.

Therefore, take the above 3 expanded components and plug them back,
and keep in mind that by differential form rule $\mathrm{d}x \wedge
\mathrm{d}x = 0$, we have

$$
\begin{darray}{rcl}
\forall x,  && f_{x_{t+1}}(x) \mathrm{d}x \\\\
&=& \mathbb{P} [ x_{t+1} = x \mid y_{t+1} = y] \\\\
&=& \frac{\mathrm{Const} \cdot 
\exp \left( 
-\frac{(x-x'\_{t+1})^2}{2\sigma'^2\_{t+1}} -\frac{(y - h_{t+1}x)^2}{2\sigma^2_{r_{t+1}}}
\right) (\mathrm{d}x \wedge \mathrm{d} y - h_{t+1} \mathrm{d}x \wedge \mathrm{d}x)}
{\mathrm{Const} \cdot dy} \\\\
&=& \mathrm{Const} \cdot \exp \left( 
-\frac{(x-x'\_{t+1})^2}{2\sigma'^2\_{t+1}} -\frac{(y - h_{t+1}x)^2}{2\sigma^2\_{r_{t+1}}}
\right) \mathrm{d} x
\end{darray}
$$

Let's then take a closer look at the terms inside $\exp()$

$$
\begin{darray}{rcl}
&&-\frac{(x-x'_{t+1})^2}{2\sigma'^2\_{t+1}} -\frac{(y - h\_{t+1}x)^2}{2\sigma^2\_{r\_{t+1}}} \\\\
&=&
-\frac{(\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1})x^2 - 
2(\sigma^2\_{r\_{t+1}} x'\_{t+1} + \sigma'^2\_{t+1}h\_{t+1}y)x + \mathrm{Const}}
{2\sigma'^2\_{t+1}\sigma^2\_{r\_{t+1}}} \\\\
&=& -\frac{1}{2} \frac{x^2 - 
2\frac{\sigma^2\_{r\_{t+1}} x'\_{t+1} + \sigma'^2\_{t+1}h\_{t+1}y}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}}x}
{\frac{\sigma'^2\_{t+1}\sigma^2\_{r\_{t+1}}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}}} + \mathrm{Const}  \\\\
&=& - \frac{1}{2}\frac{\left(x - \frac{\sigma^2\_{r\_{t+1}} x'\_{t+1} + \sigma'^2\_{t+1}h\_{t+1}y}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}} \right)^2}
{\frac{\sigma'^2\_{t+1}\sigma^2\_{r\_{t+1}}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}}} + \mathrm{Const}
\end{darray}
$$

Plug this back in the above equation we have

$$
\begin{darray}{rcl}
\forall x,  f_{x_{t+1}}(x) \mathrm{d}x &=& \mathbb{P} [ x_{t+1} = x \mid y_{t+1} = y] \\\\
&=& \mathrm{Const} \cdot \exp \left(  - \frac{1}{2}\frac{\left(x - \frac{\sigma^2\_{r\_{t+1}} x'\_{t+1} + \sigma'^2\_{t+1}h\_{t+1}y}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}} \right)^2}
{\frac{\sigma'^2\_{t+1}\sigma^2\_{r\_{t+1}}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}}} \right) \mathrm{d} x
\end{darray}
$$

Let's remove $\mathrm{d}x$ from both side, and we have

$$
\forall x,  f_{x_{t+1}}(x) =
= \mathrm{Const} \cdot \exp \left(  - \frac{1}{2} \frac{\left(x - \frac{\sigma^2\_{r\_{t+1}} x'\_{t+1} + \sigma'^2\_{t+1}h\_{t+1}y_{t+1}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}} \right)^2}
{\frac{\sigma'^2\_{t+1}\sigma^2\_{r\_{t+1}}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}}} \right)
$$

Note that since $y$ is basically the value of $y_{t+1}$, it is
replaced with $y_{t+1}$.


This means that $x_{t+1}$ follows Gaussian distirbution! We can even
directly tell what is the mean and what is the variance of the
estimation from the above formula, i.e. 

$$
\begin{cases}
\hat{x}_{t+1} &=& \frac{\sigma^2\_{r\_{t+1}} x'\_{t+1} + \sigma'^2\_{t+1}h\_{t+1}y\_{t+1}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}} \\\\
\sigma^2\_{t+1} &=& \frac{\sigma'^2\_{t+1}\sigma^2\_{r\_{t+1}}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}}
\end{cases}
$$

## Making Sense of the Result

The above answer still looks very complicated, and let me try to
interpret it in a more intuitive way in this section.

Let's start with the mean

$$
\begin{darray}{rcl}
\hat{x}_{t+1} &=& \frac{\sigma^2\_{r\_{t+1}} x'\_{t+1} + \sigma'^2\_{t+1}h\_{t+1}y\_{t+1}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}} \\\\
&=& \frac{\sigma^2\_{r\_{t+1}}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}} \cdot x'\_{t+1} + 
\frac{\sigma'^2\_{t+1}h\_{t+1}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}} \cdot y\_{t+1} \\\\
&=& \frac{\sigma^2\_{r\_{t+1}}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}} \cdot x'\_{t+1} + 
\frac{\sigma'^2\_{t+1}h^2\_{t+1}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}} \cdot 
\frac{y\_{t+1}}{h\_{t+1}} \\\\
&=& K \cdot x'\_{t+1} + (1 - K) \cdot \frac{y\_{t+1}}{h\_{t+1}}
\end{darray}
$$

Note that in the above formula, we let

$$
K = \frac{\sigma^2\_{r\_{t+1}}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}}
$$

$K$ is clearly a number between $0$ and $1$. This means that the mean
of estimation of $x_{t+1}$ is actually a <b>weighted combination</b>
of $x'\_{t+1}$ and $y_{t+1} / h_{t+1}$. It is worth noting that 

1. $x'_{t+1}$ is the best guess you can have based on <b>pure prediction</b>
2. $y_{t+1} / h_{t+1}$ is the best guess you can have based on <b>pure observation</b>

So this is basically about trusting both of those two evidences with a
grain of salt. And how much you trust each of them depends on the
variance of each guess. The bigger variance, the less trustworthy.
Very reasonable, right?

What about the estimated variance of $x_{t+1}$? As we have defined
$K$, it can be written as

$$
\sigma^2\_{t+1} = K \cdot \sigma'^2_{t+1}
$$

This is intuitively just updating the pure prediction based variance
estimation as we have observation now. Note that becauese $K < 1$, the
final estimated variance is going to be smaller than the actual pure
prediction based estimated variance!

So at this moment we can now summarize the procedure of Kalman Filter
update, i.e. how to obtain $t+1$-step estimation based on $t$-step
estimation and new observation.

<b>Step I:</b> Compute the pure prediction based estimation.

$$
\begin{cases}
x'_{t+1} &=& a\hat{x}_t \\\\
\sigma'^2\_{t+1} &=& a^2 \sigma_t^2 + \sigma\_{e_t}^2
\end{cases}
$$

<b>Step II:</b> Compute the combination weight $K$, which is often called the <b>Kalman Gain</b>.

$$
K = \frac{\sigma^2\_{r\_{t+1}}}{\sigma^2\_{r\_{t+1}} + h^2\_{t+1}\sigma'^2\_{t+1}}
$$

<b>Step III:</b> Use Kalman Gain $K$ and observation $y_{t+1}$ to
update the pure prediction based estimation.

$$
\begin{cases}
\hat{x}\_{t+1} &=& K \cdot x'\_{t+1} + (1 - K) \cdot \frac{y\_{t+1}}{h\_{t+1}} \\\\
\sigma^2\_{t+1} &=& K \cdot \sigma'^2_{t+1}
\end{cases}
$$

## Summarry

This post demonstrated the derivation of 1D Kalman Filter, and also
slightly touched the intuitive interpretation of it. Also, I think
many of the techniques used here such as generative model and
differential forms can find their applications in many other
situations.

However, in reality, 1D Kalman Filter is rarely useful enough. This
post should have prepared you for the next journey - multivariate
Kalman Filter. Stay tuned!
