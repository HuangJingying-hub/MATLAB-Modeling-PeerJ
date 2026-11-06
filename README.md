# MATLAB Multi-Objective Feature Selection (MMOFS)

## Overview

This repository contains MATLAB source code and associated files for a multi-objective feature-selection workflow applied to the prediction of serious respiratory adverse events. The feature search uses a ring-topology particle-swarm optimization procedure with non-dominated sorting and crowding-based ranking. Candidate feature subsets are evaluated using MATLAB's **LogitBoost** tree ensemble under stratified five-fold cross-validation.

**Important:** Although the evaluation script is named `xgb_fitness.m`, its implementation uses `fitcensemble(..., 'Method', 'LogitBoost', ...)`, **not XGBoost**.

## Software requirements

- MATLAB. **The exact MATLAB release was not recorded in the supplied project files and must be confirmed by the authors.**
- **Statistics and Machine Learning Toolbox**, for `cvpartition`, `training`, `test`, `templateTree`, and `fitcensemble`.
- No external XGBoost installation is required by the supplied MATLAB scripts.

The code has been inspected but **has not been executed or validated in MATLAB** as part of preparation of this documentation.

## Input data

The supplied workbooks contain **324 observations** and **25 predictor variables**:

| File | Role | Layout |
| --- | --- | --- |
| `王河山建模x.xlsx` | Predictor data | Row 1 contains variable descriptions; column A contains a row index; columns B–Z contain 25 predictors. |
| `王河山建模y.xlsx` | Binary outcome | Row 1 contains the outcome description; column A contains a row index; column B contains the outcome. `1` = serious respiratory adverse event; `2` = no event. |

In the supplied outcome data, 95 observations are labeled `1` and 229 are labeled `2`. The data contain clinical information. **Do not publish the original spreadsheets or MATLAB workspace files without verifying ethics approval, data-sharing consent, and de-identification/re-identification risk.**

Keep the input filenames unchanged unless all corresponding `readmatrix` references in the MATLAB scripts are updated.

## Source files

| File | Function |
| --- | --- |
| `newmain.m` | Primary analysis script; loads the predictor matrix, generates cross-validation folds, runs the optimizer, and exports results. |
| `newmain_1.m` | Alternative script. It is identical to `newmain.m` except that it writes `4ps-2.xlsx` and `4pf-2.xlsx` instead of the unnumbered outputs. |
| `newMO_Ring_PSO_SCD.m` | Ring-topology multi-objective particle swarm optimizer, including a local non-dominated sorting function. |
| `calculate_mean_fitness.m` | Calls `xgb_fitness.m` to evaluate a candidate feature subset; the current code sets one evaluation per call (`num_iterations = 1`). |
| `xgb_fitness.m` | Fits and evaluates a LogitBoost classifier with stratified five-fold cross-validation. |
| `generate_cv_partition.m` | Generates and saves the stratified five-fold partition as `cv_partition.mat`. |
| `initial.m` | Initializes nonempty binary feature-selection vectors. |
| `is_non_dominated.m` | Standalone dominance-checking utility; no call to this file was found in the supplied main workflow. |

## Model and optimization settings

The following values are specified in the supplied source code:

| Setting | Value |
| --- | --- |
| Number of candidate predictors | 25 |
| Feature pre-screening | None in the active main workflow (no LASSO, ReliefF, or SU pre-screening) |
| Optimization objectives | Minimize five-fold classification error (percentage points); minimize number of selected predictors |
| Cross-validation | Stratified five-fold (`KFold = 5`) |
| Fold-generation random seed | `rng(42)` |
| Classifier | MATLAB `fitcensemble`, `Method = 'LogitBoost'` |
| Number of boosting cycles | 60 |
| Tree maximum splits | `2^4 - 1 = 15` (`maxDepth = 4` in the code) |
| Tree minimum leaf size | 1 |
| Boosting learning rate | 0.1 |
| Maximum fitness evaluations setting | 20,000 |
| Population size | `round(200/n_var)*n_var`; for 25 predictors, 200 particles |
| Number of generations | `fix(20000/popsize)`; for 200 particles, 100 generations |
| Personal-best archive size | 10 |
| Neighborhood-best archive size | 30 |
| Inertia weight | 0.7298 |
| Acceleration coefficients | 2.05 and 2.05 |
| Additional near-Pareto error tolerance | 0.5 percentage points in the code |

The code checks for missing predictor values and would replace them with column means **before** cross-validation. No blank/missing predictor entries were detected in the supplied workbooks during this review, so no imputation appears necessary for this input. If missingness is present in a different dataset, preprocessing should be fitted using training folds only to avoid leakage.

## How to run

1. Obtain permission to access the clinical data, and download the authorized version of the complete project.
2. Open MATLAB and set **Current Folder** to the project root, where the `.m` source files and both input workbooks are stored together. The current scripts use relative filenames and are **not** directly compatible with moving code and data into separate directories without path edits.
3. Confirm that the **Statistics and Machine Learning Toolbox** is installed.
4. Run `newmain.m`. It automatically calls `generate_cv_partition.m`, then evaluates feature subsets using `calculate_mean_fitness.m` / `xgb_fitness.m`, and runs the optimizer.
5. Inspect the generated result files and compare them with the manuscript tables and figures.

MATLAB command:

```matlab
newmain
```

### Expected output files from `newmain.m`

- `cv_partition.mat`: stored five-fold partition.
- `4ps.xlsx`: unique selected solutions, with the two objectives followed by a 25-element binary feature mask.
- `4pf.xlsx`: the corresponding two-objective solution values (classification error percentage; number of selected predictors).
- `tempEXA.xlsx` and `tempEXA.mat`: optimization archive/output matrix.
- `result.mat`: workspace snapshot and results generated by the script. **This may contain copies of the clinical input data.**

The supplied `结果-M/` folder contains separately retained `4ps*` and `4pf*` files from multiple runs. The correspondence between these runs and specific manuscript results has **not** been established from the available code alone. The supplied `selected_features.mat` contains variables relating to LASSO, ReliefF and SU, but these are **not used in the supplied active main workflow**.

## Reproducibility and implementation notes

- `generate_cv_partition.m` initializes the fold creation with `rng(42)` but then invokes `rng('shuffle')`. Consequently, **the cross-validation splits are fixed but the subsequent particle-swarm search is not fully deterministic**; results may differ across runs.
- In `newMO_Ring_PSO_SCD.m`, the primary function is declared as `MO_Ring_PSO_SCD`, while the file and calling scripts use `newMO_Ring_PSO_SCD`. Consistent naming is recommended and should be tested in MATLAB before release.
- The standalone code has not been validated against the published tables or independently rerun. The actual MATLAB release and any final code/data revisions used in the manuscript should be documented before archival publication.

## Data and code availability

This repository is intended to document the computational workflow. Public access to patient-level datasets is subject to institutional ethics and data-sharing requirements. A final article should link only to the actual released files and should clearly describe any restrictions on data access.
