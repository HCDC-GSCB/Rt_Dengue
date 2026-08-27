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

# Gọi các functions của EpiFilter:
path_epifilter <- "package/EpiFilter"

files.sources <- list.files(path = path_epifilter, full.names = TRUE)
  for (f in files.sources) {
    source(f)
  }

# Gọi các functions của Mills:


# Chuẩn bị các dữ liệu cần thiết

# Dữ liệu thời tiết:
df_temp_city
df_temp_ward

# Dữ liệu ca bệnh:


