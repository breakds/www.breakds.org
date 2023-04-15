---
# Documentation: https://sourcethemes.com/academic/docs/managing-content/

title: "Transformation of Probabilistic Distributions"
subtitle: ""
summary: ""
authors: [breakds]
tags: ["math", "reinforcement learning", "machine learning"]
categories: ["machine learning", "math"]
date: 2023-04-14T08:17:04-08:00
lastmod: 2023-04-14T08:17:04-08:00
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

# Motivation

> To use `rsample` or not to use `rsample`, that is a question.

If you ever come across the above when implementing a deep learning algorithm, for example, a policy gradient algorithm for reinforcement learning, this post is about that.

**Disclaimer**: Please note that I am more interested in making the math intuitive rather than strict here.

# The concepts

## Transformation of Random Variables

Our exploration starts with a math problem that you might find in the assignments from an introductory level statistics course. Suppose we have an 1D random variable $\mathbf{X}$ following Gaussian distribution,

$$
\mathbf{X} \sim \mathcal{N}(0, 1)
$$

the probabilistic density function (pdf) of this distribtion is

$$
p(x) = \frac{1}{\sqrt{2\pi}} \exp \left( -\frac{x^2}{2} \right)
$$

Now, assume $\mathbf{Y}$ is another random variable that has a close relationship with $\mathbf{X}$.

$$
\mathbf{Y} = \sigma \mathbf{X} + \mu =: f(\mathbf{X})
$$

**Question**: What is the pdf of $\mathbf{Y}$? What kind of distribution does $\mathbf{Y}$ follow?

To answer this question, we can start from simple principles. Let's denote the pdf of $\mathbf{Y}$ as $q(\cdot)$. The integral of both pdf $p(\cdot)$ and $q(\cdot)$ over $\mathbb{R}$ must be equal to 1.

$$
1 = \int_{-\infty}^{+\infty}p(x) \mathrm{d}x = \int_{-\infty}^{+\infty}q(y) \mathrm{d}y
$$

It is not hard to deduce that, based on intuition, the above equation that constraints $p(\cdot)$ and $q(\cdot)$ is too **loose**. The probability of $\mathbf{X}$ taking any value $x$ must be equal to the probability of $\mathbf{Y}$ taking the corresponding value $y = f(x)$. This means that 

$$
\forall x \in \mathbb{R}, \mathbb{P} \\{ X = x \\} = \mathbb{P} \\{ Y = f(x) \\}
$$

The above equation can be expressed with derivative form (well intuively but inaccurately you can understand this as the form you usually write to the right of $\int$) equivalence as below

$$
\forall x \in \mathbb{R} \text{ and } y = f(x), p(x) \mathrm{d}x = q(y) \mathrm{d}y
$$

Note that since $y = f(x)$, and fortunately $f$ is a linear function so that it can be inversed, we can now simplify the above as 

$$
\begin{eqnarray}
&&p(x) \mathrm{d}x && = q(y) \mathrm{d}y \\\\
\Rightarrow && p(f^{-1}(y)) \mathrm{d}(f^{-1}(y)) && = q(y) \mathrm{d}y
\end{eqnarray}
\tag{1}\label{eq:derv_eqv}
$$

We are now blocked by $\mathrm{d}(f^{-1}(y))$, which is a derivative form. Without a formal definition, we can simplify it with very intuitive rules. For example, in this case since $f(x) = \sigma x + \mu$, 

$$
f^{-1}(y) = \frac{y - \mu}{\sigma}
$$

The form $\mathrm{d}(f^{-1}(y))$ is pretty much in plain word just the area under $f^{-1}(\cdot)$ within an infinitesimal neighborhood around a specific $y$. By just applying a symbolic trick (dividing $\mathrm{d}y$ and multiply it back), we can derive:

$$
\begin{eqnarray}
\mathrm{d}(f^{-1}(y)) && = && \frac{\mathrm{d}(f^{-1}(y))}{\mathrm{d}y} \cdot \mathrm{d} y \\\\
&& = && \frac{\mathrm{d}((y - \mu) / \sigma)}{\mathrm{d}y} \cdot \mathrm{d}y \\\\
&& = && \frac{1}{\sigma} \cdot \mathrm{d} y \\\\
&& = && \frac{\mathrm{d}y}{\sigma}
\end{eqnarray}
\tag{2}\label{eq:dinverse_linear}
$$

Please note that $\mathrm{d}(\cdot)/\mathrm{d}y$ is just what we usually call **the derivative w.r.t $y$a**. More generally, if the transformation function $f$ is invertible, the above equation is reduced to

$$
\begin{equation}
\mathrm{d}(f^{-1}(y)) = \frac{\mathrm{d} y}{f'(f^{-1}(y))}
\end{equation}
$$

Now put $\eqref{eq:dinverse_linear}$ to $\eqref{eq:derv_eqv}$, we have

$$
\begin{eqnarray}
&&p(x) \mathrm{d}x && = q(y) \mathrm{d}y && \\\\
\Rightarrow && p(f^{-1}(y)) \mathrm{d}(f^{-1}(y)) && = q(y) \mathrm{d}y && \\\\
\Rightarrow && p(f^{-1}(y)) \frac{\mathrm{d} y}{f'(f^{-1}(y))} && = q(y) \mathrm{d}y && \\\\
\Rightarrow && p(\frac{y - \mu}{\sigma}) \cdot \frac{\mathrm{d}y}{\sigma} && = q(y) \mathrm{d}y && \\\\
\Rightarrow && \frac{1}{\sigma} p(\frac{y - \mu}{\sigma}) && = q(y) && (\text{ eliminate } \mathrm{d}y)\\\\
\Rightarrow && q(y) = \frac{1}{\sqrt{2 \pi} \sigma} \exp -\frac{(y - \mu)^2}{\sigma^2}  &&
\end{eqnarray}
$$


Now, we have proved (sort of intuitively and symblically via derivative form arithmetics) that such linear transformation of the random variable $\mathrm{X}$ still follows Gaussian distribution. In fact,

$$
\mathrm{Y} \sim \mathcal{N}(\mu, \sigma^2)
$$

Pretty straight forward, right?

## More general 1D case
