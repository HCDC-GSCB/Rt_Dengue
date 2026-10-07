source("setup.R")

# Làm sạch tên phường/xã
incidence_dat <- incidence_dat %>%
  mutate(
    date_hosp = as.Date(date_hosp),
    new_commune_ward = new_commune_ward %>%
      stri_trans_nfc() %>% 
      str_remove("^(Xã đảo|Đặc khu|Phường|Thị trấn|Xã)\\s+") %>% 
      str_squish()
  ) %>% 
  mutate(
    new_commune_ward = str_replace_all(
      new_commune_ward, 
      c("oà\\b" = "òa", "oá\\b" = "óa", "oả\\b" = "ỏa", "oã\\b" = "õa", "oạ\\b" = "ọa")
    )
  )  %>% 
  filter(!is.na(new_commune_ward)) %>% 
  select(age, new_commune_ward,method_of_care,date_of_symptom,date_hosp,
         date_of_report, severity, diagnostic_classification,longitude,latitude,year,month) %>% 
  mutate(
    week_hosp = isoweek(date_hosp),
    year_hosp = isoyear(date_hosp)) %>% 
  filter(year_hosp %in% c(2017:2025))

# Kiểm tra tên phường/xã
unique(incidence_dat$new_commune_ward)

# Ngày trong giai đoạn nghiên cứu
study_dates <- seq(as.Date("2017-01-02"), as.Date("2025-12-28"), by = "day")

# Số ca mắc theo từng ngày cho toàn Thành phố 
city_daily_long <- incidence_dat %>%
  count(date_hosp, name = "cases") %>%
  complete(date_hosp = study_dates, fill = list(cases = 0L)) %>%
  mutate(
    week_hosp = isoweek(date_hosp),
    year_hosp = isoyear(date_hosp)
  )

# Số ca mắc theo từng ngày cho từng Phướng/Xã
ward_list <- sort(unique(incidence_dat$new_commune_ward))

ward_daily_long <- incidence_dat %>%
  count(new_commune_ward, date_hosp, name = "cases") %>%
  complete(
    new_commune_ward = ward_list,
    date_hosp        = study_dates,
    fill             = list(cases = 0L)
  ) %>%
  mutate(
    week_hosp = isoweek(date_hosp),
    year_hosp = isoyear(date_hosp)
  ) %>%
  arrange(new_commune_ward, date_hosp)

# Làm sạch các cột đặc điểm của dân số tham gia nghiên cứu:



