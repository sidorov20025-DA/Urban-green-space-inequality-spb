# Hypothesis 3
# Spatial accessibility of green spaces for residential buildings.
# Run from the repository root.

library(readr)
library(dplyr)
library(ggplot2)
library(janitor)
library(psych)
library(rstatix)

mo <- read_csv(
  "data/processed/analysis_mo_cross_section.csv",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
) %>%
  clean_names()

buffer_500 <- read_csv(
  "data/processed/accessibility_buffer_500.csv",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
) %>%
  clean_names()

buffer_1000 <- read_csv(
  "data/processed/accessibility_buffer_1000.csv",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
) %>%
  clean_names()

buildings_500 <- read_csv(
  "data/processed/residential_buildings_access_500.csv",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
) %>%
  clean_names()

buffer_500_clean <- buffer_500 %>%
  transmute(
    sys = as.numeric(sys),
    access_500_ha = access_500_ha,
    access_500_pct = access_500_ha / sys_names_area_qgis_ha * 100
  )

buffer_1000_clean <- buffer_1000 %>%
  transmute(
    sys = as.numeric(sys),
    access_1000_ha = access_1000_ha,
    access_1000_pct = access_1000_ha / sys_names_area_qgis_ha * 100
  )

buildings_500_clean <- buildings_500 %>%
  group_by(sys, sys_names_name) %>%
  summarise(
    res_buildings_total = n(),
    res_buildings_access_500 = sum(access_500, na.rm = TRUE),
    res_buildings_access_500_pct = mean(access_500, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  mutate(sys = as.numeric(sys))

mo_access <- mo %>%
  mutate(sys = as.numeric(sys)) %>%
  left_join(buffer_500_clean, by = "sys") %>%
  left_join(buffer_1000_clean, by = "sys") %>%
  left_join(buildings_500_clean, by = "sys") %>%
  mutate(
    res_buildings_no_access_500_pct =
      100 - res_buildings_access_500_pct
  )

access_summary <- mo_access %>%
  summarise(
    mean_access_500 = mean(access_500_pct, na.rm = TRUE),
    mean_access_1000 = mean(access_1000_pct, na.rm = TRUE),
    mean_res_buildings_access_500 =
      mean(res_buildings_access_500_pct, na.rm = TRUE),
    median_res_buildings_access_500 =
      median(res_buildings_access_500_pct, na.rm = TRUE)
  )

print(access_summary)

h3_social_vars <- mo_access %>%
  select(
    res_buildings_access_500_pct,
    mon_children_share_pct,
    population_density_per_km2_calc,
    green_main_share_pct,
    green_main_m2_per_capita_calc,
    mon_beautification_per_capita_thous_rub,
    bdmo_income_total_latest_per_capita_thous_rub,
    bdmo_expense_total_latest_per_capita_thous_rub,
    bdmo_salary_avg_month_no_small_business_rub_latest,
    budget_process_quality_score
  )

h3_social_corr <- corr.test(
  h3_social_vars,
  method = "spearman",
  adjust = "none"
)

h3_social_corr_table <- tibble(
  variable = rownames(h3_social_corr$r),
  rho = h3_social_corr$r[, "res_buildings_access_500_pct"],
  p_value = h3_social_corr$p[, "res_buildings_access_500_pct"],
  n = h3_social_corr$n[, "res_buildings_access_500_pct"]
) %>%
  filter(variable != "res_buildings_access_500_pct") %>%
  mutate(
    rho = round(rho, 2),
    p_value = round(p_value, 3)
  )

print(h3_social_corr_table)

# H3a: differences in accessibility between territorial zones.
# Requires `economic_geographic_zone_ru` in the analytical dataset.
if ("economic_geographic_zone_ru" %in% names(mo_access)) {
  kw_h3 <- kruskal.test(
    res_buildings_no_access_500_pct ~ economic_geographic_zone_ru,
    data = mo_access
  )

  print(kw_h3)

  h3_dunn <- mo_access %>%
    dunn_test(
      res_buildings_no_access_500_pct ~ economic_geographic_zone_ru,
      p.adjust.method = "bonferroni"
    )

  print(h3_dunn)
}

# H3b: association between the share of children and accessibility.
h3_children <- cor.test(
  mo_access$mon_children_share_pct,
  mo_access$res_buildings_access_500_pct,
  method = "spearman",
  exact = FALSE
)

print(h3_children)

ggplot(mo_access, aes(x = res_buildings_access_500_pct)) +
  geom_histogram(bins = 20) +
  labs(
    x = "Доля жилых зданий в пределах 500 м от зеленых зон, %",
    y = "Количество МО",
    title = "Распределение доступности зеленых зон"
  ) +
  theme_minimal()

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

write_csv(
  h3_social_corr_table,
  "outputs/tables/h3_social_economic_correlations_access.csv"
)
