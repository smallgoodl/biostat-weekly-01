# =====================================================================
# 01_clean.R — 载入、检查、清洗 NCCTG lung，写出分析就绪数据
#              / Load, inspect and clean NCCTG lung; write analysis-ready data
# 目标 / Goal: 得到带因子标签、缺失处理清楚的 tibble
#              / Produce a tibble with labelled factors and explicit missing-data handling
# 声明 / Note: 公开数据 survival::lung 的学习练习，非原创临床研究，不用于临床结论
#              / Learning exercise on public data survival::lung; not original clinical research;
#                not for clinical conclusions.
# =====================================================================

# 加载包（静默）/ Load packages quietly
#   tidyverse：数据整理 / data wrangling;  survival：生存分析与 lung 数据 / survival analysis and the lung data
suppressPackageStartupMessages({
  library(tidyverse)
  library(survival)
})

# ---- 路径：以项目根目录为工作目录 / Paths: project root is the working directory ----
# 若输出目录不存在则创建，避免写文件时报错 / Create output folders if missing so writes do not fail
if (!dir.exists("output")) dir.create("output", recursive = TRUE)
if (!dir.exists("data")) dir.create("data", recursive = TRUE)

# ---- 载入原始数据 / Load the raw data ----
# lung 随 survival 包提供，无需联网下载；status: 1=删失, 2=死亡
# lung ships with the survival package (no download needed); status: 1 = censored, 2 = dead
raw <- as_tibble(survival::lung)

# 先看样本量、变量结构与缺失情况，再决定如何处理
# Inspect size, structure and missingness first, then decide how to handle them
message("原始样本量: ", nrow(raw), " 行, ", ncol(raw), " 列")
message("\n--- 变量结构 ---")
glimpse(raw)

message("\n--- 各变量缺失数 ---")
print(colSums(is.na(raw)))

# ---- 清洗与编码 / Cleaning and coding ----
# 分析主模型常用变量：age, sex, ph.ecog, wt.loss
#   / Variables commonly used in the main model: age, sex, ph.ecog, wt.loss
# meal.cal 缺失较多(~20%)，本练习保留但主模型不用
#   / meal.cal has many missing values (~20%): kept in the data but not used in the main model
# ECOG=3 仅极少例，合并为 >=2（否则该层太小，估计不稳定）
#   / Only very few patients have ECOG=3; merge into ">=2" (a tiny stratum gives unstable estimates)

clean <- raw %>%
  mutate(
    # 生存结局：event=1 表示死亡，0 表示删失（Cox/KM 需要 0/1 事件指示）
    # Survival outcome: event = 1 means death, 0 means censored (Cox/KM need a 0/1 event indicator)
    event = as.integer(status == 2),
    # 性别因子：把 1/2 编码变成带标签的因子；第一水平 Male 将成为 Cox 模型的参照组
    # Sex as a factor: turn the 1/2 codes into labels; the first level (Male) becomes the reference group in Cox models
    sex = factor(sex, levels = c(1, 2), labels = c("Male", "Female")),
    # ECOG：0 / 1 / >=2；先保留原始值，便于核对
    # ECOG: 0 / 1 / >=2; keep the raw value for traceability
    ph.ecog_raw = ph.ecog,
    # 用 case_when 逐条判断；缺失保持 NA（不擅自填补）
    # case_when evaluates each rule in turn; missing stays NA (no imputation)
    ecog = case_when(
      is.na(ph.ecog) ~ NA_character_,
      ph.ecog == 0 ~ "0",
      ph.ecog == 1 ~ "1",
      ph.ecog >= 2 ~ "2+",
      TRUE ~ NA_character_
    ),
    # 转为有序水平的因子，0 为参照组
    # Convert to a factor with explicit level order; "0" is the reference group
    ecog = factor(ecog, levels = c("0", "1", "2+")),
    # 年龄分组（仅描述用，模型里年龄仍按连续变量）
    # Age groups (descriptive only; the model keeps age continuous)
    age_group = cut(
      age,
      breaks = c(-Inf, 60, 70, Inf),
      labels = c("<60", "60-70", ">70"),
      right = TRUE
    )
  ) %>%
  # 主分析所需关键：time, event, age, sex, ecog；只保留后续要用的列
  # Key variables for the main analysis: time, event, age, sex, ecog; keep only columns used downstream
  # 对主分析关键变量做完整病例（complete-case）；wt.loss 可选保留
  # Complete-case analysis on the key variables; wt.loss is optional and kept as-is
  select(
    inst, time, status, event, age, age_group, sex,
    ph.ecog_raw, ecog, ph.karno, pat.karno, meal.cal, wt.loss
  )

# ---- 主分析完整病例集 / Complete-case set for the main analysis ----
# 去掉 time/event/age/sex/ecog 任一缺失的行（Cox 模型会默认丢弃缺失行，这里显式处理便于报告样本量）
# Drop rows missing any of time/event/age/sex/ecog (coxph would drop them silently anyway;
# doing it explicitly lets us report the sample size)
analysis <- clean %>%
  filter(
    !is.na(time), !is.na(event),
    !is.na(age), !is.na(sex), !is.na(ecog)
  )

# 汇报剔除例数、分析样本量与事件数 / Report dropped cases, analysis n and number of events
n_drop <- nrow(clean) - nrow(analysis)
message("\n因主变量缺失剔除: ", n_drop, " 例")
message("分析样本量: ", nrow(analysis))
message("事件数(死亡): ", sum(analysis$event),
        " (", round(100 * mean(analysis$event), 1), "%)")

# ---- 简单质控：生存时间应为正 / Sanity check: survival times must be positive ----
# 若不满足则立即报错中止 / Stop with an error if violated
stopifnot(all(analysis$time > 0))

# ---- 保存 / Save ----
# rds 保留因子等类型（供后续脚本读取）；csv 便于用其他软件查看
# rds keeps factor types (read by later scripts); csv is easy to open in other software
saveRDS(analysis, file = "data/lung_clean.rds")
write_csv(analysis, "data/lung_clean.csv")

message("\n已写出: data/lung_clean.rds 与 data/lung_clean.csv")
message("01_clean.R 完成。")
