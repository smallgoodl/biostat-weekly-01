# run_all.R — 按顺序运行本周练习流水线
# 用法: Rscript run_all.R   （请在项目根目录执行）

message("========================================")
message("  Biostat weekly 01 — NCCTG lung")
message("  Pipeline: clean → desc → model → fig")
message("========================================\n")

# 确保从本脚本所在目录运行
args_cmd <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_cmd, value = TRUE)
if (length(file_arg) == 1) {
  script_path <- normalizePath(sub("^--file=", "", file_arg))
  setwd(dirname(script_path))
}

message("工作目录: ", getwd(), "\n")

steps <- c("01_clean.R", "02_descriptive.R", "03_model.R", "04_figures.R")
for (f in steps) {
  message(">>> 运行 ", f, " ...")
  source(f, local = new.env(), encoding = "UTF-8")
  message("")
}

message("========================================")
message("全部完成。请查看 output/ 与 data/")
message("========================================")
