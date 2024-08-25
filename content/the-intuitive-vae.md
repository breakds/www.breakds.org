+++
title = "The Intuitive VAE"
description = "Notes on deriving VAE with intuitive math"
date = 2024-08-25
draft = false
[taxonomies]
tags = ["vae", "generative model", "machine learning"]
[extra]
keywords = "vae, generative model, machine learning"
toc = true
series = ""
math = true
math_auto_render = true
+++

Variational Autoencoder, also known as VAE, is an elegant algorithm in machine learning. This post summarizes my attempt to teach the math behind VAE in an intuitive way.

# Maximum Likelihood Estimation (MLE)

A common problem (arguably the central problem) in machine learning is learning the underlying distribution of a dataset $X_{\text{Data}}$. This dataset contains $n$ samples:

$$
X_{\text{Data}} = \{x_1, x_2, \cdots, x_n \}, \text{ where } x_i \in \mathbb{R}^d
$$

Assuming the underlying distribution has a probability density function (pdf) of $p(x)$, we aim to find (or fit) a parameterized function $p_\theta(x)$, such that by optimizing with respect to $\theta$, 

$$
p_\theta(x) \text{ can closely approximate } p(x)
$$

Why do we want to learn $p(x)$? Because:

1. We can then sample from it (e.g., [DALL·E 3](https://openai.com/index/dall-e-3/)).
2. We can evaluate $p_\theta(y)$ to determine how likely $y$ is to be a sample from the underlying distribution.
3. We can use it for various downstream tasks.

The maximum likelihood estimation approach suggests maximizing the following objective with respect to $\theta$:

$$
\theta^{*} = \arg\max_{\theta} \prod_{i=1}^n p_\theta(x_i)
$$

This is often simplified by taking the logarithm of the objective, converting the product into a **sum**:

$$
\theta^{*} = \arg\max_{\theta} \sum_{i=1}^n \log p_\theta(x_i)
$$

Now, if we assume the underlying distribution is as simple as a Gaussian, $p_\theta$ can be parameterized with $\theta = (\mu, \sigma)$:

$$
p_\theta(x) = \frac{1}{\sqrt{2 \pi}\sigma} \exp \left( -\frac{(x - \mu)^2}{2 \sigma^2}\right)
$$

The optimization then becomes:

$$
\theta^{*} = \arg\min_{\theta} \left[n \cdot \log \sigma + \frac{1}{2\sigma^2}\sum_{i=1}^n (x_i - \mu)^2 \right]
$$

Finding the minimum is straightforward:

$$
\begin{cases}
\mu &= \text{np.mean}(X_\text{Data}) \\\\
\sigma &= \text{np.std}(X_\text{Data})
\end{cases}
$$


# Bring in the Generative Model

Although modeling using a single Gaussian, as described above, is widely used, it is not suitable when the underlying distribution is very complex (e.g., the set of all meaningful images). A common technique to model such complex distributions is to assume the generation process follows something like $p(z) \cdot p(x|z)$. This means you first generate a **code** $z$ from $p(z)$, which broadly describes the characteristics of the final data point, and then sample the final data point from $p(x|z)$.

This assumption is intuitive, and we can understand it through an analogy of sampling a random human being. First, a gene is sampled, which determines many traits of the human, such as height, skin color, etc. We can then sample many individuals from this gene pool, and although they might all be different, they should share some similarities within the cohort. Here, the gene corresponds to $z$, which encodes the general characteristics, and the "generated" human corresponds to $x$. We often assume $p(z) = \mathcal{N}(0, I)$ because many traits are arguably Gaussian distributed[^1].

Given this, estimating $p(x)$ becomes all about estimating the underlying $p(x|z)$ since $p(z) = \mathcal{N}(0, I)$ is assumed to be **known**. If we model $p(x|z)$ with a neural network parameterized by $\theta$, we can write the model for $p(x)$ as

$$
p_\theta(x) = \int_z p_\theta(x|z)p(z) \, \mathrm{d}z
$$

**Terminology**: We will use the subscript $\theta$ to indicate that a distribution/pdf is induced by the parameterized pdf $p_\theta(x|z)$.

Unfortunately, directly optimizing this model using the MLE objective is intractable due to the integral. For now, let's take a closer look at the model.

It is possible to generate the same $x$ from two different codes, $z_1$ and $z_2$, as long as $p_\theta(x|z_1) > 0$ and $p_\theta(x|z_2) > 0$. This implies that the answer to "how likely each code can generate me" indicates the existence of another set of induced distributions:

$$
p_\theta(z|x) = \frac{p_\theta(x|z) \cdot p(z)}{p_\theta(x)}
$$

From now on, we will refer to $p_\theta(x|z)$ as the (learnable) **decoder** because it deciphers the code into an actual sample. We will call $p_\theta(z|x)$ the $\theta$-induced **encoder**. The "$\theta$-induced" prefix is important because we want to distinguish it from something else introduced in the next section.

[^1]: It is perfectly fine to use another form for $p(z)$, but the Gaussian distribution is one of the easiest to work with.

# KL Divergence and EBLO

An embarrassing fact about the above generative model is that even if we find a way to successfully learn the **decoder** $p_\theta(x|z)$, it would still be difficult to recover the induced encoder $p_\theta(z|x)$[^2]. A natural idea is to learn a separate **encoder** $q_\phi(z|x)$, **independently parameterized** by $\phi$.

I understand your concern: what if $q_\phi(z|x)$ is not consistent with the $\theta$-induced encoder $p_\theta(z|x)$? Well, we can start by analyzing a term that measures the inconsistency between two distributions, namely the [KL divergence](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence).

$$
\mathrm{KL}(q_\phi(z|x) \mathrel{\Vert} p_\theta(z|x) ) = \mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log \frac{q_\phi(z|x)}{p_\theta(z|x)} \right\]
$$

In hindsight, we want to transform the above expression to make $p_\theta(x)$ appear, so that it relates to the MLE objective. This is easily done by applying Bayes' theorem to $p_\theta(z|x)$ (twice):

$$
\begin{darray}{rcl}
\mathrm{KL}(q_\phi(z|x) \mathrel{\Vert} p_\theta(z|x) ) &=& \mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log \frac{q_\phi(z|x)}{p_\theta(z|x)} \right\] \\\\
&=& \mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log \frac{q_\phi(z|x) \cdot p_\theta(x)}{p_\theta(x|z) \cdot p(z)} \right\] \\\\
&=& \mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log p_\theta(x) \right\] + 
\mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log \frac{q_\phi(z|x)}{p(z)} \right] - \mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log p_\theta(x|z) \right\] \\\\
&=& \log p_\theta(x) + \mathrm{KL}\left(q_\phi(z|x) \mathrel{\Vert} p(z) \right) - \mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log p_\theta(x|z) \right\]
\end{darray}
$$

