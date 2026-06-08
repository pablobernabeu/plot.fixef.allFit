# plot.fixef.allFit

> **This function now lives in the [`modelviz`](https://github.com/pablobernabeu/modelviz) package.**

Visualise the output from `lme4::allFit()`, to look at the fixed-effect
estimates for a set of predictors across a set of optimizers (e.g. bobyqa,
Nelder-Mead). This standalone function has been generalised, renamed and folded
into **modelviz**, a unified, CRAN-grade package for visualising statistical
models and data.

The successor is **`optimizer_fixef_plot()`**, which:

* replaces the brittle manual `patchwork` layout with robust faceting,
* drops the `Cairo`/`reshape2` dependencies,
* accepts either an `lme4::allFit()` object **or** a plain data frame, and
* shares a consistent theme and palette with the rest of the package.

## Use it via modelviz

```r
# install.packages("remotes")
remotes::install_github("pablobernabeu/modelviz")

library(modelviz)

m  <- lme4::lmer(life_satisfaction ~ stress + (1 | region),
                 data = wellbeing_survey)
af <- lme4::allFit(m)
optimizer_fixef_plot(af)
```

See the [modelviz repository](https://github.com/pablobernabeu/modelviz) and
`vignette("model-estimates", package = "modelviz")` for details.

---

The original standalone script is preserved in this repository
(`plot.fixef.allFit.R`) and in the git history for reference.
