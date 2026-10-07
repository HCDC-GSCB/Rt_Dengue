source("./clean data.R")
source("./SI_estimation.R")

# Tham số
 tau <- 14
 mean_prior <- 5; std_prior <- 5 #Tiên nghiệm cho EpiEstim: Gamma(a = 1, b = 5)
 Rmin <- 0.01; Rmax <- 10
 m <- 1000; eta <- 0.1
 conf <- 0.025
 
# Kiểm tra dữ liệu đầu vào
 stopifnot(
   length(ward_list) == 168,                          
   nrow(city_daily_long) == length(study_dates),      
   nrow(ward_daily_long) == 168 * length(study_dates),
   is.environment(epifilter),                         
   all(c("epiFilter", "epiSmoother") %in% ls(epifilter))
 )
 
# Tính lực lây nhiễm:
 calc_lambda <- function(I, w) {
   n <- length(I)
   W <- if (is.matrix(w)) w else matrix(w, n, length(w), byrow = TRUE)
   stopifnot(nrow(W) == n)
   vapply(seq_len(n), function(t) {
     u <- seq_len(min(ncol(W), t - 1))
     if (length(u) == 0) return(NA_real_)
     sum(I[t - u] * W[t, u])
   }, numeric(1))
 }
 
 split_local <- function(I, lambda) {
   imported <- ifelse(is.na(lambda) | lambda == 0, I, 0)
   data.frame(local = I - imported, imported = imported)
 }
 
 # EpiEstim: cửa sổ τ ngày, ước lượng gán cho ngày cuối cửa sổ
 run_epiestim <- function(incid, w) {
   n       <- nrow(incid)
   t_end   <- seq(tau + 1, n)
   t_start <- t_end - tau + 1
   res <- withCallingHandlers(
     estimate_R(incid, method = "non_parametric_si",
                config = make_config(list(
                  si_distr = c(0, w),                    # phần tử đầu = độ trễ 0
                  t_start = t_start, t_end = t_end,
                  mean_prior = mean_prior, std_prior = std_prior))),
     warning = function(cnd) {                         # cảnh báo CV hậu nghiệm: thay bằng cột ee_cv
       if (grepl("too early", conditionMessage(cnd))) invokeRestart("muffleWarning")
     })
   # CV hậu nghiệm = 1 / sqrt(a + ΣI_local trong cửa sổ)  (Cori 2013, Web Appendix 1)
   # CV ≤ 0,3 cần ít nhất 11 ca trong cửa sổ khi a = 1  (Web Appendix 2, Web Table 1)
   a_prior <- (mean_prior / std_prior)^2
   cs      <- c(0, cumsum(incid$local))
   sum_I   <- cs[t_end + 1] - cs[t_start]
   data.frame(t       = res$R$t_end,
              ee_mean = res$R$`Mean(R)`,
              ee_lo   = res$R$`Quantile.0.025(R)`,
              ee_hi   = res$R$`Quantile.0.975(R)`,
              ee_cv   = 1 / sqrt(a_prior + sum_I))
 }
 
 # EpiFilter: kết quả gốc là list KHÔNG tên
 #   [[1]] Rmed  [[2]] Rhat (4 x n: KTC dưới, trên, 25%, 75%)  [[3]] Rmean
 #   [[4]] pR (lọc)  [[5]] pRup (dự đoán p_t*)  [[6]] pstate
 # Chỉ chạy từ ngày U, khi Λ_t đã có đủ lịch sử (như Choo 2026). Ở đầu chuỗi Λ_t
 # chỉ gồm 1–2 ngày nên rất nhỏ, hàm hợp lý Poisson tràn số dưới về 0 → NaN.
 # Dòng đầu (ngày U) là tiên nghiệm; cập nhật bắt đầu từ ngày U + 1.
 run_epifilter <- function(I_local, lambda) {
   idx   <- U:length(I_local)
   nd    <- length(idx)
   Rgrid <- seq(Rmin, Rmax, length.out = m)
   pR0   <- rep(1 / m, m)
   filt  <- epifilter$epiFilter(Rgrid, m, eta, pR0, nd, lambda[idx], I_local[idx], conf)
   if (anyNA(filt[[3]])) stop("EpiFilter trả về NaN — kiểm tra Λ_t và số ca.")
   smo   <- epifilter$epiSmoother(Rgrid, m, filt[[4]], filt[[5]], nd, filt[[6]], conf)
   pRup  <- filt[[5]]
   data.frame(t         = idx,
              ef_mean   = filt[[3]],  ef_lo  = filt[[2]][1, ], ef_hi  = filt[[2]][2, ],
              efs_mean  = smo[[3]],   efs_lo = smo[[2]][1, ],  efs_hi = smo[[2]][2, ],
              ef_pred_R = as.vector(pRup %*% Rgrid) / rowSums(pRup))  # TB của p_t*
 }
 
 # Một chuỗi (thành phố hoặc một phường/xã) → bảng kết quả theo ngày
 #   ee_*  : EpiEstim             ef_*  : EpiFilter lọc (p_t)
 #   efs_* : EpiFilter làm mượt (q_t) — chỉ để mô tả hồi cứu, không dùng khi so sánh
 #   *_I_fit  : R̂_t · Λ_t  (giá trị khớp, R̂_t dùng dữ liệu đến t)
 #   *_I_pred : dự báo một bước (R̂ chỉ dùng dữ liệu đến t−1)
 estimate_ti <- function(I, dates, w) {
   lambda <- calc_lambda(I, w)
   incid  <- split_local(I, lambda)
   out <- data.frame(t = seq_along(I), date = dates, I = I,
                     I_local = incid$local, lambda = lambda) %>%
     left_join(run_epiestim(incid, w), by = "t") %>%
     left_join(run_epifilter(incid$local, lambda), by = "t") %>%
     mutate(
       ee_I_fit  = ee_mean * lambda,
       ee_I_pred = lag(ee_mean) * lambda,
       ef_I_fit  = ef_mean * lambda,
       ef_I_pred = ef_pred_R * lambda,
       eval_window = t > U                                # bỏ U ngày đầu: Λ chưa đầy đủ
     )
   out
 }
 
 #───────────────────────────────────────────────────────────────────────────────
 # Chạy
 #───────────────────────────────────────────────────────────────────────────────
 w_ti <- calc_w_ti()
 
 # Toàn Thành phố
 rt_ti_city <- estimate_ti(city_daily_long$cases, city_daily_long$date_hosp, w_ti)
 
 # Từng phường/xã — thử 1 phường trước để đo thời gian
 # system.time(estimate_ti(ward_daily_long$cases[ward_daily_long$new_commune_ward == ward_list[1]],
 #                         study_dates, w_ti))
 rt_ti_ward <- ward_daily_long %>%
   group_by(new_commune_ward) %>%
   group_modify(~ estimate_ti(.x$cases, .x$date_hosp, w_ti)) %>%
   ungroup()
 
 
