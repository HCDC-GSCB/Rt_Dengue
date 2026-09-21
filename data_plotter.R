# Bản đồ số ca
sliced_era5 <- collated_era5 %>% slice("time", 1) %>% as.data.table()

ggplot() +
  geom_sf(
    data = hcmc_shp2 %>%
      left_join(sliced_era5, by = join_by(ma_xa == region)),
    mapping = aes(fill = t2m)
  ) +
  geom_point(
    data = incidence_dat %>%
      filter(date_hosp == as.Date(sliced_era5$time[[1]])),
    mapping = aes(x = longitude, y = latitude),
    alpha = 0.5
  ) +
  scale_fill_viridis_c() +
  coord_sf(ylim = c(10.25, NA))

# Biểu đồ số ca mắc theo thời gian 

