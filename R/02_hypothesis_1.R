# Hypothesis 1
# Green-space provision differs between economic-geographic zones.
#
# NOTE:
# This script reconstructs the analysis structure from the documented thesis
# results. Verify that `economic_geographic_zone_ru` is present in the final
# analytical dataset before running.

library(readr)
library(dplyr)
library(ggplot2)
library(rstatix)

mo <- read_csv(
  "data/processed/analysis_mo_cross_section.csv",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

required_vars <- c(
  "economic_geographic_zone_ru",
  "green_main_share_pct",
  "green_main_m2_per_capita_calc"
)

stopifnot(all(required_vars %in% names(mo)))

h1_desc <- mo %>%
  group_by(economic_geographic_zone_ru) %>%
  summarise(
    n = n(),
    median_green_share = median(green_main_share_pct, na.rm = TRUE),
    median_green_m2_per_capita = median(
      green_main_m2_per_capita_calc,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

print(h1_desc)

kw_green_share <- kruskal.test(
  green_main_share_pct ~ economic_geographic_zone_ru,
  data = mo
)

kw_green_per_capita <- kruskal.test(
  green_main_m2_per_capita_calc ~ economic_geographic_zone_ru,
  data = mo
)

print(kw_green_share)
print(kw_green_per_capita)

posthoc_green_share <- mo %>%
  dunn_test(
    green_main_share_pct ~ economic_geographic_zone_ru,
    p.adjust.method = "bonferroni"
  )

posthoc_green_per_capita <- mo %>%
  dunn_test(
    green_main_m2_per_capita_calc ~ economic_geographic_zone_ru,
    p.adjust.method = "bonferroni"
  )

print(posthoc_green_share)
print(posthoc_green_per_capita)

ggplot(
  mo,
  aes(
    x = economic_geographic_zone_ru,
    y = green_main_m2_per_capita_calc
  )
) +
  geom_boxplot() +
  coord_flip() +
  labs(
    x = NULL,
    y = "Площадь основных зеленых зон, м²/жителя",
    title = "Обеспеченность зелеными зонами по территориальным поясам"
  ) +
  theme_minimal()
