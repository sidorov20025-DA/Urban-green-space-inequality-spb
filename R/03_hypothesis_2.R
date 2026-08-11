# Hypothesis 2
# Higher population density is associated with lower green-space provision.

library(readr)
library(dplyr)
library(ggplot2)

mo <- read_csv(
  "data/processed/analysis_mo_cross_section.csv",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

h2_data <- mo %>%
  select(
    mo_name,
    population_density_per_km2_calc,
    green_main_m2_per_capita_calc,
    green_main_share_pct
  ) %>%
  filter(
    !is.na(population_density_per_km2_calc),
    !is.na(green_main_m2_per_capita_calc)
  )

h2_spearman_per_capita <- cor.test(
  h2_data$population_density_per_km2_calc,
  h2_data$green_main_m2_per_capita_calc,
  method = "spearman",
  exact = FALSE
)

h2_spearman_share <- cor.test(
  h2_data$population_density_per_km2_calc,
  h2_data$green_main_share_pct,
  method = "spearman",
  exact = FALSE
)

print(h2_spearman_per_capita)
print(h2_spearman_share)

ggplot(
  h2_data,
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
    title = "Плотность населения и обеспеченность зелеными зонами"
  ) +
  theme_minimal()
