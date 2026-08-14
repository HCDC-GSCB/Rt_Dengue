library(tidyverse)
library(stars)
library(sf)
library(data.table)

collated_era5 <- read_ncdf(
  "data/weather/HCM-2-2017-2025-era5.nc",
  make_units = FALSE
)

hcmc_shp2 <- st_read("data/spatial_data/gisvn/HCM-2.shp")

sliced_era5 <- collated_era5 %>% slice("time", 1) %>% as.data.table()

hcmc_shp2 %>%
  left_join(sliced_era5, by = join_by(ma_xa == region)) %>%
  ggplot(aes(fill = t2m)) +
  geom_sf() +
  scale_fill_viridis_c()
