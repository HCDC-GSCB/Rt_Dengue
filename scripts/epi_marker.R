library(EpiEstim)
library(tidyverse)
library(stars)
library(tidylog)
library(data.table)
library(patchwork)

source("scripts/utils.R")

theme_set(theme_bw())

# Incidence data processing ---------------------------------------------------
incidence_bundle <- read_rds(
  "data/incidence_geocoded/data_for_analysis_gisvn.RDS"
)

incidence_dat <- incidence_bundle$incidence_data %>%
  drop_na(id_space_lvl3_postreform) %>%
  rename(region = id_space_lvl3_postreform) %>%
  mutate(date = as.Date(date_hosp)) %>%
  group_by(region, date) %>%
  tally() %>%
  ungroup() %>%
  complete(
    date = seq(min(date), max(date), "1 day"),
    region = region,
    fill = list(n = 0)
  )

incidence_epi_period_df <- epi_period_marking(incidence_dat, 500L) %>%
  mutate(epi_marker = fct(as.character(epi_marker)))
p1 <- incidence_epi_period_df %>%
  ggplot(aes(x = date, y = n, color = epi_marker, fill = epi_marker)) +
  geom_col() +
  scale_color_manual(
    values = c(rbind(
      colorRampPalette(c("green", "lightgreen"))(10),
      colorRampPalette(c("pink", "red"))(10)
    )),
    guide = "none"
  ) +
  scale_fill_manual(
    values = c(rbind(
      colorRampPalette(c("green", "lightgreen"))(10),
      colorRampPalette(c("pink", "red"))(10)
    )),
    guide = guide_legend(position = "top", nrow = 2)
  )


# Weather data processing -----------------------------------------------------
collated_era5 <- read_ncdf(
  "data/weather/HCM-2-2017-2025-era5.nc",
  make_units = FALSE
)

t2ms_per_epi_period_per_region <- collated_era5 %>%
  as.data.table() %>%
  mutate(
    era_date = as.Date(time),
    isoyear = year(era_date),
    isoweek = isoweek(era_date),
    t2m = t2m - 273.15,
    mn2t24 = mn2t24 - 273.15,
    mx2t24 = mx2t24 - 273.15,
    isoweek = ifelse(isoweek == 53, 52, isoweek)
  ) %>%
  select(isoyear, isoweek, region, t2m, mn2t24, mx2t24) %>%
  left_join(incidence_epi_period_df, by = join_by(isoyear, isoweek)) %>%
  drop_na(epi_marker) %>%
  group_by(region, epi_marker) %>%
  summarise(
    t2m = mean(t2m),
    mn2t24 = mean(mn2t24),
    mx2t24 = mean(mx2t24),
    start_date = min(date),
    end_date = max(date),
    period_len = unique(period_len),
    .groups = "drop"
  )

p2 <- t2ms_per_epi_period_per_region %>%
  ggplot(aes(
    x = epi_marker,
    y = t2m,
    color = epi_marker
  )) +
  geom_boxplot() +
  scale_color_manual(
    values = c(rbind(
      colorRampPalette(c("pink", "red"))(10),
      colorRampPalette(c("green", "lightgreen"))(10)
    )),
    guide = "none"
  )

p1 / p2
