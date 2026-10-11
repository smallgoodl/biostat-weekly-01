# 01_clean.R — 载入、检查、清洗 NCCTG lung，写出分析就绪数据
# 目标：得到带因子标签、缺失处理清楚的 tibble

suppressPackageStartupMessages({
  library(tidyverse)
  library(survival)
})

# ---- 路径：以项目根目录为工作目录 ----
if (!dir.exists("output")) dir.create("output", recursive = TRUE)
if (!dir.exists("data")) dir.create("data", recursive = TRUE)

# ---- 载入原始数据 ----
# lung 随 survival 包提供；status: 1=删失, 2=死亡
raw <- as_tibble(survival::lung)

message("原始样本量: ", nrow(raw), " 行, ", ncol(raw), " 列")
message("\n--- 变量结构 ---")
glimpse(raw)

message("\n--- 各变量缺失数 ---")
print(colSums(is.na(raw)))

# ---- 清洗与编码 ----
# 分析主模型常用变量：age, sex, ph.ecog, wt.loss
# meal.cal 缺失较多(~20%)，本练习保留但主模型不用
# ECOG=3 仅极少例，合并为 >=2

clean <- raw %>%
  mutate(
    # 生存结局：event=1 表示死亡
    event = as.integer(status == 2),
    # 性别因子
    sex = factor(sex, levels = c(1, 2), labels = c("Male", "Female")),
    # ECOG：0 / 1 / >=2
    ph.ecog_raw = ph.ecog,
    ecog = case_when(
      is.na(ph.ecog) ~ NA_character_,
      ph.ecog == 0 ~ "0",
      ph.ecog == 1 ~ "1",
      ph.ecog >= 2 ~ "2+",
      TRUE ~ NA_character_
    ),
    ecog = factor(ecog, levels = c("0", "1", "2+")),
    # 年龄分组（描述用）
    age_group = cut(
      age,
      breaks = c(-Inf, 60, 70, Inf),
      labels = c("<60", "60-70", ">70"),
      right = TRUE
    )
  ) %>%
  # 主分析所需关键：time, event, age, sex, ecog
  # 对主分析关键做完整病例（complete-case）；wt.loss 可选保留
  select(
    inst, time, status, event, age, age_group, sex,
    ph.ecog_raw, ecog, ph.karno, pat.karno, meal.cal, wt.loss
  )

# ---- 主分析完整病例集 ----
# 去掉 time/event/age/sex/ecog 任一缺失的行
analysis <- clean %>%
  filter(
    !is.na(time), !is.na(event),
    !is.na(age), !is.na(sex), !is.na(ecog)
  )

n_drop <- nrow(clean) - nrow(analysis)
message("\n因主变量缺失剔除: ", n_drop, " 例")
message("分析样本量: ", nrow(analysis))
message("事件数(死亡): ", sum(analysis$event),
        " (", round(100 * mean(analysis$event), 1), "%)")

# ---- 简单质控：生存时间应为正 ----
stopifnot(all(analysis$time > 0))

# ---- 保存 ----
saveRDS(analysis, file = "data/lung_clean.rds")
write_csv(analysis, "data/lung_clean.csv")

message("\n已写出: data/lung_clean.rds 与 data/lung_clean.csv")
message("01_clean.R 完成。")
