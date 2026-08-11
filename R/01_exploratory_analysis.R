# Exploratory analysis
# Run from the repository root.

library(readr)
library(dplyr)
library(ggplot2)

mo <- read_csv(
  "data/processed/analysis_mo_cross_section.csv",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

glimpse(mo)

descriptive_stats <- mo %>%
  summarise(
    n = n(),
    green_main_share_mean = mean(green_main_share_pct, na.rm = TRUE),
    green_main_share_sd = sd(green_main_share_pct, na.rm = TRUE),
    green_main_m2_per_capita_mean = mean(green_main_m2_per_capita_calc, na.rm = TRUE),
    population_density_mean = mean(population_density_per_km2_calc, na.rm = TRUE)
  )

print(descriptive_stats)

exploratory_vars <- mo %>%
  select(
    green_main_share_pct,
    green_main_m2_per_capita_calc,
    green_broad_share_pct,
    population_density_per_km2_calc,
    mon_children_share_pct,
    mon_budget_no_subventions_per_capita_thous_rub,
    mon_beautification_per_capita_thous_rub,
    nash_spb_messages_per_1000,
    pos_requests_per_1000,
    bdmo_income_total_latest_per_capita_thous_rub,
    bdmo_salary_avg_month_no_small_business_rub_latest
  )

spearman_matrix <- cor(
  exploratory_vars,
  use = "pairwise.complete.obs",
  method = "spearman"
)

print(spearman_matrix)

model_1 <- lm(
  green_main_m2_per_capita_calc ~
    population_density_per_km2_calc +
    mon_budget_no_subventions_per_capita_thous_rub +
    mon_children_share_pct,
  data = mo
)

summary(model_1)

ggplot(
  mo,
  aes(
    x = population_density_per_km2_calc,
    y = green_main_m2_per_capita_calc
  )
) +
  geom_point() +
  geom_smooth(method = "lm", se = TRUE) +
  labs(
    x = "Плотность населения, чел./км²",
    y = "Площадь основных зеленых зон, м²/жителя",
    title = "Связь плотности населения и обеспеченности зелеными зонами"
  ) +
  theme_minimal()

mo %>%
  arrange(desc(green_main_m2_per_capita_calc)) %>%
  select(
    mo_name,
    green_main_m2_per_capita_calc,
    green_main_share_pct,
    population_density_per_km2_calc
  ) %>%
  slice_head(n = 10)

mo %>%
  arrange(green_main_m2_per_capita_calc) %>%
  select(
    mo_name,
    green_main_m2_per_capita_calc,
    green_main_share_pct,
    population_density_per_km2_calc
  ) %>%
  slice_head(n = 10)
