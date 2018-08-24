source("init.R")


# GLOBAL FILTERS ----------------------------------------------------------
mnth = 4

daily <- daily %>%
  filter(date > Sys.Date() - months(mnth))

# sleep_by_hr <- sleep_by_hr %>%
#   filter(sleepdate > Sys.Date() - months(mnth))

sleep_detailed <- sleep_detailed %>%
  filter(sleepdate > Sys.Date() - months(mnth))

sleep_summaries <- sleep_summaries %>%
  filter(dateOfSleep > Sys.Date() - months(mnth))

# CHARTS INTRADAY  ------------------------------------------------------------------
# intraday steps
intraday %>%
  filter(as.Date(datetime) > today() - days(3)) %>%
  mutate(Date = as.character(as.Date(datetime))) %>%
  ggplot() +
  geom_area(aes(update(datetime, year = 2020, month = 1, day = 1), cum_steps, alpha = Date), fill = step_color, color = "black", position = "dodge") +
  geom_line(aes(update(datetime, year = 2020, month = 1, day = 1), steps), color = "black", position = "dodge", size = 0.3) +
  labs(title = ("Steps Last 3 Days"), x = "Time (hrs)", y = "Steps") +
  scale_x_datetime(breaks=date_breaks("6 hour"), labels=date_format("%H:%M")) +
  facet_wrap(~ reorder(format(as.Date(datetime), "%A"), datetime)) +
  theme_light() +
  theme(legend.position = "bottom")
