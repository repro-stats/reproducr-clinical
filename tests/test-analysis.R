library(testthat)
library(survival)

# Source the analysis
source(file.path(dirname(dirname(sys.frame(1)$ofile)), "analysis.R"),
       chdir = TRUE)

# Helper — fall back for running interactively
if (!exists("OUTPUTS")) source("analysis.R")

# ---- Trial design -----------------------------------------------------------

test_that("trial has the expected sample size", {
  expect_equal(OUTPUTS$n_total, 400L)
})

test_that("arms are balanced (within 10%)", {
  ratio <- OUTPUTS$n_treatment / OUTPUTS$n_control
  expect_true(ratio > 0.80 && ratio < 1.25)
})

test_that("event rate is in a plausible range for oncology trial", {
  expect_true(OUTPUTS$event_rate > 0.40)
  expect_true(OUTPUTS$event_rate < 0.80)
})

# ---- Kaplan-Meier -----------------------------------------------------------

test_that("treatment arm has longer median OS than control", {
  expect_true(OUTPUTS$median_os_treatment > OUTPUTS$median_os_control)
})

test_that("12-month survival is higher in treatment arm", {
  expect_true(OUTPUTS$surv_12m_treatment > OUTPUTS$surv_12m_control)
})

test_that("median OS values are positive and plausible", {
  expect_true(OUTPUTS$median_os_control   > 0)
  expect_true(OUTPUTS$median_os_treatment > 0)
  expect_true(OUTPUTS$median_os_control   < 60)
  expect_true(OUTPUTS$median_os_treatment < 60)
})

test_that("landmark table has correct structure", {
  expect_true(is.data.frame(OUTPUTS$landmark_table))
  expect_true(all(c("arm", "time", "surv", "lower", "upper")
                  %in% names(OUTPUTS$landmark_table)))
  expect_equal(nrow(OUTPUTS$landmark_table), 8L)  # 4 timepoints x 2 arms
})

test_that("survival probabilities are between 0 and 1", {
  expect_true(all(OUTPUTS$landmark_table$surv  >= 0))
  expect_true(all(OUTPUTS$landmark_table$surv  <= 1))
  expect_true(all(OUTPUTS$landmark_table$lower >= 0))
  expect_true(all(OUTPUTS$landmark_table$upper <= 1))
})

# ---- Log-rank test ----------------------------------------------------------

test_that("log-rank test is statistically significant", {
  expect_true(OUTPUTS$lr_pval < 0.05)
})

test_that("log-rank chi-squared is positive", {
  expect_true(OUTPUTS$lr_chisq > 0)
})

# ---- Cox model --------------------------------------------------------------

test_that("treatment HR is below 1 (protective effect)", {
  expect_true(OUTPUTS$hr_est < 1.0)
})

test_that("treatment HR is in a plausible range", {
  expect_true(OUTPUTS$hr_est > 0.30)
  expect_true(OUTPUTS$hr_est < 0.95)
})

test_that("95% CI for HR does not cross 1", {
  expect_true(OUTPUTS$hr_hi < 1.0)
})

test_that("Cox model p-value for treatment is significant", {
  expect_true(OUTPUTS$cox_pval < 0.01)
})

test_that("concordance is above 0.5 (better than chance)", {
  expect_true(OUTPUTS$concordance > 0.5)
})

test_that("Cox table has expected covariates", {
  expect_true("armTreatment" %in% rownames(OUTPUTS$cox_table))
  expect_true("age"          %in% rownames(OUTPUTS$cox_table))
  expect_true("ecog1"        %in% rownames(OUTPUTS$cox_table))
  expect_true("ecog2"        %in% rownames(OUTPUTS$cox_table))
})

# ---- OUTPUTS completeness ---------------------------------------------------

test_that("OUTPUTS contains all required keys", {
  required <- c(
    "n_total", "n_control", "n_treatment", "n_events", "event_rate",
    "baseline_table", "median_os_control", "median_os_treatment",
    "landmark_table", "surv_12m_control", "surv_12m_treatment",
    "lr_chisq", "lr_pval",
    "hr_est", "hr_lo", "hr_hi", "cox_pval",
    "cox_table", "concordance", "lr_test_pval"
  )
  expect_true(all(required %in% names(OUTPUTS)))
})

test_that("baseline_table has expected structure", {
  expect_true(is.data.frame(OUTPUTS$baseline_table))
  expect_true(all(c("characteristic", "control", "treatment")
                  %in% names(OUTPUTS$baseline_table)))
})
