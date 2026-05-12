library(stars)
library(sf)
library(tidyverse)
library(units)
library(terra)
library(writexl)
library(ncmeta)
library(glue)

# TRÍCH XUẤT DỮ LIỆU THỜI TIẾT ERA5 THEO PHƯỜNG/XÃ TP.HCM MỚI -----------------

## BƯỚC 1: ĐỌC VÀ CHUẨN BỊ DỮ LIỆU NetCDF -------------------------------------

nc_dat <- read_ncdf(
  "data/weather/VNM-2-2017-2025-era5.nc",
  var = c("t2m", "mn2t24", "mx2t24")
) %>%
  st_set_crs(4326)

weather_df <- as.data.frame(nc_dat) %>%
  as_tibble() %>%
  mutate(
    region = as.character(region),
    t2m    = as.numeric(t2m),
    mn2t24 = as.numeric(mn2t24),
    mx2t24 = as.numeric(mx2t24)
  )

## BƯỚC 2: LỌC 3 TỈNH THUỘC TP.HCM MỚI ----------------------------------------

# VNM.25 = TP.HCM cũ | VNM.9 = Bình Dương | VNM.7 = Bà Rịa - Vũng Tàu
# ============================================================
HCM_PREFIXES <- c("VNM\\.25\\.", "VNM\\.9\\.", "VNM\\.7\\.")

weather_hcm_raw <- weather_df %>%
  filter(grepl(paste(HCM_PREFIXES, collapse = "|"), region))

cat("Số region TP.HCM mới trong NetCDF:", n_distinct(weather_hcm_raw$region), "\n")

## BƯỚC 3: ĐỌC GADM LEVEL 3 - TẠO MAPPING region -> đơn vị cũ ------------------

# GID_3 dạng "VNM.25.1.1_1" -> rút về "VNM.25.1_1" để khớp NetCDF
# ============================================================
vnm_adm3 <- read_rds("data/spatial data/gadm41_VNM_3_pk.rds") %>%
  terra::unwrap() %>%
  st_as_sf() %>%
  st_transform(4326)

hcm_adm3 <- vnm_adm3 %>%
  filter(NAME_1 %in% c("Hồ Chí Minh", "Bình Dương", "Bà Rịa - Vũng Tàu")) %>%
  mutate(
    region = sub("(VNM\\.\\d+\\.\\d+)\\.\\d+(_1$)", "\\1\\2", GID_3)
  ) %>%
  select(region, GID_3, NAME_3, NAME_2, NAME_1, geometry)

cat("Số xã/phường cũ trong GADM (3 tỉnh):", nrow(hcm_adm3), "\n")
cat("Số region khớp NetCDF - GADM:", length(intersect(weather_hcm_raw$region, hcm_adm3$region)), "\n")

## BƯỚC 4: ĐỌC SHAPEFILE PHƯỜNG/XÃ MỚI TP.HCM ----------------------------------

cat("Số phường/xã mới trong shapefile:", nrow(hcm_wards), "\n")

## BƯỚC 5: SPATIAL JOIN - centroid GADM cũ -> phường/xã mới --------------------
gadm_centroids <- hcm_adm3 %>% st_centroid()

region_to_ward <- st_join(
  gadm_centroids,
  hcm_wards %>% select(maXa, tenXa),
  join = st_within
) %>%
  st_drop_geometry() %>%
  filter(!is.na(maXa)) %>%
  select(region, maXa, tenXa)

cat("Số region được gán vào phường/xã mới:", nrow(region_to_ward), "\n")
cat("Số phường/xã mới có dữ liệu:", n_distinct(region_to_ward$maXa), "\n")

# ============================================================
# BƯỚC 5b: XỬ LÝ PHƯỜNG/XÃ BỊ THIẾU - GÁN THỦ CÔNG
# ============================================================
missing_wards <- hcm_wards %>%
  st_drop_geometry() %>%
  filter(!maXa %in% region_to_ward$maXa) %>%
  select(maXa, tenXa)

