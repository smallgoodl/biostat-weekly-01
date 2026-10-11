# =====================================================================
# 02_descriptive.R — 基线特征表（按性别分层）/ Baseline characteristics table (stratified by sex)
# 输出 CSV + HTML / Outputs: CSV + HTML
# =====================================================================

# gtsummary 生成论文风格的汇总表；gt 负责导出 HTML
# gtsummary builds publication-style summary tables; gt exports them to HTML
suppressPackageStartupMessages({
  library(tidyverse)
  library(gtsummary)
  library(gt)
})

# 读取上一步清洗好的分析数据 / Read the cleaned data from step 01
analysis <- readRDS("data/lung_clean.rds")

# ---- 基线表：连续变量用中位数(IQR)，分类用 n(%) ----
# ---- Baseline table: median (IQR) for continuous variables, n (%) for categorical ----
# 为什么用中位数(IQR)：lung 中 wt.loss、meal.cal 等偏态，中位数更稳健
# Why median (IQR): variables such as wt.loss and meal.cal are skewed; the median is more robust
tbl <- analysis %>%
  select(age, sex, ecog, ph.karno, pat.karno, wt.loss, meal.cal, event) %>%
  # 把 0/1 事件变成可读标签 / Turn the 0/1 event into readable labels
  mutate(event = factor(event, levels = c(0, 1), labels = c("Censored", "Death"))) %>%
  tbl_summary(
    by = sex,  # 按性别分列 / one column per sex
    # 表中显示的变量名（英文，便于直接放入论文风格表格）
    # Display labels (kept in English for publication-style tables)
    label = list(
      age ~ "Age (years)",
      ecog ~ "ECOG performance status",
      ph.karno ~ "Karnofsky (physician)",
      pat.karno ~ "Karnofsky (patient)",
      wt.loss ~ "Weight loss (lbs)",
      meal.cal ~ "Calories per meal",
      event ~ "Vital status"
    ),
    # 汇总统计量的格式 / Format of the summary statistics
    statistic = list(
      all_continuous() ~ "{median} ({p25}, {p75})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    missing = "no"  # 不单独显示缺失行 / do not show a separate missing row
  ) %>%
  add_p() %>%         # 组间比较 p 值（连续：Wilcoxon 秩和；分类：卡方/Fisher）/ between-group p-values (Wilcoxon rank-sum for continuous; chi-square/Fisher for categorical)
  add_overall() %>%   # 增加“合计”列 / add an overall column
  modify_header(label ~ "**Characteristic**") %>%
  modify_spanning_header(c("stat_1", "stat_2") ~ "**Sex**") %>%
  bold_labels()

# ---- 导出 / Export ----
# CSV：把 gtsummary 转成数据框 / CSV: convert the gtsummary object to a data frame
tbl_df <- as_tibble(tbl, col_labels = TRUE)
write_csv(tbl_df, "output/baseline_table.csv")

# HTML：转成 gt 对象后保存 / HTML: convert to a gt object and save
tbl %>%
  as_gt() %>%
  gt::gtsave("output/baseline_table.html")

# 控制台也打印一份简表 / Also announce the table on the console
message("\n===== 基线表（按性别）=====")
invisible(tbl)

# 额外：事件率与随访时间摘要 / Extra: event count and follow-up summary
# 注意：这里是所有人的观察时间中位数（含删失），不是反向 KM 的中位随访
# Note: this is the median observation time of everyone (including censored), not the reverse-KM median follow-up
surv_sum <- analysis %>%
  summarise(
    n = n(),                                          # 分析样本量 / analysis sample size
    deaths = sum(event),                              # 死亡例数 / number of deaths
    median_fu_days = median(time),                    # 观察时间中位数（天）/ median observation time (days)
    median_fu_months = round(median(time) / 30.44, 1) # 换算为月（30.44 天/月）/ in months (30.44 days/month)
  )
write_csv(surv_sum, "output/followup_summary.csv")
message("\n随访摘要已写 output/followup_summary.csv")
message("02_descriptive.R 完成。")