The most confusing part might be why we can take $p_\theta(x)$ out of the expectation. This is because the expectation is with respect to $z$, and $p_\theta(x)$ is independent of $z$. This is why I explicitly write out the variable of the expectation. Rearranging the terms on both sides of the equation, we have:

$$
\log p_\theta(x) = \mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log p_\theta(x|z) \right\] - \mathrm{KL}\left(q_\phi(z|x) \mathrel{\Vert} p(z) \right) + \mathrm{KL}(q_\phi(z|x) \mathrel{\Vert} p_\theta(z|x) )
$$

If we denote part of the right-hand side as:

$$
\mathrm{ELBO} = \mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log p_\theta(x|z) \right\] - \mathrm{KL}\left(q_\phi(z|x) \mathrel{\Vert} p(z) \right)
$$

Then the equation for $\log p_\theta(x)$ becomes:

$$
\log p_\theta(x) = \mathrm{ELBO} + \mathrm{KL}(q_\phi(z|x) \mathrel{\Vert} p_\theta(z|x) )
$$

Because KL divergence is always **non-negative**, the ELBO is a **lower bound** on $\log p_\theta(x)$, which is precisely what we want to maximize in MLE. This is also how the ELBO gets its name (Evidence Lower Bound).

[^2]: The induced encoder refers to the conditional distribution $p_\theta(z|x)$, which is difficult to compute directly.