if (nrow(missing_wards) > 0) {
  cat("\n⚠️  Phường/xã chưa có dữ liệu:", nrow(missing_wards), "\n")
  print(missing_wards)
  
  # Bảng gán thủ công cho các trường hợp đặc biệt
  # Lý do:
  # - Côn Đảo (71713027): GADM không có polygon đảo xa bờ ~189km,
  #                        gán vào VNM.7.6_1 (Vũng Tàu) vì cùng tỉnh BRVT
  # - Tân Mỹ  (70113082): Centroid GADM lệch ra ngoài polygon mới do sáp nhập,
  #                        gán vào VNM.25.19_1 (Quận 7) vì cách 0.13km
  manual_mapping <- tibble(
    maXa   = c("71713027",        "70113082"),
    tenXa  = c("Đặc khu Côn Đảo", "Phường Tân Mỹ"),
    region = c("VNM.7.6_1",       "VNM.25.19_1"),
    ly_do  = c("Đảo xa bờ, cùng tỉnh BRVT",
               "Centroid lệch, cách 0.13km, sáp nhập từ Quận 7")
  )
  
  # Tách: có trong bảng thủ công vs chưa có
  manual_fix  <- missing_wards %>%
    inner_join(manual_mapping %>% select(maXa, tenXa, region), by = c("maXa", "tenXa"))
  
  auto_fix <- missing_wards %>%
    filter(!maXa %in% manual_mapping$maXa)
  
  cat("\n📍 Gán thủ công:\n")
  print(manual_mapping %>% select(maXa, tenXa, region, ly_do))
  
  # Xử lý các phường còn lại (nếu có) bằng st_nearest_feature
  if (nrow(auto_fix) > 0) {
    cat("\n📍 Phường/xã còn lại dùng region gần nhất:\n")
    print(auto_fix)
    
    auto_fix_sf <- hcm_wards %>%
      filter(maXa %in% auto_fix$maXa) %>%
      st_centroid()
    nearest_idx <- st_nearest_feature(auto_fix_sf, gadm_centroids)
    
    auto_fix_result <- tibble(
      region = hcm_adm3$region[nearest_idx],
      maXa   = auto_fix_sf$maXa,
      tenXa  = auto_fix_sf$tenXa
    )
    manual_fix <- bind_rows(manual_fix, auto_fix_result)
  }
  
  region_to_ward <- bind_rows(region_to_ward, manual_fix)
  cat("\n✅ Tổng phường/xã có dữ liệu sau bổ sung:", n_distinct(region_to_ward$maXa), "\n")
}

# Kiểm tra kết quả 2 trường hợp đặc biệt
cat("\nKiểm tra mapping các trường hợp đặc biệt:\n")
region_to_ward %>%
  filter(maXa %in% c("71713027", "70113082")) %>%
  print()
# ============================================================
# BƯỚC 6: GHÉP DỮ LIỆU THỜI TIẾT VỚI MAPPING
# ============================================================
weather_with_ward <- weather_hcm_raw %>%
  inner_join(region_to_ward, by = "region",
             relationship = "many-to-many")

# ============================================================
# OUTPUT 1: THEO TỪNG PHƯỜNG/XÃ MỚI
# ============================================================
df_ward <- weather_with_ward %>%
  group_by(time, maXa, tenXa) %>%
  summarise(
    t2m_C    = round(mean(t2m,    na.rm = TRUE) - 273.15, 2),
    mn2t24_C = round(mean(mn2t24, na.rm = TRUE) - 273.15, 2),
    mx2t24_C = round(mean(mx2t24, na.rm = TRUE) - 273.15, 2),
    .groups = "drop"
  ) %>%
  arrange(maXa, time)

cat("\n=== OUTPUT PHƯỜNG/XÃ ===\n")
print(head(df_ward, 10))
cat("Tổng hàng     :", nrow(df_ward), "\n")
cat("Số phường/xã  :", n_distinct(df_ward$maXa), "/", nrow(hcm_wards), "\n")
cat("Số tuần       :", n_distinct(df_ward$time), "\n")

