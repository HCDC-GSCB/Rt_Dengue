
# Ước tính Khoảng thời gian thế hệ - nối tiếp (SI - GI)

#───────────────────────────────────────────────────────────────────────────────
# Tham số
#───────────────────────────────────────────────────────────────────────────────
# Thứ tự 4 giai đoạn trong vector: [EIP, IIP, THM, TMH]
# Tham số cho công thức EIP phụ thuộc T: rate_IM = b0 - b1*T
b0 <- 7.9;  b1 <- 0.21

# Ghi chú rate EIP không phụ thuộc T (ti-SI):
#   0.23  theo Chan & Johansson (2012) — dùng cho dữ liệu THỰC
#   0.067 ≈ mean(rate_td) tại T_mean Singapore — dùng cho mô phỏng

U    <- 35    # Độ dài SI tối đa (ngày)
T_lo <- 15    # Nhiệt độ tối thiểu sinh học Ae. aegypti (°C)
T_hi <- 7.9 / 0.21  # ≈ 37.6°C — điểm singularity (rate_IM = 0)


#───────────────────────────────────────────────────────────────────────────────
# Kiểm tra nhiệt độ:
#───────────────────────────────────────────────────────────────────────────────

check_temp <- function(T) {
  if (T < 15) {
    warning(sprintf("T=%.1f°C dưới ngưỡng sinh học (15°C) — Ae. aegypti ngừng hoạt động", T))
    return(FALSE)
  }
  if ((7.9 - 0.21 * T) <= 0) {
    warning(sprintf("T=%.1f°C vượt điểm singularity (37.6°C) — rate_IM ≤ 0", T))
    return(FALSE)
  }
  if (T > 32) {
    message(sprintf(" Ngoài phạm vi tối ưu (15-32°C)", T))
  }
  TRUE
}

#───────────────────────────────────────────────────────────────────────────────
# Hàm ước tính SI
#───────────────────────────────────────────────────────────────────────────────

# dcoga(x, shape, rate): PDF của tổng 4 Gamma độc lập tại điểm x
#
# Thứ tự 4 giai đoạn: [EIP, IIP, THM, TMH]
#   shape = c(a_EIP, a_IIP, a_THM, a_TMH)
#   rate  = c(r_EIP, r_IIP, r_THM, r_TMH)

# Tham số shape (a) và rate (r):
#   IIP  : Gamma(shape=16,   rate=2.7 )
#   EIP  : Exp  (shape=1,    rate=0.23)  ← ti version
#   EIP  : Gamma(shape=4.3,  rate=7.9 - 0.21*T )  ← td version
#   THM  : Exp  (shape=1,    rate=1   )
#   TMH  : Exp  (shape=1,    rate=1   )


# --- ti-SI: không phụ thuộc T, tính một lần ---
calc_w_ti <- function() {
  a_ind <- c(16,   1,    1,  1)    
  r_ind <- c(2.7,  0.23, 1,  1)   
  
  w_raw <- dcoga(1:U, shape = a_ind, rate = r_ind)
  w_raw / sum(w_raw)
}

# --- td-SI: phụ thuộc T, tính tại mỗi ngày ---
calc_w_td <- function(T) {
  if (!check_temp(T)) return(rep(0, U))
  
  a_dep <- c(16,   4.3,           1,  1)   
  r_dep <- c(2.7,  1/(7.9 - 0.21*T), 1,  1) 
  
  w_raw <- dcoga(1:U, shape = a_dep, rate = r_dep)
  w_sum <- sum(w_raw)
  if (w_sum <= 0) return(rep(0, U))
  w_raw / w_sum
}


#───────────────────────────────────────────────────────────────────────────────
# Kiểm tra hàm SI và vẽ biểu đồ SI
#───────────────────────────────────────────────────────────────────────────────

test_SI <- function(temps = c(25, 27, 28, 29, 30, 32),
                    plot  = TRUE) {
  
  days <- 1:U
  w_ti <- calc_w_ti()
  
  # Thống kê ti-SI
  mean_ti   <- sum(days * w_ti)
  median_ti <- days[which(cumsum(w_ti) >= 0.5)[1]]
  mode_ti   <- days[which.max(w_ti)]
  
  cat("=== SERIAL INTERVAL — THỐNG KÊ ===\n\n")
  cat(sprintf("%-30s %6s %6s %6s %6s\n",
              "Phân phối", "Mean", "Median", "Mode", "Sum_w"))
  cat(strrep("-", 58), "\n")
  cat(sprintf("%-30s %6.1f %6.1f %6.1f %6.4f\n",
              "ti-SI (EIP: Exp rate=0.23)", mean_ti, median_ti, mode_ti, sum(w_ti)))
  
  for (T in temps) {
    w_td <- calc_w_td(T)
    if (all(w_td == 0)) {
      cat(sprintf("%-30s  %s\n", paste0("td-SI (T=", T, "°C)"), "NGOÀI PHẠM VI"))
      next
    }
    mean_td   <- sum(days * w_td)
    median_td <- days[which(cumsum(w_td) >= 0.5)[1]]
    mode_td   <- days[which.max(w_td)]
    cat(sprintf("%-30s %6.1f %6.1f %6.1f %6.4f  [rate_IM=%.3f]\n",
                paste0("td-SI (T=", T, "°C)"),
                mean_td, median_td, mode_td, sum(w_td), 7.9 - 0.21*T))
  }
  cat("\n")
  
  # Vẽ hình nếu yêu cầu
  if (plot) {
    library(ggplot2)
    library(dplyr)
    
    n_temp <- length(temps)
    pal_td <- colorRampPalette(c("#2196F3", "#4CAF50", "#FF5722"))(n_temp)
    
    df_plot <- bind_rows(
      data.frame(Ngay = days, w = w_ti,
                 Nhan = "ti-SI (Exp 0.23)",
                 Mau  = "#9C27B0", Kieu = "dashed"),
      bind_rows(lapply(seq_along(temps), function(i) {
        T   <- temps[i]
        w   <- calc_w_td(T)
        data.frame(Ngay = days, w = w,
                   Nhan = paste0("td-SI (T=", T, "°C)"),
                   Mau  = pal_td[i], Kieu = "solid")
      }))
    )
    
    p <- ggplot(df_plot, aes(x = Ngay, y = w,
                             color = Nhan, linetype = Kieu)) +
      geom_line(linewidth = 0.9) +
      scale_color_manual(values = setNames(df_plot$Mau,
                                           df_plot$Nhan),
                         name = "Mô hình") +
      scale_linetype_manual(values = c("dashed", "solid"),
                            guide  = "none") +
      scale_x_continuous(breaks = seq(0, 35, 5)) +
      labs(
        title    = "Phân bố Khoảng thời gian thế hệ của Sốt xuất huyết Dengue",,
        x = "Thời gian (Days)",
        y = "Mật độ xác suất lây nhiễm (Density)"
      ) +
      theme_bw(base_size = 12) +
      theme(legend.position   = "right",
            plot.title        = element_text(face = "bold"),
            plot.subtitle     = element_text(size = 10, color = "grey40"),
            panel.grid.minor  = element_blank())
    
    print(p)
    return(invisible(list(plot = p, data = df_plot)))
  }
}























