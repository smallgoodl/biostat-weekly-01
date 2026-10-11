# =====================================================================
# 04_figures.R — KM 曲线与 Cox 森林图 / KM curves and Cox forest plot
# 图形保存为 PNG 到 output/（图中文字保持英文）
# Figures are saved as PNG files in output/ (figure text stays in English)
# =====================================================================

# survminer：ggsurvplot 画 KM 曲线 + 在险人数表；ggplot2（含在 tidyverse 中）画森林图
# survminer: ggsurvplot draws KM curves + numbers-at-risk table; ggplot2 (in tidyverse) draws the forest plot

suppressPackageStartupMessages({
  library(tidyverse)
  library(survival)
  library(survminer)
})

# 读取清洗数据与模型结果 / Read the cleaned data and model results
analysis <- readRDS("data/lung_clean.rds")
models <- readRDS("data/models.rds")

# ---- KM：按性别 / KM by sex ----
# 拟合 KM；conf.int=TRUE 画 95% 置信带；pval=TRUE 标注 log-rank p 值；risk.table 在图下方显示各时点在险人数
# Fit KM; conf.int = TRUE draws 95% bands; pval = TRUE prints the log-rank p-value; risk.table shows numbers at risk below
fit_sex <- survfit(Surv(time, event) ~ sex, data = analysis)

p_sex <- ggsurvplot(
  fit_sex,
  data = analysis,
  risk.table = TRUE,
  pval = TRUE,
  conf.int = TRUE,
  xlab = "Time (days)",
  ylab = "Overall survival",
  title = "Kaplan-Meier by sex (NCCTG lung)",
  legend.title = "Sex",
  legend.labs = levels(analysis$sex),
  break.time.by = 200,
  ggtheme = theme_bw(base_size = 12)
)

# 用 survminer 推荐方式保存组合图（曲线+风险表）/ Save the combined plot (curve + risk table) the survminer-recommended way
ggsave(
  filename = "output/km_by_sex.png",
  plot = print(p_sex, newpage = FALSE),
  width = 8, height = 7, dpi = 150, bg = "white"
)
message("已保存 output/km_by_sex.png")

# ---- KM：按 ECOG / KM by ECOG ----
# ECOG 体力状态：0=无症状，1=有症状但可活动，2+=日间卧床时间更多；conf.int=FALSE 避免三组置信带重叠过乱
# ECOG status: 0 = asymptomatic, 1 = symptomatic but ambulatory, 2+ = in bed more of the day;
# conf.int = FALSE avoids cluttered overlapping bands for three groups
fit_ecog <- survfit(Surv(time, event) ~ ecog, data = analysis)

p_ecog <- ggsurvplot(
  fit_ecog,
  data = analysis,
  risk.table = TRUE,
  pval = TRUE,
  conf.int = FALSE,
  xlab = "Time (days)",
  ylab = "Overall survival",
  title = "Kaplan-Meier by ECOG (NCCTG lung)",
  legend.title = "ECOG",
  legend.labs = levels(analysis$ecog),
  break.time.by = 200,
  palette = "Dark2",
  ggtheme = theme_bw(base_size = 12)
)

ggsave(
  filename = "output/km_by_ecog.png",
  plot = print(p_ecog, newpage = FALSE),
  width = 8, height = 7, dpi = 150, bg = "white"
)
message("已保存 output/km_by_ecog.png")

# ---- Cox 森林图（HR + 95% CI）/ Cox forest plot (HR + 95% CI) ----
# 森林图含义：每行一个变量，点 = 风险比 HR，横线 = 95% 置信区间；
# 虚线 HR=1 表示“无效应”，区间不跨过 1 即在 5% 水平显著；HR<1 风险更低，HR>1 风险更高
# How to read it: one row per term, dot = hazard ratio, bar = 95% CI; the dashed line at HR = 1 means "no effect";
# a CI not crossing 1 is significant at the 5% level; HR < 1 = lower hazard, HR > 1 = higher hazard
# 参考水平：Male 在因子里是第一水平，模型里对比的是 Female vs Male / Reference: Male is the first factor level, so the model contrasts Female vs Male
# broom 给出 sexFemale；这里把模型项名换成易读标签 / broom reports "sexFemale"; here we map term names to readable labels
cox_tbl <- models$cox_tbl %>%
  mutate(
    label = case_when(
      term == "age" ~ "Age (per year)",
      term == "sexFemale" ~ "Female (vs Male)",
      term == "sexMale" ~ "Male (vs Female)",
      term == "ecog1" ~ "ECOG 1 (vs 0)",
      term == "ecog2+" ~ "ECOG 2+ (vs 0)",
      TRUE ~ term
    )
  ) %>%
  # 反转水平，使第一项显示在图最上方 / reverse levels so the first term is at the top
  mutate(label = factor(label, levels = rev(label)))

p_forest <- ggplot(cox_tbl, aes(x = HR, y = label)) +
  # HR=1 参考线 / reference line at HR = 1
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey40") +
  # 95% 置信区间 / 95% CI bars
  geom_errorbar(aes(xmin = CI_low, xmax = CI_high), width = 0.2, orientation = "y", color = "#2c3e50") +
  # HR 点估计 / HR point estimates
  geom_point(size = 3, color = "#c0392b") +
  # 对数刻度：HR 是比值，对数轴上 0.5 与 2 对称 / log scale: HR is a ratio, so 0.5 and 2 are symmetric
  scale_x_log10(breaks = c(0.5, 1, 2, 4, 8)) +
  labs(
    title = "Cox PH: hazard ratios for overall survival",
    subtitle = "NCCTG lung cancer (complete-case n)",
    x = "Hazard ratio (log scale)",
    y = NULL,
    caption = "Adjusted for age, sex, and ECOG"
  ) +
  theme_bw(base_size = 12) +
  theme(panel.grid.minor = element_blank())

ggsave("output/cox_forest.png", p_forest, width = 7, height = 4.5, dpi = 150, bg = "white")
message("已保存 output/cox_forest.png")

message("04_figures.R 完成。")
