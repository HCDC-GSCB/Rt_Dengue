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
# Dữ liệu thời tiết:
df_temp_city
df_temp_ward

# Dữ liệu ca bệnh:


