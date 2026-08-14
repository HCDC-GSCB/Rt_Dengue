library(tidyverse)
library(readxl)
library(stars)
library(sf)
library(data.table)

collated_era5 <- read_ncdf(
  "data/weather/HCM-2-2017-2025-era5.nc",
  make_units = FALSE
)

hcmc_shp2 <- st_read("data/spatial_data/gisvn/HCM-2.shp")

sliced_era5 <- collated_era5 %>% slice("time", 1) %>% as.data.table()

incidence_dat <- read_rds(
  "data/incidence_geocoded/incidence_dat_filtered.rds"
) %>%
  mutate(date_hosp = as.Date(date_hosp))


ggplot() +
  geom_sf(
    data = hcmc_shp2 %>%
      left_join(sliced_era5, by = join_by(ma_xa == region)),
    mapping = aes(fill = t2m)
  ) +
  geom_point(
    data = incidence_dat %>% filter(date_hosp == sliced_era5$time[[1]]),
    mapping = aes(x = longitude, y = latitude),
    alpha = 0.5
  ) +
  scale_fill_viridis_c() +
  coord_sf(ylim = c(10.25, NA))
