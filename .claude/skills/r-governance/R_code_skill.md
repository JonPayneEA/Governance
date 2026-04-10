---
name: r-governance
description: Team R coding standards for Forecasting and Warning Tools. Covers fastverse (not tidyverse), Flode module architecture, naming conventions, mandatory header blocks, S7/R6/S3 OOP hierarchy, file formats, tier-based testing, and renv reproducibility. Load when writing or reviewing any R code in this project.
user-invocable: false
paths: "**/*.R, **/*.r, **/*.Rmd, **/*.qmd"
---

# R Tool Governance Skill

## When this skill applies

Load this skill whenever writing, reviewing, or refactoring R code for the Forecasting and Warning Teams. It applies to all `.R` files, Flode module development, hydrological analysis scripts, and any R tool intended for team use.

This skill encodes the team-specific standards from *R Tool Governance v1.3*, a companion to the *Data & Digital Asset Governance Framework v1.4*. It diverges from general R conventions in significant ways -- read every section.

---

## 1. Ecosystem: fastverse, not tidyverse

The team's default ecosystem is the **fastverse**. The tidyverse must not be used in Tier 1 operational tools or Flode package functions. It is acceptable only in Tier 3 exploratory work.

| Task | Use |
|---|---|
| Tabular data manipulation | `data.table` (primary); `collapse` as supplementary toolkit |
| Time series | `kit`, `roll` |
| Numerical / statistical | `collapse::fnth()`, `collapse::fmean()` etc. |
| File I/O (text) | `data.table::fread()` / `fwrite()` |
| File I/O (Parquet) | `arrow::read_parquet()` / `write_parquet()` |
| File I/O (spatial / netCDF) | `terra`, `ncdf4` |
| Visualisation | `ggplot2` acceptable for Tier 2-3; `reach.viz` functions preferred |
| Paths | `here`, `config` |
| Package development | `devtools`, `roxygen2`, `usethis`, `testthat` |

**Anti-patterns:**
```r
# Never in Tier 1 or Flode
library(dplyr)
library(purrr)
library(readr)
read.csv(...)       # use fread()
write.csv(...)      # use fwrite()
sapply(...)         # use collapse or explicit vapply
```

**Correct patterns:**
```r
library(data.table)
library(collapse)

flow_dt <- fread("gauges.csv")
flow_dt[station == "Thames", .(mean_q = fmean(flow_cms)), by = water_year]
```

The core data.table idiom is `DT[i, j, by]`: filter rows with `i`, compute columns with `j`, group with `by`.

---

## 2. Flode package map

All reusable R code should be developed with eventual inclusion in Flode in mind. Use the correct module:

| Module | Owns |
|---|---|
| `reach.io` | Reading gauge records, gridded rainfall, NWP outputs; writing standardised forecast files |
| `reach.hydro` | Core hydrological calculations: flow stats, unit conversions, catchment aggregation, flood frequency |
| `reach.ensemble` | Ensemble processing: member weighting, quantile extraction, probabilistic thresholding |
| `reach.viz` | Standardised ggplot2-compatible chart themes and flood-specific plot functions |
| `reach.validate` | Model validation and skill scoring: bias metrics, skill scores, verification |
| `reach.utils` | Date/time helpers, path management, logging, configuration loading |

Note: module names are provisional and may change. Module scopes are agreed.

To promote a function into Flode: develop as Tier 3 with full header, peer review to Tier 2 standard, open a GitHub issue to the Flode Steward, write roxygen2 docs and achieve 70% test coverage, then the Steward merges and increments Flode's version.

---

## 3. Naming conventions

| Item | Convention | Example |
|---|---|---|
| Functions | `snake_case` verbs | `calc_flood_peak()`, `load_gauge_dt()` |
| data.table objects | `_dt` suffix | `flow_dt`, `ensemble_dt` |
| OOP classes | `UpperCamelCase` with `Flode` prefix | `FlodeCatchment`, `FlodeForecast` |
| Variables | `snake_case` nouns | `catchment_area_km2`, `peak_flow_cms` |
| Constants | `UPPER_SNAKE_CASE` | `DEFAULT_THRESHOLD_M3S` |
| Script files | Date-prefixed, descriptive | `2026-02_flow_ensemble_aggregation.R` |

---

## 4. Mandatory header block

Every script and function file must open with this block, completed in full:

```r
# ============================================================ #
# Tool:         [Tool name]
# Description:  [One-sentence description of what this does]
# Flode Module: [Target module, e.g. reach.hydro - or 'standalone']
# Author:       [Name, email]
# Created:      [YYYY-MM-DD]
# Modified:     [YYYY-MM-DD] - [initials]: [change summary]
# Tier:         [1 / 2 / 3]
# Inputs:       [Describe inputs and expected formats]
# Outputs:      [Describe outputs and formats]
# Dependencies: [List non-base packages; flag any non-fastverse choices]
# ============================================================ #
```

No script is compliant without this block. If you create or edit a script and it lacks the header, add it.

---

## 5. OOP hierarchy

New Flode classes must use the correct OOP system:

| System | Use when | Avoid when |
|---|---|---|
| **S7** (preferred) | Defining new exported Flode classes; formal validated contracts | Rapid Tier 3 prototyping |
| **R6** | Stateful objects with lifecycle (`initialize` / `finalize`); reference semantics required | General data representation -- use S7 instead |
| **S3** | Lightweight method dispatch: `print`, `summary` for existing Flode classes | New exported Flode classes -- use S7 |
| **S4** | Interoperability with `terra`, `sp` only | All new development |

S7 example:
```r
library(S7)

FlodeCatchment <- new_class(
  "FlodeCatchment",
  properties = list(
    gauge_id    = class_character,
    area_km2    = class_double,
    tier        = class_integer
  )
)
```

S7 properties should be typed. Validators must be present for Tier 1 and Tier 2 classes. R6 classes must have a `print` method.

---

## 6. File formats

| Format | Use |
|---|---|
| Parquet (`.parquet`) | Preferred for all large tabular outputs. Use `arrow::write_parquet()` / `read_parquet()`. |
| CSV (`.csv`) | Small exchange files under ~10,000 rows. Use `data.table::fwrite()` only. |
| netCDF (`.nc`) | Gridded spatial outputs. Use `ncdf4` or `terra`. |
| RDS (`.rds`) | R-specific intermediate objects. Use `saveRDS()` / `readRDS()`. |
| Feather (`.feather`) | High-speed intermediate files within a single pipeline. |
| Excel (`.xlsx`) | Final-output reports and stakeholder deliverables only. Use `openxlsx2`. |

**Never use `.RData` files.** Never use `write.csv()`.

---

## 7. Testing and code quality by tier

| Tier | Requirements |
|---|---|
| **Tier 1 -- Operational** | `testthat` unit tests mandatory; 70% line coverage via `covr`; `lintr` must pass (failures block merge); `styler` advisory; `renv::status()` must pass |
| **Tier 2 -- Analytical** | Tests recommended; `lintr` advisory |
| **Tier 3 -- Experimental** | Inline comments sufficient |

Testing standards for Tier 1:
- Unit tests cover expected outputs, edge cases (empty inputs, NA values, out-of-range data), and known failure modes
- Test files live in `/tests/testthat/` following R package conventions
- Use small, embedded data fixtures -- no external file dependencies in tests

Automated checks summary:

| Tool | Purpose | Blocks merge? |
|---|---|---|
| `lintr` | Static analysis, style violations | Yes (Tier 1) |
| `styler` | Auto-reformatting | No (advisory) |
| `testthat` | Test suite | Yes |
| `renv::status()` | Lockfile consistency | Yes (Tier 1-2) |
| `covr` | Line coverage | Yes, if below 70% (Tier 1) |

---

## 8. Reproducibility with renv

All team R repositories must use `renv`.

```r
# New repository
renv::init()

# Before any commit that adds or updates a package
renv::snapshot()    # then commit renv.lock

# First step for a new team member
renv::restore()
```

`renv.lock` must always be committed with dependency changes. A fresh R session must be able to run the tool after `renv::restore()` with no undeclared dependencies.

---

## 9. Repository structure

```
flood-forecast-tools/
├── operational/        # Tier 1 tools
├── analytical/         # Tier 2 tools
├── experimental/       # Tier 3 tools
├── shared-functions/   # Shared R function library
├── tests/              # testthat test suites
├── docs/               # Documentation and runbooks
├── renv/               # renv lockfile
└── README.md
```

Paths must never be hard-coded. Use `here::here()` for portable path management.

Scripts must not exceed 300 lines. Longer scripts should be refactored into functions or sub-scripts.

---

## 10. Documentation by tier

| Tier | Required |
|---|---|
| Tier 1 | Header block; roxygen2 for all exported functions; `README.md`; user guide or runbook; changelog in Git |
| Tier 2 | Header block; roxygen2 for key functions; `README.md` |
| Tier 3 | Header block; inline comments sufficient |

---

## 11. Anti-patterns at a glance

```r
# Hard-coded paths
data <- fread("C:/Users/jane/data/gauges.csv")   # use here::here()

# Tidyverse in Tier 1 / Flode
library(dplyr); flow %>% filter(q > 100)         # use data.table

# Wrong OOP system for a new Flode class
setClass("FlodeCatchment", ...)                   # S4 -- use S7

# .RData persistence
save(flow_dt, file = "session.RData")             # use saveRDS()

# CSV with base R
write.csv(flow_dt, "output.csv")                  # use fwrite()

# Missing header block
calc_flood_peak <- function(q, threshold) { ... } # add header to file

# S4 for new development outside terra/sp interop
setClass("MyClass", ...)                          # use S7 or R6
```

---

## References

- `03-r-code-governance.qmd` -- authoritative source for all standards above
- `01-governance-framework.qmd` -- parent framework: roles, tiers, routes to development, version control
- data.table wiki: `rdatatable.gitlab.io/data.table/`
- fastverse docs: `fastverse.github.io/fastverse/`
- S7 docs: `rconsortium.github.io/S7/`