# Properties of ELBO

Can we just maximize the ELBO as a surrogate to maximize $\log p_\theta(x)$? The answer is (not a straightforward) yes. It’s not straightforward because, typically, maximizing a lower bound does not necessarily mean the objective value is maximized—unless the gap is zero!

Let's examine the most interesting property of the ELBO, as highlighted by Hung-yi Lee in his [talk about VAE](https://www.youtube.com/watch?v=8zomhgKrsmQ&t=14s). What happens if we **keep $\theta$ fixed** and maximize the ELBO with respect to $\phi$?

$$
\phi^{*} = \arg\max_{\phi} \mathrm{ELBO}
$$

In this case, since $\log p_\theta(x)$ does not change (because $\theta$ is fixed), a maximized ELBO must imply a **minimized gap**:

$$
\log p_\theta(x) = \mathrm{ELBO} \uparrow + \mathrm{KL}(q_\phi(z|x) \mathrel{\Vert} p_\theta(z|x)) \downarrow
$$

However, note that the gap is a KL divergence, whose **minimum value is 0**! Although it may be difficult for the optimizer to reach a global optimum in practice, this clearly suggests that the effect of maximizing the ELBO with respect to $\phi$ is to drive the KL divergence term toward 0, making the ELBO a **tighter lower bound**.

This also makes sense from another perspective, because the mathematical meaning of a shrinking $\mathrm{KL}(q_\phi(z|x) \mathrel{\Vert} p_\theta(z|x))$ is that the learned encoder $q_\phi(z|x)$ is becoming more consistent with the $\theta$-induced encoder $p_\theta(z|x)$.

We now arrive at a more intuitive understanding of (maximizing) the ELBO. If we maximize the ELBO with respect to both $\theta$ and $\phi$, it will simultaneously attempt to:

1. Raise the lower bound of the target **higher and higher**.
2. **Close the gap** between the lower bound and the target.


# Computing ELBO for Training

Recall that the ELBO is defined as:

$$
\mathrm{ELBO} = \mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log p_\theta(x|z) \right\] - \mathrm{KL}\left(q_\phi(z|x) \mathrel{\Vert} p(z) \right)
$$

The **first term** $\mathbb{E}\_{z \sim q_\phi(\cdot|x)} \left\[ \log p_\theta(x|z) \right\]$ essentially means that, for each sample $x$ in the batch, we should first evaluate $q_\phi(\cdot|x)$ and sample a code $z$ from the $x$-conditioned distribution. We can then use $\log p_\theta(x|z)$ for this particular $z$ as a **representative** of the first term. This approach is common when working with expectations in the loss function since, statistically, they are equivalent.

If your model $p_\theta(x|z)$ is defined as a conditional Gaussian distribution (which is typically the case when using VAE), $p_\theta(x|z)$ is just $\mathcal{N}(\mu_\theta(z), \sigma_\theta(z))$. In this case, maximizing the first term is **almost**[^3] equivalent to minimizing the Euclidean distance between $\mu_\theta$ and $x$ (i.e., $p_\theta(x|z)$ should reconstruct $x$). This is why this term is often referred to as the **reconstruction loss**.

The **second term** is even simpler. It implies that $q_\phi(z|x)$, even when conditioned on $x$, should not deviate too far from the **prior distribution** $p(z)$. When $q_\phi(z|x)$ is modeled as a conditional Gaussian distribution, and $p(z)$ is also assumed to be Gaussian, the KL divergence can be computed in **closed form**.

In practice, you can combine these two terms with a weighting factor as a hyperparameter, allowing you to emphasize which term's effect is more important for your specific application. You can even schedule the weight dynamically to perform curriculum training.

[^3] Technically you also need to care about $\sigma_\theta(z)$

---
# Comments

The current zola theme I am using does not support uterrances. I considering switching to [this theme](https://github.com/welpo/tabi) to enable uterrances comments, but for now, if you have comments or discussion, please leave them as [github issues](https://github.com/breakds/www.breakds.org/issues) manually. Sorry about the inconvenience!


