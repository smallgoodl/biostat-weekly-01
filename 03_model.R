# =====================================================================
# 03_model.R — Kaplan–Meier + Cox 比例风险模型 / Kaplan–Meier + Cox proportional hazards model
# 研究问题 / Question: ECOG / 性别 / 年龄 与总生存的关系
#                      / Association of ECOG, sex and age with overall survival
# =====================================================================

# survival：KM、log-rank、Cox；broom：把模型结果整理成数据框
# survival: KM, log-rank, Cox;  broom: tidy model results into data frames
suppressPackageStartupMessages({
  library(tidyverse)
  library(survival)
  library(broom)
})

# 读取清洗后的数据 / Read the cleaned data
analysis <- readRDS("data/lung_clean.rds")

# Surv 对象：把“时间 + 是否死亡”打包成生存结局；事件为死亡，event=0 为删失
# Surv object: bundles "time + death indicator" into a survival outcome; event = death, 0 = censored
analysis <- analysis %>%
  mutate(surv = Surv(time, event))

# ---- 1. Kaplan–Meier：按性别 / KM by sex ----
# KM 是非参数方法，估计生存函数 S(t)，能正确处理删失
# KM is non-parametric: it estimates the survival function S(t) and handles censoring correctly
km_sex <- survfit(surv ~ sex, data = analysis)
message("\n===== KM：按性别 =====")
print(km_sex)
# log-rank 检验：H0 为两组生存曲线无差异（全程平均加权的比较）
# Log-rank test: H0 = no difference between the survival curves (compares the whole follow-up)
message("\nLog-rank (sex):")
print(survdiff(surv ~ sex, data = analysis))

# ---- 2. Kaplan–Meier：按 ECOG / KM by ECOG ----
km_ecog <- survfit(surv ~ ecog, data = analysis)
message("\n===== KM：按 ECOG =====")
print(km_ecog)
# 三组的整体 log-rank 检验（自由度 2）/ Overall 3-group log-rank test (2 df)
message("\nLog-rank (ecog):")
print(survdiff(surv ~ ecog, data = analysis))

# 中位生存时间表 / Median survival tables
med_sex <- broom::tidy(km_sex) # 逐步曲线点（此处未直接使用）；中位数用 summary()$table 即可
                               # / step-wise curve points (not used further); medians come from summary()$table
km_med <- summary(km_sex)$table
km_med_ecog <- summary(km_ecog)$table
write.csv(km_med, "output/km_median_by_sex.csv")
write.csv(km_med_ecog, "output/km_median_by_ecog.csv")

# ---- 3. 多因素 Cox PH / Multivariable Cox PH ----
# 参考水平 / Reference levels: Male（sex 因子第一水平 / first level of the sex factor）、ECOG=0；
# 年龄为连续变量，HR 对应“每增加 1 岁” / age is continuous, so its HR is "per 1 year".
# 因此 sexFemale 的 HR 是 女性 vs 男性 / so the sexFemale HR is Female vs Male.
# Cox 模型：h(t|x) = h0(t) * exp(b'x)，HR = exp(b)；HR>1 表示风险更高，<1 表示更低
# Cox model: h(t|x) = h0(t) * exp(b'x), HR = exp(b); HR > 1 = higher hazard, < 1 = lower
cox_fit <- coxph(
  Surv(time, event) ~ age + sex + ecog,
  data = analysis
)

message("\n===== Cox PH 模型 =====")
print(summary(cox_fit))

# HR + 95% CI 表 / HR + 95% CI table
# exponentiate = TRUE：把对数风险比还原为 HR / convert log-hazard coefficients back to HR
cox_tbl <- broom::tidy(cox_fit, exponentiate = TRUE, conf.int = TRUE) %>%
  select(term, estimate, conf.low, conf.high, p.value) %>%
  rename(HR = estimate, CI_low = conf.low, CI_high = conf.high, p = p.value) %>%
  mutate(
    # 保留 3 位小数；p 值保留 3 位有效数字 / 3 decimals; p-values to 3 significant digits
    across(c(HR, CI_low, CI_high), ~ round(.x, 3)),
    p = signif(p, 3),
    HR_CI = sprintf("%.3f (%.3f–%.3f)", HR, CI_low, CI_high)
  )

write_csv(cox_tbl, "output/cox_results.csv")
message("\nCox HR 表:")
print(cox_tbl)

# ---- 4. 比例风险假定（Schoenfeld）/ Proportional-hazards assumption (Schoenfeld residuals) ----
# Cox 模型假定 HR 不随时间变化；cox.zph 检验 Schoenfeld 残差与时间是否相关
# The Cox model assumes HRs are constant over time; cox.zph tests whether Schoenfeld residuals correlate with time
# p 较大（如 > 0.05）表示没有发现违反该假定的证据（不等于证明成立）
# A large p (e.g. > 0.05) means no evidence against the assumption (not proof that it holds)
ph_test <- cox.zph(cox_fit)
message("\n===== 比例风险假定 (cox.zph) =====")
print(ph_test)

# GLOBAL 行是整体检验 / the GLOBAL row is the overall test
ph_df <- as.data.frame(ph_test$table) %>%
  rownames_to_column("term")
write_csv(ph_df, "output/ph_assumption.csv")

# 保存模型对象供作图 / Save model objects for the figure script
saveRDS(list(cox = cox_fit, km_sex = km_sex, km_ecog = km_ecog, cox_tbl = cox_tbl),
        "data/models.rds")

message("\n03_model.R 完成。")
