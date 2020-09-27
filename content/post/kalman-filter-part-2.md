---
# Documentation: https://sourcethemes.com/academic/docs/managing-content/
# Documentation: https://sourcethemes.com/academic/docs/writing-markdown-latex/

title: "Minimalist's Kalman Filter Derivation, Part II"
subtitle: "From Bayes Filter to Multivariate Kalman Filter"
summary: "Derive multivariate Kalman Filter from Bayes Filter"
authors: [breakds]
tags: []
categories: ["robotics", "control", "statistics"]
date: 2020-09-25T20:52:29-08:00
lastmod: 2020-09-25T20:53:00-08:00
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

## Background

As promised, in this post we will be deriving the multi-variate
version of Kalman Filter. It will be a bit more math intensive because
we are focusing on **derivation**, but similar to the previous post I
will try my best to make the equations intuitive and easily
understandable. 

## Bayes Filter

Kalman filter is actually a special form of Bayes filter. This means
that Bayes filter is actually solving a (slightly) more general
problem. We will first give a high-level overivew of Bayes Filter and
then add constraint to make it a Kalman filter problem.

The reason is that 

1. Although being more general, Bayes filter is actually more
   straight-forward to derive.
2. By understanding the connection between Kalman filter and Bayes
   filter, it will give a much better picture of the great ideas
   behind both of them.

Unlike the previous post, we are looking at a system with
multi-variate state space ($n$ dimensional). This means that the
system is undergoing a series of states

$$
x_1, x_2, x_3, ..., x_t, x_{t+1}, ... \in \mathbb{R}^n
$$

Similarly, we are not able to directly observe the states. What we can
do is for each timestamp $t$, we can take a measurement to obtain the
observations

$$
y_1, y_2, y_3, ..., y_t, y_{t+1}, ... \in \mathbb{R}^m
$$

Note that here $m$ is not necessarily equal to $n$. Bayes filter aims
to solve the problem of estimating (the distribution of) $x_t$ given
the observed trajectory $y_{1..t}$, i.e. estimating the probability
density function (pdf):

$$
p\left(x_t \mid y_{1..t}\right) = ?
$$

### Solve Bayes Filter Problem

Bayes filter assumes that you know 

$$
\begin{cases}
p\left( x_t \mid x_{t-1} \right) & \textrm{the transition model}\\\\
p\left( y_t \mid x_t \right) & \textrm{the measurement model} \\\\
p \left( x_{t-1} \mid y_{1..t-1} \right) & \textrm{the previous state estimation}
\end{cases}
$$

The first step is to obtain the estimation of $x_t$ purely based on
prediction (i.e. without the newest observation $y_t$). By applying
the **transition model** and the previous state estimation, we have:

$$
p\left( x_t \mid y_{1..t-1} \right) = \int_{x} p\left(x_t \mid x_{t-1} = x\right) \cdot p\left(x_{t-1} = x \mid y_{1..t-1} \right) \mathrm{d}x
$$

We then look at the **posterior**[^1]

$$
\begin{eqnarray}
p \left( x_t \mid y_{1..t} \right) &=& \frac{p\left( x_t, y_t \mid y_{1..t-1}\right)}{p\left( y_t \mid y_{1..t-1}\right)} \\\\
&\propto& p\left( x_t, y_t \mid y_{1..t-1}\right) \\\\
&=& p \left(y_t \mid x_t \right) \cdot p\left( x_t \mid y_{1..t-1} \right)
\end{eqnarray}
$$

Note that both terms on the RHS are known as they are just the
**measurement model** and the pure prediction estimation. 

[^1]: If you recognize it - yes we are applying Bayes inference here.

By obtaining the pdf $p\left( x_t \mid y_{1..t} \right)$ we derived
the estimated distribution for the current state at $t$. Therefore two
steps actually covered the Bayes filter. Yes it is just that simple
and straight-forward. $\blacksquare$

### Kalman Filter Is a Special Bayes 

We say that Kalman filter is a special form of Bayes Filter because it
poses 3 constraints on Bayes filter, one for each of the known
conditions:

