# 04_figures.R — KM 曲线与 Cox 森林图
# 图形保存为 PNG 到 output/

suppressPackageStartupMessages({
  library(tidyverse)
  library(survival)
  library(survminer)
})

analysis <- readRDS("data/lung_clean.rds")
models <- readRDS("data/models.rds")

# ---- KM：按性别 ----
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

# 用 survminer 推荐方式保存组合图
ggsave(
  filename = "output/km_by_sex.png",
  plot = print(p_sex, newpage = FALSE),
  width = 8, height = 7, dpi = 150, bg = "white"
)
message("已保存 output/km_by_sex.png")

# ---- KM：按 ECOG ----
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

# ---- Cox 森林图（HR + 95% CI）----
# 参考水平：Male 在因子里是第一水平，模型里对比的是 Female vs Male
# broom 给出 sexFemale；标签写清楚
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
  mutate(label = factor(label, levels = rev(label)))

p_forest <- ggplot(cox_tbl, aes(x = HR, y = label)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey40") +
  geom_errorbar(aes(xmin = CI_low, xmax = CI_high), width = 0.2, orientation = "y", color = "#2c3e50") +
  geom_point(size = 3, color = "#c0392b") +
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
