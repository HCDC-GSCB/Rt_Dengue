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
      c("oà" = "òa", "oá" = "óa", "oả" = "ỏa", "oã" = "õa", "oạ" = "ọa")
    )
  )

#Kiểm tra tên phường/xã
unique(incidence_dat$new_commune_ward)

