# Some Runtime considerations

If you are running a large scale analysis using TarGene, it is likely that you will need to make some trade offs about the estimation of nuisance parameters to keep the runtime under control. This runtime is mostly driven by the [Targeted Maximum Likelihood Estimation](@ref) process which will scale with the size of the study.

## Unit of work

The unit of work is represented by a set of treatment variables, typically one or multiple SNPs and a set of outcome variables (phenotypes). This unit of work, which corresponds to a Phenome-Wide association study, can be coarsely decomposed as follows:

1. One estimation of the propensity score: ``P(T|W)`` as specified in the `ESTIMATORFILE` configuration file.
2. For each outcome:
    1. The initial estimation of ``E[Y|T, W]`` as specified in the `ESTIMATORFILE` configuration file.
    2. For each treatment case/control setting:
        1. The **TMLE step** which roughly consists in fitting a Generalized Linear Model.

Let's illustrate with two examples:

- **Scenario 1**:
  - Parameters of interest:
    - Average Treatment Effects of Rs1799971: 0 → 1.
    - Average Treatment Effects of Rs1799971: 0 → 2.
  - Outcomes: Height, diabetes.

This scenario will require the execution of 1 unit of work which will be composed of:

```math
1 ⋅ P(T|W) + 2 ⋅ E[Y|T, W] + 4 ⋅ TMLE \ steps
```

- **Scenario 2**:
  - Parameters of interest:
    - Average Treatment Effects of Rs4680: 0 → 1.
    - Average Treatment Effects of Rs1799971: 0 → 2.
  - Outcomes: Height

This scenario will require the execution of 2 units of work each composed of:

```math
1 ⋅ P(T|W) + 1 ⋅ E[Y|T, W] + 1 ⋅ TMLE \ step
```

Those units of work can and will be run in parallel by TarGene if resources are available.

Since it is advocated to use Super Learning for both ``P(T|W)`` and ``E[Y|T, W]``, those operations are typically driving the run time. We also note that estimating ``P(T|W)`` is usually more expensive than ``E[Y|T, W]``.

Since genetic studies usually involve many SNPs and/or outcomes, we recognize that Super Learning in its purest form, may not always be a practical choice. We describe below some pointer to reduce computational time.

## Super Learning: Cross validation scheme

Because Super Learning employs cross-validation, each learning algorithm in the library needs to be trained `n` times, `n` being the number of folds. If the `adaptive` cross-validation scheme is selected this can result in up to 20 folds cross-validation which will dramatically increase runtime. Here are three alternatives:

1. To keep that complexity bounded, one can resort to a fixed k-folds cross-validation where k is an arbitrary number, e.g. 3.
2. The least expensive resampling strategy is the `resampling: Holdout` which will only consist in a single out-of-sample evaluation.
3. Don't use Super Learning. It is perfectly possible to use TarGene without Super Learning.

## Algorithms

In TarGene, we try to provide a variety of different learning algorithms that can be combined with Super Learning. By restricting the number of algorithms in a Super Learner, runtime will evidently be reduced. Also, the runtime of all learning algorithms is not equal and will depend on hyperparameter choices. Developing an understanding of a learning algorithm helps to make more informed decision about it's usage.

Here are a few examples:

- The `GLMNetRegressor/GLMNetClassifier` contain an internal k-fold cross-validation procedure that tunes the regularization hyperparameter. Combined with a p-folds Super Learner, this effectively results in k*p training procedures.

- The `GridSearch...` models correspond to self-tuning models that will also perform an inner cross-validation to select the best hyper parameter setting among the provided grid.

- The `XGBoostRegressor/XGBoostClassifier` have a `tree_method` hyperparameter that defaults to `exact`. The `hist` method is usually way faster and more appropriate for big datasets.

## Some figures

The following figures correspond to some experiments that have been run on the Eddie cluster. Since no reproducible benchmark has been conducted yet, they are only meant to give a general idea of how runtime is influenced by generic choices. The memory corresponds to virtual memory usage and actual RAM usage may be lower:

| Parameter type | Number of outcomes | G specification | Q specification | Virtual Memory (GB) | Cores | Time to complete |
| ---| --- | --- | --- | --- | --- | --- |
| IATE | 770 | Super Learning: GLMnet (3-folds) + GridSearchEvoTree (3-folds, 10 hyperparameters) | Super Learning: GLMnet (3-folds) + GridSearchEvoTree (3-folds, 10 hyperparameters) |  100 | 5 | > 3 days |
| IATE | 770 | GLMnet (3-folds) | GLMnet (3-folds) | 20 | 5 | 7 hours |