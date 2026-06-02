# Simulated Phase III Oncology Trial — Time-to-Event Analysis
# reproducr-example-clinical: https://github.com/reproducr-dev/reproducr-example-clinical
#
# Two-arm randomised controlled trial comparing Treatment vs Control
# in patients with advanced solid tumours.
#
# Primary endpoint: Overall survival (time to death or censoring)
# Secondary endpoints: Landmark survival rates, HR by subgroup
#
# Reproducibility standards:
#   - All qualified calls use pkg::fn namespace
#   - All stochastic calls are seeded
#   - Key outputs collected in OUTPUTS for reproducr certification

# ---- data simulation --------------------------------------------------------
# In a real trial this would be: trial_data <- readr::read_csv("data/trial.csv")
# Here we simulate realistic trial data with a known treatment effect.

set.seed(2024L)
n <- 400L

age  <- round(stats::rnorm(n, mean = 58, sd = 10))
sex  <- stats::rbinom(n, 1, 0.45)
ecog <- sample(0:2, n, replace = TRUE, prob = c(0.4, 0.4, 0.2))
arm  <- stats::rbinom(n, 1, 0.5)   # 1 = Treatment, 0 = Control

# Simulate time-to-event under proportional hazards
# True HR for treatment = 0.65; age, ECOG are prognostic
baseline_hazard <- 0.04
hr_treatment    <- 0.65
hr_age          <- 1.02
hr_ecog         <- 1.35

lambda <- baseline_hazard *
  (hr_treatment ^ arm) *
  (hr_age       ^ ((age - 58) / 10)) *
  (hr_ecog      ^ ecog)

time_event  <- stats::rexp(n, rate = lambda)
time_censor <- stats::runif(n, min = 6, max = 36)
time        <- pmin(time_event, time_censor)
status      <- as.integer(time_event <= time_censor)

trial_data <- data.frame(
  id     = seq_len(n),
  arm    = factor(arm, levels = c(0, 1),
                  labels = c("Control", "Treatment")),
  age    = age,
  sex    = factor(sex, levels = c(0, 1),
                  labels = c("Male", "Female")),
  ecog   = factor(ecog, levels = c(0, 1, 2),
                  labels = c("0", "1", "2")),
  time   = round(time, 2),
  status = status,
  stringsAsFactors = FALSE
)

# ---- baseline characteristics -----------------------------------------------

baseline_table <- data.frame(
  characteristic = c("N", "Age (mean, SD)", "Female (%)",
                      "ECOG 0 (%)", "ECOG 1 (%)", "ECOG 2 (%)",
                      "Events (%)", "Median follow-up (months)"),
  control = c(
    sum(trial_data$arm == "Control"),
    sprintf("%.1f (%.1f)",
            mean(trial_data$age[trial_data$arm == "Control"]),
            stats::sd(trial_data$age[trial_data$arm == "Control"])),
    sprintf("%.1f",
            100 * mean(trial_data$sex[trial_data$arm == "Control"] == "Female")),
    sprintf("%.1f",
            100 * mean(trial_data$ecog[trial_data$arm == "Control"] == "0")),
    sprintf("%.1f",
            100 * mean(trial_data$ecog[trial_data$arm == "Control"] == "1")),
    sprintf("%.1f",
            100 * mean(trial_data$ecog[trial_data$arm == "Control"] == "2")),
    sprintf("%.1f",
            100 * mean(trial_data$status[trial_data$arm == "Control"])),
    sprintf("%.1f",
            stats::median(trial_data$time[trial_data$arm == "Control"]))
  ),
  treatment = c(
    sum(trial_data$arm == "Treatment"),
    sprintf("%.1f (%.1f)",
            mean(trial_data$age[trial_data$arm == "Treatment"]),
            stats::sd(trial_data$age[trial_data$arm == "Treatment"])),
    sprintf("%.1f",
            100 * mean(trial_data$sex[trial_data$arm == "Treatment"] == "Female")),
    sprintf("%.1f",
            100 * mean(trial_data$ecog[trial_data$arm == "Treatment"] == "0")),
    sprintf("%.1f",
            100 * mean(trial_data$ecog[trial_data$arm == "Treatment"] == "1")),
    sprintf("%.1f",
            100 * mean(trial_data$ecog[trial_data$arm == "Treatment"] == "2")),
    sprintf("%.1f",
            100 * mean(trial_data$status[trial_data$arm == "Treatment"])),
    sprintf("%.1f",
            stats::median(trial_data$time[trial_data$arm == "Treatment"]))
  ),
  stringsAsFactors = FALSE
)

