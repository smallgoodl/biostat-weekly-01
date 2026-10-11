# =====================================================================
# run_all.R — 按顺序运行本周练习流水线 / Run the weekly-exercise pipeline in order
# 用法 / Usage: Rscript run_all.R   （请在项目根目录执行 / run from the project root）
# =====================================================================

message("========================================")
message("  Biostat weekly 01 — NCCTG lung")
message("  Pipeline: clean → desc → model → fig")
message("========================================\n")

# 确保从本脚本所在目录运行：解析 Rscript 传入的 --file= 参数得到脚本路径，再 setwd
# Make sure we run from this script's folder: parse the --file= argument given by Rscript, then setwd
args_cmd <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_cmd, value = TRUE)
if (length(file_arg) == 1) {
  script_path <- normalizePath(sub("^--file=", "", file_arg))
  setwd(dirname(script_path))
}

message("工作目录: ", getwd(), "\n")

# 步骤顺序不可调换：后一步读取前一步写出的文件
# The order matters: each step reads files written by the previous one
#   01 清洗 / clean  → data/lung_clean.rds
#   02 描述 / descriptive → output/baseline_table.*
#   03 建模 / models → output/cox_results.csv, data/models.rds
#   04 作图 / figures → output/*.png
steps <- c("01_clean.R", "02_descriptive.R", "03_model.R", "04_figures.R")
for (f in steps) {
  message(">>> 运行 ", f, " ...")
  # 每个脚本在全新环境中运行，互不污染变量；UTF-8 保证中文注释正常读取
  # Each script runs in a fresh environment so variables do not leak; UTF-8 keeps Chinese text intact
  source(f, local = new.env(), encoding = "UTF-8")
  message("")
}

message("========================================")
message("全部完成。请查看 output/ 与 data/")
message("========================================")