ggsave("charts/steps-intraday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

# intraday calories
# label <- intraday %>%
#   summarise(
#     datetime = max(update(datetime, year = 2020, month = 1, day = 1)),
#     calories = max(calories),
#     label = "test"
#   )

intraday %>%
  filter(as.Date(datetime) > today() - days(3)) %>%
  mutate(Date = as.character(as.Date(datetime))) %>%
  ggplot() +
  # geom_area(aes(update(datetime, year = 2020, month = 1, day = 1), cum_calories, alpha = Date), fill = calory_color, color = "black", position = "dodge") +
  # geom_line(aes(update(datetime, year = 2020, month = 1, day = 1), calories), color = "black", position = "dodge", size = 0.3) +
  geom_area(aes(update(datetime, year = 2020, month = 1, day = 1), calories, alpha = Date), color = "black", fill = calory_color, position = "dodge") +
  facet_wrap(~ reorder(format(as.Date(datetime), "%A"), datetime)) +
  # geom_text(aes(label = label), data = label, vjust = "top", hjust = "right") +
  scale_x_datetime(breaks=date_breaks("6 hour"), labels=date_format("%H:%M")) +
  theme_light() +
  theme(legend.position = "bottom") +
  labs(title = ("Calories Spent Last 3 Days"), x = "Time (hrs)", y = "Calories")
ggsave("charts/cal-intraday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

# on top of each other
intraday %>%
  filter(as.Date(datetime) > today() - days(4)) %>%
  mutate(Date = as.character(as.Date(datetime))) %>%
  ggplot() +
  geom_line(aes(update(datetime, year = 2020, month = 1, day = 1), cum_calories, alpha = Date), color = calory_color, position = "dodge", size = 2) +
  # geom_line(aes(update(datetime, year = 2020, month = 1, day = 1), calories), color = "black", position = "dodge", size = 0.3) +
  # geom_area(aes(update(datetime, year = 2020, month = 1, day = 1), calories, alpha = Date), color = "black", fill = calory_color, position = "dodge") +
  # facet_wrap(~ reorder(format(as.Date(datetime), "%A"), datetime)) +
  # geom_text(aes(label = label), data = label, vjust = "top", hjust = "right") +
  scale_x_datetime(breaks=date_breaks("6 hour"), labels=date_format("%H:%M")) +
  scale_y_continuous(position = "right", breaks = extended_breaks(15)) +
  theme_light() +
  theme(legend.position = "bottom") +
  labs(title = ("Calories over the Day - Last 4 Days"), x = "Time (hrs)", y = "Calories")
ggsave("charts/cal-intraday-cum.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")


# CHARTS DAILY  ------------------------------------------------------
# mutli month calories

daily %>%
  filter(date != today) %>%
  ggplot(aes(date, calories)) +
  geom_point(aes(color = calories, shape = workday), size = 2) +
  geom_line(alpha = 1/3) +
  theme(legend.position = "bottom") +
  # scale_color_continuous("BrBG") +
  # scale_color_gradient_tableau("BrBG") +
  scale_color_gradient(low="brown", high="Green", guide = "none") +
  geom_smooth(se = FALSE, method = "loess") +
  theme_light() +
  theme(legend.position = "bottom") +
  labs(title = "Calories per Day", x = "Date", y = "Calories")
ggsave("charts/cal-date.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")


daily %>%
  filter(date != today) %>%
  ggplot(aes(x = reorder(format(date, "%b"), date), calories)) +
  geom_violin(alpha = 1/4, fill = calory_color) +
  geom_jitter(aes(color = workday, shape = vacation), alpha = 2/4) +
  labs(title = "Calories spent per day", x = "Time", y = "Calories") +
  scale_color_calc() +
  theme_light()
ggsave("charts/cal-day2.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")


# CHARTS SLEEP SUMARIES-------------------------------------------------------------


sleep_summaries %>%
  filter(type == "stages") %>%
  filter(hoursAsleep > 5 ) %>%
  filter(dateOfSleep > "2017-12-01") %>%
  ggplot(aes(dateOfSleep, hoursAsleep)) +
  geom_col(aes(fill = hoursAsleep)) +
  geom_line(aes(y = hoursAwake, color = hoursAwake), size = 1) +
  scale_fill_continuous_tableau(c("Blue")) +
  scale_color_continuous_tableau("Red") +
  geom_smooth(se = FALSE, method = "loess", color = trend_color, size = 0.5, alpha = 0.2) +
  theme_light() +
  theme(legend.position = "bottom") +
  labs(title = "Sleep Trends", x = "Time", y = "Hours", color = "Hours Awake", fill = "Hours Asleep")
ggsave("charts/sleep-multiday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")


sleep_summaries %>%
  filter(type == "stages") %>%
  filter(hoursAsleep > 5 ) %>%
  ggplot(aes(dateOfSleep, hoursAwake)) +
  geom_col(aes(fill = hoursAwake)) +
  scale_fill_continuous_tableau(c("Red")) +
  geom_smooth(se = FALSE, method = "loess", color = trend_color, size = 1) +
  theme_light() +
  theme(legend.position = "bottom") +
  labs(title = "Hours awake during the night", x = "time", y = "Hours Awake", color = "Hours Awake")
ggsave("charts/sleep-awake-multiday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

sleep_summaries %>%
  filter(type == "stages") %>%
  filter(hoursAsleep > 5 ) %>%
  ggplot(aes(dateOfSleep, perc_awake)) +
  geom_point(aes(color = perc_awake), size = 2.5, alpha = 0.8) +
  geom_line(aes(color = perc_awake), alpha = 1/4, size = 2.5) +
  scale_color_continuous_tableau("Red") +
  geom_smooth(se = FALSE, method = "loess", color = trend_color) +
  theme_light() +
  theme(legend.position = "bottom") +
  labs(title = "Percentage awake", x = "time", y = "% Awake", color = "% Awake")
ggsave("charts/sleep-perc-awake-multiday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")





# CHARTS SLEEP DETAILED -------------------------------------------------------

sleep_detailed %>%
  filter(as.Date(sleepdate) > today() - days(3)) %>%
  ggplot(aes(fix_start, level)) +
  geom_segment(aes(xend = fix_end, yend = level, color = level), size = 7) +
  facet_grid(fct_rev(as_factor(reorder(format(sleepdate, "%A"), sleepdate))) ~ .) +
  theme_light() +
  scale_color_brewer(palette = "RdYlBu", direction = -1) +
  scale_x_datetime(breaks=date_breaks("2 hour"), labels=date_format("%H:%M")) +
  labs(title = "Sleep Last 3 Nights", x = "Time", y = "")
ggsave("charts/sleep-3nights.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")
#





