source("clean data.R")

# ---- Thiết lập -------------------------------------------------------------

# Dấu phân cách theo quy định tiếng Việt
theme_gtsummary_language("en", big.mark = ".", decimal.mark = ",")

# Nhóm tuổi - chỉnh lại nếu cần
age_breaks <- c(0, 5, 15, 25, 45, Inf)
age_labels <- c("<5", "5–14", "15–24", "25–44", "≥45")

# Phân độ bệnh: giá trị trong dữ liệu
sev_map <- c(
  "SXH"                      = "SXHD",
  "SXH có dấu hiệu cảnh báo" = "SXHD có dấu hiệu cảnh báo",
  "SXH nặng"                 = "SXHD nặng"
)

# Hình thức điều trị
moc_levels <- c("Ngoại trú", "Nội trú")

# Phân loại chẩn đoán:
dx_levels <- c("Lâm sàng", "Xác định phòng xét nghiệm")

na_label <- "Không có thông tin"

# ---- Chuẩn bị dữ liệu cho bảng (không sửa incidence_dat) --------------------

tbl_data <- incidence_dat %>%
  mutate(
    age_group = cut(age, breaks = age_breaks, labels = age_labels, right = FALSE),
    
    # Phân loại chẩn đoán
    dx_raw = as.character(diagnostic_classification) %>%
      stri_trans_nfc() %>%
      str_replace_all("[\\r\\n()]", " ") %>%
      str_to_lower() %>%
      str_squish(),
    dx_group = case_when(
      is.na(dx_raw)                                ~ NA_character_,
      str_detect(dx_raw, "(^|\\+ )xác đ[iíị]nh")   ~ "Xác định phòng xét nghiệm",
      str_detect(dx_raw, "^có thể$")               ~ "Có thể",
      str_detect(dx_raw, "nghi ng|^lâm sàng$")     ~ "Nghi ngờ (Lâm sàng)",
      str_detect(dx_raw, "s[ốô]t xuất huyết|sxh")  ~ "Chỉ ghi chẩn đoán SXHD",
      TRUE                                         ~ "Giá trị không hợp lệ"
    ),
    dx = factor(
      case_when(
        dx_group %in% c("Nghi ngờ (Lâm sàng)", "Có thể") ~ "Lâm sàng",
        dx_group == "Xác định phòng xét nghiệm"          ~ "Xác định phòng xét nghiệm"
      ),
      levels = dx_levels
    ),
    
    # Hình thức điều trị và phân độ bệnh: chuẩn hoá Unicode trước khi đối chiếu
    moc_raw = str_squish(stri_trans_nfc(as.character(method_of_care))),
    sev_raw = str_squish(stri_trans_nfc(as.character(severity))),
    moc     = factor(moc_raw, levels = moc_levels),
    sev     = factor(unname(sev_map[sev_raw]), levels = unname(sev_map))
  )

# Dừng nếu có giá trị lạ, tránh để chúng âm thầm biến thành "Không có thông tin"
stopifnot(
  "Có giá trị hình thức điều trị ngoài danh sách" =
    all(na.omit(tbl_data$moc_raw) %in% moc_levels),
  "Có giá trị phân độ bệnh ngoài danh sách" =
    all(na.omit(tbl_data$sev_raw) %in% names(sev_map))
)

tbl_data <- tbl_data %>%
  mutate(across(c(dx, sev), ~ fct_na_value_to_level(.x, level = na_label))) %>%
  select(any_of(c("age", "age_group", "sex", "dx", "moc", "sev")))

# ---- Dựng bảng --------------------------------------------------------------

tbl_desc <- tbl_data %>%
  tbl_summary(
    label = list(
      age           ~ "Tuổi (năm)",
      age_group     ~ "Nhóm tuổi",
      any_of("sex") ~ "Giới",
      dx            ~ "Phân loại chẩn đoán",
      moc           ~ "Hình thức điều trị",
      sev           ~ "Phân độ bệnh"
    ),
    missing_text = na_label
  ) %>%
  modify_header(label ~ "**Đặc điểm**") %>%
  bold_labels()

tbl_desc

# ---- Xuất sang Word ---------------------------------------------------------

#tbl_desc %>%
#  as_flex_table() %>%
#  flextable::save_as_docx(path = "bang_dac_diem_ca_benh.docx"