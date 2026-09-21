# Chuẩn bị các thư viện cần thiết:
 library(tidyverse)
 library(ggplot2)
 library(readxl)
 library(stringi)
 library(stringr)
 library(lubridate)
 library(scales)
 library(coga)
 library(EpiEstim)
 library(data.table)
 library(stars)
 library(sf)

# Gọi các functions của EpiFilter:
 path_epifilter <- "package/EpiFilter"
 files.sources <- list.files(path = path_epifilter, pattern = "\\.R$", full.names = TRUE)
 epifilter <- new.env()
 for (f in files.sources) source(f, local = epifilter)

# Gọi các functions của Mills:
 path_mills <- "package/Mills/mills_gi.RData"
 load_mills <- function(path) {
   e <- new.env()
   load(path, envir = e)
   for (n in ls(e)) {                       
      o <- get(n, envir = e)
      if (is.function(o)) { environment(o) <- e; assign(n, o, envir = e) }
   }
  e
 }
 mills <- load_mills(path_mills)

# Chuẩn bị các dữ liệu cần thiết
# Đọc dữ liệu ca bệnh
 incidence_dat <- read_rds("data/incidence_dat_filtered.rds") 

# Đọc dữ liệu thời tiết
 collated_era5 <- read_ncdf(
   "data/weather/HCM-2-2017-2025-era5.nc",
   make_units = FALSE
 )

# Đọc shape file
 hcmc_shp2 <- st_read("data/spatial_data/gisvn/HCM-2.shp")
 
