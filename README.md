# 生物统计周练习 01：NCCTG 肺癌生存分析

> **说明：** 本项目是使用公开数据集 `survival::lung`（NCCTG 晚期肺癌）完成的生物统计**学习练习**，并非原创临床研究，结果不用于任何临床结论。

## 数据集是什么？

本练习使用 **NCCTG 肺癌数据**（`survival` 包中的 `lung`）。  
这是北美中部癌症治疗协作组（North Central Cancer Treatment Group）的经典公开临床数据集，共 **228** 例晚期肺癌患者，主要变量包括：

| 变量 | 含义 |
|------|------|
| `time` | 生存时间（天） |
| `status` | 结局：1=删失，2=死亡 |
| `age` | 年龄（岁） |
| `sex` | 性别：1=男，2=女 |
| `ph.ecog` | 医师评估的 ECOG 体力状态（0–3，越高越差） |
| `ph.karno` / `pat.karno` | 医师/患者评估的 Karnofsky 评分 |
| `meal.cal` | 餐时热量摄入 |
| `wt.loss` | 近半年体重下降（磅） |
| `inst` | 研究机构编号 |

无需外网下载；`survival` 包安装后即可直接 `data(lung)`。

## 研究问题

**在晚期肺癌患者中，ECOG 体力状态、性别、年龄是否与总生存（Overall Survival）相关？**

具体步骤：

1. 清洗数据，得到分析用表；
2. 按性别做基线特征描述；
3. 绘制 Kaplan–Meier 曲线（按性别、按 ECOG），拟合多因素 Cox 比例风险模型；
4. 输出表格与图形到 `output/`。

## 如何运行

在项目根目录执行：

```bash
cd /workspace/biostat-weekly-01
Rscript run_all.R
```

或在 R / RStudio 中：

```r
setwd("/workspace/biostat-weekly-01")
source("run_all.R")
```

依赖包（首次运行前需安装）：`tidyverse`、`survival`、`survminer`、`gtsummary`、`broom`、`gt`。

## 各脚本做什么

| 脚本 | 作用 |
|------|------|
| `01_clean.R` | 载入 lung、检查缺失、因子化、写出 `data/lung_clean.rds` |
| `02_descriptive.R` | 基线表（按性别分层），CSV + HTML |
| `03_model.R` | KM 检验 + Cox PH，HR/CI，比例风险假定简要检查 |
| `04_figures.R` | KM 曲线、HR 森林图，PNG 到 `output/` |
| `run_all.R` | 按顺序 `source` 以上脚本 |

## 输出文件（运行后）

- `data/lung_clean.rds` — 分析就绪数据
- `output/baseline_table.csv` / `baseline_table.html` — 基线表
- `output/cox_results.csv` — Cox 模型 HR 表
- `output/ph_assumption.csv` — 比例风险检验
- `output/km_by_sex.png` / `km_by_ecog.png` — KM 曲线
- `output/cox_forest.png` — 森林图

## 学习提示

- `status` 在 survival 包约定中：`Surv(time, status == 2)` 表示以死亡为事件。
- ECOG 3 例数很少，建模时常合并为「2+」。
- Cox 模型报告的是 **风险比 HR**：HR > 1 表示该组死亡风险更高。