1. The transition model is assumed to be **linear** with **Gaussian**
   error. This means that
   
   $$
   p \left( x_t \mid x_{t-1} \right) = \textrm{  pdf of } N( F_tx_{t-1}, Q_t)
   $$
   
   Here $F_t$ is a $n \times n$ matrix, and $Q_t$ is a $n \times n$
   [covariance
   matrix](https://en.wikipedia.org/wiki/Covariance_matrix) describing
   the error. The most important properties of the covariance matrices
   are that they are
   
   * always symmetric
   * always [positive semi-definite](https://en.wikipedia.org/wiki/Definite_symmetric_matrix)
   * always invertible
2. The measurement model is also assumed **linear** with **Gaussian**
   error.

    $$
    p\left( y_t \mid x_t \right) = \textrm{ pdf of } N(H_tx_t, R_t)
    $$
    
    Similarly, $H_t$ is a $m \times n$ matrix and $R_t$ is a $m \times
    m$ covariance matrix.
3. The estimated distribution of $x_t \mid y_{1..t}$ is assumed
   Gaussian, i.e.
   
   $$
   p\left( x_t \mid y_{1..t} \right) = \textrm{ pdf of } N(\hat{x}_t, P_t)
   $$
   
   Here in the above formula
   
   * $\hat{x}_t$ is the estimated mean of the state at $t$.
   * $P_t$ is a $n \times n$ matrix representing the estimated
     covariance of the state at $t$.

We can now follow Bayes Filter's 2 steps to solve Kalman Filter.

## Pure Prediction in Kalman Filter

As shown above the first step is about computing

$$
p\left( x_t \mid y_{1..t-1} \right) = \int_{x} p\left(x_t \mid x_{t-1} = x\right) \cdot p\left(x_{t-1} = x \mid y_{1..t-1} \right) \mathrm{d}x
$$

We can continue to simplify it since we are dealing with Kalman filter
and we know that both pdfs involved in the RHS are **Gaussian**. Note
that if we take the **generative model** view of the above equation,
it actually tells

> The random variance $x_t|y_{1..t-1}$ is generated by
>
> 1. Sample $x_{t_1} \mid y_{1..t-1}$ from $N(\hat{x}_{t-1}, P_{t-1})$
> 2. Sample $e_t$ from $N(0, Q_t)$
> 3. Obtain $x_{t} \mid y_{1..t-1} = F_t \cdot (x_{t-1} \mid y_{1..t-1}) + e_t$ 

For ease of reading we are going to use $x_t$ as short for the
conditional variable $x_t \mid y_{1..t-1}$ and $x_{t-1}$ as short for
the conditional random variable $x_{t-1} \mid y_{1..t-1}$.

Recall that the moment generating function for a Gaussian distribution
$N(\mu, \Sigma)$ is

$$
g(k) = \mathbb{E} \left[ e^{k^\intercal x}\right] = \exp \left[ k^\intercal\mu + \frac{1}{2} k^\intercal \Sigma k \right]
$$

By applying this we can try to obtain the moment generating function
for the random variable $x_t \mid y_{1..t-1}$ by the following:


$$
\begin{eqnarray}
g(k) &=& \mathbb{E} \left[ e^{k^\intercal x_t}\right] = \mathbb{E} \left[ e^{k^\intercal (F_t x_{t-1} + e_t)} \right] \\\\
&=& \mathbb{E} \left[ e^{k^\intercal F_t x_{t-1}} \right] \cdot \mathbb{E} \left[ e^{k^\intercal e^t} \right] \\\\
&=& \mathbb{E} \left[ e^{(F_{t}^{\intercal} k )^\intercal x_{t-1}} \right] \cdot \mathbb{E} \left[ e^{k^\intercal e^t} \right] \\\\
&=& \exp \left[ (F_{t}^{\intercal}k)^\intercal \hat{x}_{t-1} + \frac{1}{2} (F_{t}^{\intercal}k)^\intercal P_{t-1} (F_{t}^{\intercal}k) \right] \cdot \exp \left[ \frac{1}{2} k^\intercal Q_t k\right] \\\\
&=& \exp \left[ k^\intercal F_t \hat{x}_{t-1} + \frac{1}{2}k^\intercal \left( F_{t}^{\intercal}P_{t-1}F_{t} + Q_t \right)k \right]
\end{eqnarray}
$$

Now it becomes super clear that $x_t \mid y_{1..t-1}$ also follows a
Gaussian distribution. In fact

$$
p\left(x_t \mid y_{1..t-1}\right) = \textrm{ pdf of } N(F_t\hat{x}_{t-1}, F_t^{\intercal} P_{t-1} F_t + Q_t)
$$

The mean and covariance determine the pure-prediction estimation.

$$
\begin{cases}
x_{t}' &=& F_t \hat{x}_{t-1} & \textrm{pure prediction mean} \\\\
P_{t}' &=& F_t^\intercal P_{t-1} F_t + Q_t & \textrm{pure prediction covariance}
\end{cases}
$$

Remember this and we will use them in the next section.

## Posterior in Kalman Filter

The second step in Bayes filter is just to compute the actual
estimation called **posterior** with

$$
p \left( x_t \mid y_{1..t} \right) \propto p \left(y_t \mid x_t \right) \cdot p\left( x_t \mid y_{1..t-1} \right)
$$

You would probably think it is now straight-forward to simplify this
equation as we know both terms on the RHS are Gaussian pdfs, and their
parameters are known. While it is true that we can directly compute
the product of the two Gaussian pdfs, there are some complicated
matrix inversion that we will have deal with in that approach. To
avoid such complexity, we choose to estimate an **auxilary** random
variable 

$$
Y = H_tx_t
$$ 

first. Note that $H_t$ is just a known constant matrix, and $Y$ is
basically a linear transformation of $x_t$. $Y$ has some physical
meaning as well - it is the supposed observation value if there are no
noise in the measurement. This also points out an important property
of $Y$:


$$
\begin{cases}
r_t &=& y_t - Y & \textrm{the measurement noise random variable} \\\\
r_t &\sim& N(0, R_t) & \textrm{as we assume Gaussian error}
\end{cases}
$$

### Relationship between $Y$ and $x_t$

Since $Y$ is obtained by just applying a linear transformation on
$x_t$, it is obvious that if $x_t$ follows a Gaussian distribution,
$Y$ also does. Nonetheless we will try to derive it formally via
moment generating function.

$$
\begin{eqnarray}
g_Y(k) &=& \mathbb{E}\left[ e^{k^\intercal Y}\right] = \mathbb{E}\left[ e^{k^\intercal H_t x_t}\right]
= \mathbb{E}\left[ e^{(H_t^\intercal k)^\intercal H_t x_t}\right] \\\\
&=& \exp \left[ (H_t^\intercal k)^\intercal \mu_{x_t} + \frac{1}{2} (H_t^\intercal k)^\intercal \Sigma_{x_t} (H_t^\intercal k)\right] \\\\
&=& \exp \left[ k^\intercal (H_t\mu_{x_t}) + \frac{1}{2} k^\intercal (H_t \Sigma_{x_t} H_t^\intercal) k\right]
\end{eqnarray}
$$

The above equation shows that $Y \sim N(H_t\mu_{x_t}, H_t \Sigma_{x_t}
H_t^\intercal)$.

This actually tells **two stories**:

1. The **pure prediction** estimation of $Y$, i.e. $Y | y_{1..t-1}$ is
   actually

   $$
   \begin{cases}
   Y | y_{1..t-1} &\sim& N(y', S) \\\\
   y' &=& H_tx_t' \\\\
   S &=& H_tP_t'H_t^\intercal 
   \end{cases}
   $$
   
2. The same relationship holds for the final posterior estimation of
   $Y$ (i.e. $Y | y_{1..t}$) and $x_t$ (i.e. $x_t | y_{1..t}$)
   
   
   $$
   \begin{cases}
   x_t | y_{1..t} &\sim& N(\hat{x}_t, P_t) \\\\
   Y | y_{1..t} &\sim& N(H_t\hat{x}_t, H_tP_tH_t^\intercal)
   \end{cases}
   $$

### Derivation of the Posterior of $Y$

Rewrite the posterior equation above so that it is w.r.t. $Y$, we have

$$
p \left( Y = y\mid y_{1..t} \right) \propto p \left(y_t \mid Y = y\right) \cdot p\left( Y = y\mid y_{1..t-1} \right)
$$

Let us take a closer look at the LHS. The first term

$$
\begin{eqnarray}
p \left(y_t \mid Y \right) &=& p \left(r_t = y_t - y \right) \\\\
&=& \textrm{const} \cdot \exp \left\[-\frac{1}{2} (y_t - y)^\intercal R_t (y_t - y)\right\] \\\\
&=& \textrm{const} \cdot \exp \left\[-\frac{1}{2} (y - y_t)^\intercal R_t (y - y_t)\right\] \\\\
&=& \textrm{pdf of } N(y_t, R_t) \textrm{ w.r.t. } Y
\end{eqnarray}
$$

And the second term is the pure prediction estimation of $Y$ which we
have already derived in the previous subsection. It is

$$
p\left( Y = y\mid y_{1..t-1} \right) = \textrm{ pdf of } N(H_tx_t', H_tP_t'H_t^\intercal) \textrm{ w.r.t. } Y
$$

For ease of reading let's denote both of them as

$$
\begin{cases}
N(y_t, R_t)_Y &=& \textrm{pdf of } N(y_t, R_t) \textrm{ w.r.t. } Y \\\\
N(H_tx_t', H_tP_t'H_t^\intercal)_Y &=& \textrm{ pdf of } N(H_tx_t', H_tP_t'H_t^\intercal) \textrm{ w.r.t. } Y
\end{cases}
$$

Back to the posterior of $Y$, we can now see

$$
p \left( Y = y\mid y_{1..t} \right) \propto N(y_t, R_t)_Y \cdot N(H_tx_t', H_tP_t'H_t^\intercal)_Y
$$

Okay so the posterior pdf is actually the product of two Gaussian
pdfs. We now need to apply our Lemma III (proof in the Appendix),
which says the product of two Guassian pdfs with parameters $\mu_1$,
$\Sigma_1$, $\mu_2$ and $\Sigma_2$ is the pdf of an **unnormalized**
Guassian, s.t.

$$
\begin{cases}
\Sigma &=& \Sigma_2 - K\Sigma_2 \\\\
\mu &=& \mu_2 + K (\mu_1 - \mu_2)
\end{cases}
\textrm{ , where } K = \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}
$$

(everyone is encouraged to read the appendix for the proofs of all the
lemmas, as they are rather simple).

Now plugin what we have here

$$
\begin{cases}
\Sigma_1 &=& R_t &\textrm{ and }& \mu_1 &=& y_t \\\\
\Sigma_2 &=&  H_tP_t'H_t &\textrm{ and }& \mu_2 &=& H_tx_t'
\end{cases}
$$

which gives parameters for posterior distrition of $Y|y_{1..t}$

$$
\begin{cases}
K_Y &=& H_tP_t'H_t^\intercal(R_t + H_tP_t'H_t^\intercal)^{-1} \\\\
\Sigma_Y &=& H_tP_t'H_t^\intercal - K H_tP_t'H_t^\intercal \\\\
&=& H_tP_t'H_t^\intercal - H_tP_t'H_t^\intercal(R_t + H_tP_t'H_t^\intercal)^{-1} H_tP_t'H_t^\intercal \\\\
\mu_Y &=& H_tP_t' + K (y_t - H_tx_t') \\\\
&=& H_tx_t' + H_tP_t'H_t^\intercal(R_t + H_tP_t'H_t^\intercal)^{-1}(y_t - H_tx_t')
\end{cases}
$$

### Derivation of the Posterior of $x_t$

Right, the above **does** look complicated. But you do not have to
remember this and we do this intentionally so that we can achieve our
final goal of estimating the posterior distribution of $x_t$. We now
go back to look at the last equation of the previous subsection:

$$
Y | y_{1..t} \sim N(H_t\hat{x}_t, H_tP_tH_t^\intercal)
$$
   
It is straight-forward to see that

$$
\begin{cases}
H_tP_tH_t^\intercal &=& H_tP_t'H_t^\intercal - H_tP_t'H_t^\intercal(R_t + H_tP_t'H_t^\intercal)^{-1} H_tP_t'H_t^\intercal \\\\
H_t\hat{x}_t &=& H_tx_t' + H_tP_t'H_t^\intercal(R_t + H_tP_t'H_t^\intercal)^{-1}(y_t - H_tx_t')
\end{cases}
$$

Note that this holds for whatever $H_t$ we put there. Therfore by
striping $H_t$ for both sides we have derived the parameters for the
posterior estimation of $x_t$:

$$
\begin{cases}
P_t &=& P_t' - P_t'H_t^\intercal(R_t + H_tP_t'H_t^\intercal)^{-1} H_tP_t' \\\\
\hat{x}_t &=& x_t' + P_t'H_t^\intercal(R_t + H_tP_t'H_t^\intercal)^{-1}(y_t - H_tx_t')
\end{cases}
$$

In fact, we can further simplify it by defining $K$ (which is usually
called the [Kalman gain](https://dsp.stackexchange.com/questions/2347/how-to-understand-kalman-gain-intuitively))

$$
K = P_t'H_t^\intercal(R_t + H_tP_t'H_t^\intercal)^{-1}
$$

and the posterior estimation of $x_t$ can then be simplified as

$$
\begin{cases}
P_t &=& P_t' - KH_tP_t' \\\\
\hat{x}_t &=& x_t' + K(y_t - H_tx_t')
\end{cases}
$$

That concludes the derivation of multi-variate Kalman filter. $\blacksquare$

## Summary

Based on the derivation, the Kalman filter can be used to obtain the
posterior estimation following the Bayes filter's approach. The steps
are

1. Compute the pure prediction estimation paramters

    $$
    \begin{cases}
     x_t' &=& F_t \hat{x}\_{t-1} \\\\
     P_t' &=& F_tP_{t-1}F_t^\intercal + Q_t
    \end{cases}
    $$

2. Compute the Kalman gain $K$

   $$
   K = P_t'H_t^\intercal(R_t + H_tP_t'H_t^\intercal)^{-1}
   $$

3. Compute the posterior

   $$
   \begin{cases}
   P_t &=& P_t' - KH_tP_t' \\\\
   \hat{x}_t &=& x_t' + K(y_t - H_tx_t')
   \end{cases}
   $$

# Appendix

I want the post to be very self-contained. Therefore I prepared 3
lemmas in the appendix so that main article won't be too distracting.
All the 3 lemmas are about the product of two Gaussian pdfs, and it is
suggested that you read them in order.

## Appendix -  Lemma I

The product of 2 scalar Gaussian pdfs is an **unormalized** pdf of
another scalar Gaussian. To be more specific, if 

$$
\begin{eqnarray}
f(x) &=& f_1(x)f_2(x) \textrm{, where } \\\\
f_1(x) &=& \textrm{pdf of } N(\mu_1, \sigma_1^2) \\\\
f_2(x) &=& \textrm{pdf of } N(\mu_2, \sigma_2^2)
\end{eqnarray}
$$

then $f(x)$ is the pdf of $N(\mu, \sigma^2)$ with

$$
\begin{cases}
\sigma^2 &=& \left(\frac{1}{\sigma_1^2} + \frac{1}{\sigma_2^2}\right)^{-1} \\\\
\mu &=& \frac{\sigma^2}{\sigma_1^2}\mu_1 +\frac{\sigma^2}{\sigma_2^2}\mu_2
\end{cases}
$$

**proof:**

Expand the pdf $f_1$ and $f_2$, we have

$$
\begin{cases}
f_1(x) &=& \textrm{const} \cdot \exp \left[ -\frac{(x - \mu_1)^2}{2 \sigma_1^2} \right] \\\\
f_2(x) &=& \textrm{const} \cdot \exp \left[ -\frac{(x - \mu_2)^2}{2 \sigma_2^2} \right] \\\\
\end{cases}
$$

Therefore

$$
\begin{eqnarray}
f(x) &=& f_1(x) \cdot f_2(x) \\\\
&=& \textrm{const} \cdot \exp \left[ -\frac{(x - \mu_1)^2}{2 \sigma_1^2} -\frac{(x - \mu_2)^2}{2 \sigma_2^2} \right] \\\\
&=& \textrm{const} \cdot \exp -\frac{1}{2}\left[ \left(\frac{1}{\sigma_1^2} + \frac{1}{\sigma_2^2}\right) x^2 - 2\left(\frac{\mu_1}{\sigma_1^2} + \frac{\mu_2}{\sigma_2^2}\right)x\right] 
\end{eqnarray}
$$

Therefore we know that it must be an unnormalized Gaussian form.
Assume the parameters are $\mu$ and $\sigma^2$, we can then force


$$
\frac{(x - \mu)^2}{\sigma^2} = \left(\frac{1}{\sigma_1^2} + \frac{1}{\sigma_2^2}\right) x^2 - 2\left(\frac{\mu_1}{\sigma_1^2} + \frac{\mu_2}{\sigma_2^2}\right)x + \textrm{const}
$$

which gives

$$
\begin{cases}
\frac{1}{\sigma^2} &=& \frac{1}{\sigma_1^2} + \frac{1}{\sigma_2^2} \\\\
\frac{\mu}{\sigma^2} &=& \frac{\mu_1}{\sigma_1^2} + \frac{\mu_2}{\sigma_2^2}
\end{cases}
$$

Solve it and we get


$$
\begin{cases}
\sigma^2 &=& \left(\frac{1}{\sigma_1^2} + \frac{1}{\sigma_2^2}\right)^{-1} \\\\
\mu &=& \frac{\sigma^2}{\sigma_1^2}\mu_1 +\frac{\sigma^2}{\sigma_2^2}\mu_2
\end{cases}
$$

This concludes the proof. $\blacksquare$


## Appendix -  Lemma II

Lemma II is just the multi-variate version of Lemma I.

The product of 2 **multi-variate** Gaussian pdfs of $n$ dimension is
an **unormalized** pdf of another multi-varite $n$ dimension Gaussian.
To be more specific, if

$$
\begin{eqnarray}
f(x) &=& f_1(x)f_2(x) \textrm{, where } \\\\
f_1(x) &=& \textrm{pdf of } N(\mu_1, \Sigma_1) \\\\
f_2(x) &=& \textrm{pdf of } N(\mu_2, \Sigma_2)
\end{eqnarray}
$$

then $f(x)$ is the pdf of $N(\mu, \Sigma)$ with

$$
\begin{cases}
\Sigma &=& (\Sigma_1^{-1} + \Sigma_2^{-1})^{-1} \\\\
\mu &=& \Sigma \Sigma_1^{-1} \mu_1 + \Sigma \Sigma_2^{-1} \mu_2
\end{cases}
$$

Note that Lemma II is awfully similar to Lemma I.

**proof:**

We still do the expand first, which gives

$$
\begin{cases}
f_1(x) &=& \textrm{const} \cdot \exp \left[ -\frac{1}{2} (x-\mu_1)^\intercal \Sigma_1^{-1} (x - \mu_1) \right] \\\\
f_2(x) &=& \textrm{const} \cdot \exp \left[ -\frac{1}{2} (x-\mu_2)^\intercal \Sigma_2^{-1} (x - \mu_2) \right]
\end{cases}
$$

Plug them into $f(x)$, we have


$$
\begin{eqnarray}
f(x) &=& f_1(x) \cdot f_2(x) \\\\
&=& \textrm{const} \cdot \exp -\frac{1}{2} \left[ x^\intercal(\Sigma_1^{-1} + \Sigma_2^{-1})x - 2x^\intercal (\Sigma_1^{-1}\mu_1 + \Sigma_2^{-1}\mu_2)\right]
\end{eqnarray}
$$

This shows that $f(x)$ is the pdf of a Gaussian. Similarly assume the
parameters of the Gaussian is $\mu$ and $\Sigma$, we can force

$$
\begin{eqnarray}
&&x^\intercal(\Sigma_1^{-1} + \Sigma_2^{-1})x - 2x^\intercal (\Sigma_1^{-1}\mu_1 + \Sigma_2^{-1}\mu_2)  \\\\
&=& (x - \mu)^\intercal \Sigma^{-1} (x - \mu) \\\\
&=& x^\intercal \Sigma^{-1} x - 2 x^\intercal \Sigma^{-1} \mu + \textrm{const}
\end{eqnarray}
$$

This gives the equation

$$
\begin{cases}
\Sigma^{-1} &=& \Sigma_1^{-1} + \Sigma_2^{-1} \\\\
\Sigma^{-1}\mu &=& \Sigma_1^{-1} \mu_1 + \Sigma_2^{-1} \mu_2
\end{cases}
$$

Solve it and we have

$$
\begin{cases}
\Sigma &=& (\Sigma_1^{-1} + \Sigma_2^{-1})^{-1} \\\\
\mu &=& \Sigma \Sigma_1^{-1} \mu_1 + \Sigma \Sigma_2^{-1} \mu_2
\end{cases}
$$

This concludes the proof of Lemma II. $\blacksquare$

## Appendix - Lemma III

Lemma III further simplifies Lemma II with a transformation. It states
that the solution of Lemma II can be rewritten as

$$
\begin{cases}
\Sigma &=& \Sigma_2 - K\Sigma_2 \\\\
\mu &=& \mu_2 + K(\mu_1 - \mu_2)
\end{cases}
$$

where

$$
K = \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}
$$

