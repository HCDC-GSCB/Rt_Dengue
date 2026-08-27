
# Ước tính Khoảng thời gian thế hệ - nối tiếp (SI - GI)

#───────────────────────────────────────────────────────────────────────────────
# Tham số
#───────────────────────────────────────────────────────────────────────────────
# Thứ tự 4 giai đoạn trong vector: [EIP, IIP, THM, TMH]
# Tham số cho công thức EIP phụ thuộc T: rate_IM = b0 - b1*T
b0 <- 7.9;  b1 <- 0.21

U    <- 35    # Độ dài SI tối đa (ngày)
T_lo <- 15    # Nhiệt độ tối thiểu sinh học Ae. aegypti (°C)
T_hi <- 7.9 / 0.21  # ≈ 37.6°C — điểm singularity (rate_IM = 0)


#───────────────────────────────────────────────────────────────────────────────
# Kiểm tra nhiệt độ:
#───────────────────────────────────────────────────────────────────────────────




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



