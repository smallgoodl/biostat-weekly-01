# 02_descriptive.R — 基线特征表（按性别分层）
# 输出 CSV + HTML

suppressPackageStartupMessages({
  library(tidyverse)
  library(gtsummary)
  library(gt)
})

analysis <- readRDS("data/lung_clean.rds")

# ---- 基线表：连续变量用中位数(IQR)，分类用 n(%) ----
tbl <- analysis %>%
  select(age, sex, ecog, ph.karno, pat.karno, wt.loss, meal.cal, event) %>%
  mutate(event = factor(event, levels = c(0, 1), labels = c("Censored", "Death"))) %>%
  tbl_summary(
    by = sex,
    label = list(
      age ~ "Age (years)",
      ecog ~ "ECOG performance status",
      ph.karno ~ "Karnofsky (physician)",
      pat.karno ~ "Karnofsky (patient)",
      wt.loss ~ "Weight loss (lbs)",
      meal.cal ~ "Calories per meal",
      event ~ "Vital status"
    ),
    statistic = list(
      all_continuous() ~ "{median} ({p25}, {p75})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    missing = "no"
  ) %>%
  add_p() %>%
  add_overall() %>%
  modify_header(label ~ "**Characteristic**") %>%
  modify_spanning_header(c("stat_1", "stat_2") ~ "**Sex**") %>%
  bold_labels()

# ---- 导出 ----
# CSV：把 gtsummary 转成数据框
tbl_df <- as_tibble(tbl, col_labels = TRUE)
write_csv(tbl_df, "output/baseline_table.csv")

# HTML
tbl %>%
  as_gt() %>%
  gt::gtsave("output/baseline_table.html")

# 控制台也打印一份简表
message("\n===== 基线表（按性别）=====")
invisible(tbl)

# 额外：事件率与随访时间摘要
surv_sum <- analysis %>%
  summarise(
    n = n(),
    deaths = sum(event),
    median_fu_days = median(time),
    median_fu_months = round(median(time) / 30.44, 1)
  )
write_csv(surv_sum, "output/followup_summary.csv")
message("\n随访摘要已写 output/followup_summary.csv")
message("02_descriptive.R 完成。")
