# 03_model.R — Kaplan–Meier + Cox 比例风险模型
# 研究问题：ECOG / 性别 / 年龄 与总生存的关系

suppressPackageStartupMessages({
  library(tidyverse)
  library(survival)
  library(broom)
})

analysis <- readRDS("data/lung_clean.rds")

# Surv 对象：事件为死亡
analysis <- analysis %>%
  mutate(surv = Surv(time, event))

# ---- 1. Kaplan–Meier：按性别 ----
km_sex <- survfit(surv ~ sex, data = analysis)
message("\n===== KM：按性别 =====")
print(km_sex)
message("\nLog-rank (sex):")
print(survdiff(surv ~ sex, data = analysis))

# ---- 2. Kaplan–Meier：按 ECOG ----
km_ecog <- survfit(surv ~ ecog, data = analysis)
message("\n===== KM：按 ECOG =====")
print(km_ecog)
message("\nLog-rank (ecog):")
print(survdiff(surv ~ ecog, data = analysis))

# 中位生存时间表
med_sex <- broom::tidy(km_sex) # 逐步曲线点；中位用 print 摘要即可
km_med <- summary(km_sex)$table
km_med_ecog <- summary(km_ecog)$table
write.csv(km_med, "output/km_median_by_sex.csv")
write.csv(km_med_ecog, "output/km_median_by_ecog.csv")

# ---- 3. 多因素 Cox PH ----
# 参考水平：Female, ECOG=0；年龄按每 10 岁
cox_fit <- coxph(
  Surv(time, event) ~ age + sex + ecog,
  data = analysis
)

message("\n===== Cox PH 模型 =====")
print(summary(cox_fit))

# HR + 95% CI 表
cox_tbl <- broom::tidy(cox_fit, exponentiate = TRUE, conf.int = TRUE) %>%
  select(term, estimate, conf.low, conf.high, p.value) %>%
  rename(HR = estimate, CI_low = conf.low, CI_high = conf.high, p = p.value) %>%
  mutate(
    across(c(HR, CI_low, CI_high), ~ round(.x, 3)),
    p = signif(p, 3),
    HR_CI = sprintf("%.3f (%.3f–%.3f)", HR, CI_low, CI_high)
  )

write_csv(cox_tbl, "output/cox_results.csv")
message("\nCox HR 表:")
print(cox_tbl)

# ---- 4. 比例风险假定（Schoenfeld）----
ph_test <- cox.zph(cox_fit)
message("\n===== 比例风险假定 (cox.zph) =====")
print(ph_test)

ph_df <- as.data.frame(ph_test$table) %>%
  rownames_to_column("term")
write_csv(ph_df, "output/ph_assumption.csv")

# 保存模型对象供作图
saveRDS(list(cox = cox_fit, km_sex = km_sex, km_ecog = km_ecog, cox_tbl = cox_tbl),
        "data/models.rds")

message("\n03_model.R 完成。")
