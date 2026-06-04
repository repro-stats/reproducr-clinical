# reproducr-example-clinical <a href="https://repro-stats.github.io/reproducr/"><img src="https://raw.githubusercontent.com/repro-stats/reproducr/main/man/figures/logo.svg" align="right" height="120" alt="reproducr website" /></a>

<!-- badges: start -->
[![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)](https://repro-stats.github.io/reproducr/)
[![R-CMD-check](https://github.com/repro-stats/reproducr-example-clinical/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/repro-stats/reproducr-example-clinical/actions/workflows/R-CMD-check.yml)
<!-- badges: end -->

> A clinical trial end-to-end pipeline demonstrating
> [`reproducr`](https://github.com/repro-stats/reproducr) with `renv` —
> the complete reproducibility stack for regulated analytical workflows.

**See the full walkthrough: [`DEMO.md`](DEMO.md)**

---

## This example vs reproducr-example

| | [reproducr-example](https://github.com/repro-stats/reproducr-example) | this repo |
|---|---|---|
| Domain | Ecology / penguins | Clinical trials / oncology |
| `renv` | No | **Yes** |
| Report style | minimal | **pharma** |
| Analysis | Linear regression, CV | Survival, Cox PH, log-rank |
| Outputs certified | 12 | **20** |
| Intended audience | General R users | Biostatisticians, CROs, pharma |

Together they demonstrate that `reproducr` is environment-agnostic — it works
with or without `renv`, across domains, and at any level of regulatory rigour.

---

## The reproducibility stack

```
renv.lock       ←  survival 3.7-0 pinned  (renv's job)
.reproducr.rds  ←  HR = 0.582 certified   (reproducr's job)
```

`renv` ensures the same packages are installed on every machine and every
CI run. `reproducr` ensures those packages produce the same numerical results.
They solve different problems and belong together.

---

## The trial

A simulated Phase III oncology trial (n = 400) comparing Treatment vs Control.

- **Primary endpoint:** Overall survival
- **Design:** Two-arm RCT, 1:1 randomisation
- **Covariates:** Age, sex, ECOG performance status
- **Follow-up:** 6–36 months

### Key results

| | Control | Treatment |
|---|---|---|
| N | 206 | 194 |
| Events | 136 (66%) | 95 (49%) |
| Median OS | 13.7 months | 22.7 months |
| 12-month survival | 56.8% | 67.3% |

**HR (Treatment vs Control): 0.582 (95% CI: 0.446–0.760, p < 0.001)**

Log-rank test: χ² = 13.931, p = 0.000190

---

## Reproducibility pipeline

### Tier 1 — Scan and score

```r
library(reproducr)
source("analysis.R")

# renv = TRUE reads versions from renv.lock
report <- audit_script("analysis.R", renv = TRUE, verbose = FALSE)
risks  <- risk_score(report)
print(risks)
#>
#> -- reproducr risk score --
#>
#>   No risks detected. All checks passed.
```

### Tier 2 — Certify and check drift

```r
certify(OUTPUTS, tag = "baseline-v1", script = "analysis.R")
#> reproducr: certified 20 output(s) [2026-06-01] under tag 'baseline-v1'

check_drift(OUTPUTS, against = "latest")
#>
#> -- reproducr drift check vs 'baseline-v1' --
#>
#>   Verdict  : ALL OUTPUTS MATCH
#>   OK       : 20
#>   Drifted  : 0
```

### Tier 3 — Pharma QC report

```r
repro_report(report, risks, drift = drift,
             format      = "html",
             style       = "pharma",
             output_file = "qc_report.html")
```

Generates a self-contained HTML QC document with execution environment,
package inventory, risk register, drift assessment, and sign-off fields —
suitable for regulatory submission.

---

## CI/CD

The GitHub Actions workflow runs on every push to `main` and weekly:

1. `setup-renv@v2` restores the locked environment from `renv.lock`
2. Sources `analysis.R` to produce `OUTPUTS`
3. Audits with `audit_script(renv = TRUE)` — versions from lockfile
4. Checks drift against last certified run
5. Certifies the current run
6. Generates `reproducibility_report.md` in pharma style
7. Updates the badge and commits

---

## Running locally

```r
# 1. Restore the locked environment
renv::restore()

# 2. Install reproducr
install.packages("remotes")
remotes::install_github("repro-stats/reproducr")

# 3. Run the analysis
source("analysis.R")

# 4. Full reproducr pipeline
library(reproducr)
report <- audit_script("analysis.R", renv = TRUE, verbose = FALSE)
risks  <- risk_score(report)

certify(OUTPUTS, tag = "local-run")
check_drift(OUTPUTS, against = "local-run")

repro_report(report, risks, format = "html", style = "pharma",
             output_file = "qc_report.html")
```

---

## Certification history

```r
library(reproducr)
list_certs()
```

The `.reproducr.rds` file is committed to version control and accumulates
a certification record on every CI run — providing a complete,
timestamped audit trail.

---

## About

This is a companion repository to the
[`reproducr`](https://github.com/repro-stats/reproducr) R package,
demonstrating the full pipeline in a clinical trial context with `renv`.

See also: [`reproducr-example`](https://github.com/repro-stats/reproducr-example)
(ecology example, no renv) for a simpler starting point.