# ---- Kaplan-Meier -----------------------------------------------------------

km_overall <- survival::survfit(
  survival::Surv(time, status) ~ arm,
  data    = trial_data,
  conf.int = 0.95
)

km_control <- survival::survfit(
  survival::Surv(time, status) ~ 1,
  data = trial_data[trial_data$arm == "Control", ]
)

km_treatment <- survival::survfit(
  survival::Surv(time, status) ~ 1,
  data = trial_data[trial_data$arm == "Treatment", ]
)

# Landmark survival at 6, 12, 18, 24 months
km_landmarks <- summary(km_overall, times = c(6, 12, 18, 24))

landmark_table <- data.frame(
  arm   = as.character(km_landmarks$strata),
  time  = km_landmarks$time,
  surv  = round(km_landmarks$surv,  3),
  lower = round(km_landmarks$lower, 3),
  upper = round(km_landmarks$upper, 3),
  stringsAsFactors = FALSE
)

median_control   <- summary(km_control)$table["median"]
median_treatment <- summary(km_treatment)$table["median"]

# ---- Log-rank test ----------------------------------------------------------

lr_test <- survival::survdiff(
  survival::Surv(time, status) ~ arm,
  data = trial_data
)
lr_chisq <- lr_test$chisq
lr_pval  <- 1 - stats::pchisq(lr_chisq, df = 1L)

# ---- Cox proportional hazards -----------------------------------------------

cox_fit <- survival::coxph(
  survival::Surv(time, status) ~ arm + age + sex + ecog,
  data = trial_data
)
cox_summary <- summary(cox_fit)

# Primary endpoint: treatment HR
hr_est <- exp(cox_summary$coefficients["armTreatment", "coef"])
hr_lo  <- exp(cox_summary$conf.int["armTreatment", "lower .95"])
hr_hi  <- exp(cox_summary$conf.int["armTreatment", "upper .95"])
cox_pval <- cox_summary$coefficients["armTreatment", "Pr(>|z|)"]

# Full coefficient table
cox_table <- as.data.frame(cox_summary$coefficients)
cox_table$hr     <- exp(cox_table$coef)
cox_table$hr_lo  <- exp(cox_summary$conf.int[, "lower .95"])
cox_table$hr_hi  <- exp(cox_summary$conf.int[, "upper .95"])

# ---- OUTPUTS ----------------------------------------------------------------
# All values that reproducr will hash and certify on every run.
# Any change following certification will be flagged as drift.

OUTPUTS <- list(

  # --- Trial summary
  n_total        = nrow(trial_data),
  n_control      = sum(trial_data$arm == "Control"),
  n_treatment    = sum(trial_data$arm == "Treatment"),
  n_events       = sum(trial_data$status),
  event_rate     = round(mean(trial_data$status), 4),

  # --- Baseline characteristics
  baseline_table = baseline_table,

  # --- Kaplan-Meier
  median_os_control   = round(median_control,   2),
  median_os_treatment = round(median_treatment, 2),
  landmark_table      = landmark_table,

  # Landmark survival at 12 months
  surv_12m_control   = landmark_table$surv[landmark_table$arm == "arm=Control"   &
                                            landmark_table$time == 12],
  surv_12m_treatment = landmark_table$surv[landmark_table$arm == "arm=Treatment" &
                                            landmark_table$time == 12],

  # --- Log-rank test
  lr_chisq  = round(lr_chisq, 4),
  lr_pval   = round(lr_pval,  6),

  # --- Cox model — primary result
  hr_est    = round(hr_est,   4),
  hr_lo     = round(hr_lo,    4),
  hr_hi     = round(hr_hi,    4),
  cox_pval  = round(cox_pval, 6),

  # --- Cox model — full table
  cox_table = cox_table,

  # --- Model fit
  concordance  = round(cox_summary$concordance[[1]], 4),
  lr_test_pval = round(cox_summary$logtest[[3]],     6)
)
