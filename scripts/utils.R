epi_period_marking <- function(incidence_df, incidence_threshold = 500L) {
  weekly_inc_df <- incidence_df %>%
    mutate(
      isoyear = isoyear(date),
      isoweek = isoweek(date),
      isoweek = ifelse(isoweek == 53, 52, isoweek)
    ) %>%
    group_by(isoyear, isoweek) %>%
    summarise(n = sum(n), date = min(date), .groups = "drop") %>%
    mutate(over_threshold = n > incidence_threshold)

  epi_rle <- rle(weekly_inc_df$over_threshold)
  epi_rle_indices <- seq_along(epi_rle$lengths)

  # epi/non-epi marker vector
  epi_markers <- numeric(length(weekly_inc_df$over_threshold))

  # loop state and count vars
  epi_state <- "none"
  epi_count <- 1
  non_epi_count <- -1

  # period marking looping
  for (i in epi_rle_indices) {
    # value of RLE element
    cur_val <- epi_rle$values[i]
    # length of RLE element
    cur_len <- epi_rle$lengths[i]
    # time-aware index (not RLE index)
    time_index <- sum(epi_rle$lengths[1:i])
    # time-aware indices of the RLE element period/length
    period_time_indices <- seq(time_index - cur_len + 1, time_index)

    if (epi_state == "none" && (cur_len < 3 || !cur_val)) {
      # branch: not in an epidemic and NOT over threshold to trigger
      #         the start of one
      epi_markers[period_time_indices] <- non_epi_count
    } else if (cur_val && cur_len >= 3 && epi_state == "none") {
      # branch: not in an epidemic and IS over the threshold to trigger
      #         the start of one
      epi_markers[period_time_indices] <- epi_count
      epi_state <- "started"
      non_epi_count <- non_epi_count - 1
    } else if (!cur_val && cur_len >= 3 && epi_state == "started") {
      # branch: already in an epidemic and died out
      #
      epi_markers[period_time_indices] <- non_epi_count
      epi_state <- "none"
      epi_count <- epi_count + 1
    } else if (epi_state == "started") {
      # branch: already in an epidemic and still on-going
      #
      epi_markers[period_time_indices] <- epi_count # "-"
    } else {
      stop(paste0("err at RLE index", i))
    }
  }

  weekly_inc_df %>%
    mutate(epi_marker = epi_markers) %>%
    group_by(epi_marker) %>%
    mutate(period_len = n()) %>%
    ungroup()
}