**proof:**

1. We first apply some transformation on $\Sigma$.
   
   $$
   \begin{eqnarray}
   \Sigma^{-1} &=& \Sigma_1^{-1} + \Sigma_2^{-1} \\\\
   &=& \Sigma_1^{-1}\Sigma_1(\Sigma_1^{-1} + \Sigma_2^{-1})\Sigma_2\Sigma_2^{-1} \\\\
   &=& \Sigma_1^{-1} \left[ \Sigma_1(\Sigma_1^{-1} + \Sigma_2^{-1})\Sigma_2 \right] \Sigma_2^{-1} \\\\
   &=& \Sigma_1^{-1} (\Sigma_1 + \Sigma_2) \Sigma_2^{-1} \\\\
   \end{eqnarray}
   $$
   
   take the inverse on both sides, we have
   
   $$
   \Sigma = \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}\Sigma_1 = \Sigma_1(\Sigma_1 + \Sigma_2)^{-1}\Sigma_2
   $$
   
   Note that we implicitly used the property that covariance matrices
   and their inverses are **symmetric**.
   
2. We then apply some transformation on $\mu$.

   $$
   \begin{eqnarray}
   \mu &=& \Sigma \Sigma_1^{-1}\mu_1 + \Sigma \Sigma_2^{-1}\mu_2 \\\\
   &=& \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}\Sigma_1 \Sigma_1^{-1}\mu_1 + \Sigma_1(\Sigma_1 + \Sigma_2)^{-1}\Sigma_2 \Sigma_2^{-1}\mu_2 \\\\
   &=& \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}\mu_1 + \Sigma_1(\Sigma_1 + \Sigma_2)^{-1}\mu_2 \\\\
   &=& \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}\mu_1 + (\Sigma_1 + \Sigma_2 - \Sigma_2)(\Sigma_1 + \Sigma_2)^{-1}\mu_2 \\\\
   &=& \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}\mu_1 +  \mu_2 -\Sigma_2(\Sigma_1 + \Sigma_2)^{-1}\mu_2 \\\\
   &=& \mu_2 + \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}(\mu_1 - \mu_2)
   \end{eqnarray}
   $$
   
   It is now clear that if we define $K = \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}$, then
   
   $$
   \mu = \mu_2 + K(\mu_1 - \mu_2)
   $$
   
   This proves the half of Lemma III.
   
3. Let us take another look at $\Sigma$.
   
   $$
   \begin{eqnarray}
   \Sigma &=& \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}\Sigma_1 \\\\
   &=& K\Sigma_1 \\\\
   &=& K(\Sigma_1 + \Sigma_2 - \Sigma_2) \\\\
   &=& K(\Sigma_1 + \Sigma_2) - K\Sigma_2) \\\\
   &=& \Sigma_2(\Sigma_1 + \Sigma_2)^{-1}(\Sigma_1 + \Sigma_2) - K\Sigma_2) \\\\
   &=& \Sigma_2 - K\Sigma_2
   \end{eqnarray}
   $$
   
   The above proves the second half of Lemma III.

Therefore the proof is concluded. $\blacksquare$
   
