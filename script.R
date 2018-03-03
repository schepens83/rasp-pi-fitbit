source("init.R")


# GLOBAL FILTERS ----------------------------------------------------------
daily <- daily %>%
  filter(date > Sys.Date() - months(5))

sleep_by_hr <- sleep_by_hr %>%
  filter(sleepdate > Sys.Date() - months(5))

sleep_detailed <- sleep_detailed %>%
  filter(sleepdate > Sys.Date() - months(5))

sleep_summaries <- sleep_summaries %>%
  filter(dateOfSleep > Sys.Date() - months(5))

# CHARTS INTRADAY  ------------------------------------------------------------------
# intraday steps
intraday %>%
  filter(as.Date(datetime) > today() - days(3)) %>%
  mutate(Date = as.character(as.Date(datetime))) %>%
  ggplot() +
  geom_area(aes(update(datetime, year = 2020, month = 1, day = 1), steps, alpha = Date), color = "black", fill = step_color, position = "dodge") +
  labs(title = ("Steps Last 3 Days"), x = "Time (hrs)", y = "Steps") +
  scale_x_datetime(breaks=date_breaks("6 hour"), labels=date_format("%H:%M")) +
  facet_wrap(~ reorder(format(as.Date(datetime), "%A"), datetime)) +
  theme_few() +
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
  geom_area(aes(update(datetime, year = 2020, month = 1, day = 1), calories, alpha = Date), color = "black", fill = calory_color, position = "dodge") +
  facet_wrap(~ reorder(format(as.Date(datetime), "%A"), datetime)) +
  # geom_text(aes(label = label), data = label, vjust = "top", hjust = "right") +
  scale_x_datetime(breaks=date_breaks("6 hour"), labels=date_format("%H:%M")) +
  theme_few() +
  theme(legend.position = "bottom") +
  labs(title = ("Calories Spent Last 3 Days"), x = "Time (hrs)", y = "Calories") 
ggsave("charts/cal-intraday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

# stat_summary(fun.y = "sum", aes(datetime, calories)) +
# geom_col

# CHARTS DAILY  ------------------------------------------------------
# mutli month calories

daily %>% 
  filter(date != today) %>%
  ggplot(aes(date, calories)) + 
  geom_point(aes(color = workday)) + 
  geom_line(alpha = 1/3) + 
  theme(legend.position = "bottom") +
  scale_colour_brewer(palette="Set1", direction=-1) +
  geom_smooth(se = FALSE) + 
  theme_few() +
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
  theme_few() 
ggsave("charts/cal-day2.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")


# CHARTS SLEEP SUMARIES-------------------------------------------------------------


sleep_summaries %>%
  filter(type == "stages") %>%
  filter(hoursAsleep > 5 ) %>%
  ggplot(aes(dateOfSleep, hoursAsleep)) +
  geom_point(aes(color = hoursAwake), size = 2.5) + 
  geom_line(alpha = 1/4) + 
  scale_colour_gradient(low = "lightgreen", high = "darkred") + 
  geom_smooth(se = FALSE, method = "loess", color = trend_color) +
  theme_few() + 
  theme(legend.position = "bottom") + 
  labs(title = "Sleep Trends", x = "Time", y = "Hours Asleep", color = "Hours Awake")
ggsave("charts/sleep-multiday-workday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")


sleep_summaries %>% 
  filter(type == "stages") %>%
  filter(hoursAsleep > 5 ) %>%
  ggplot(aes(dateOfSleep, hoursAwake)) +
  geom_point(aes(color = hoursAsleep), size = 2.5) + 
  geom_line(alpha = 1/4) + 
  scale_colour_gradient(low = "darkred", high = "lightgreen") + 
  geom_smooth(se = FALSE, method = "loess", color = trend_color) +
  theme_few() + 
  theme(legend.position = "bottom") +
  labs(title = "Hours awake during the night", x = "time", y = "Number of Hours", color = "Hours Asleep")
ggsave("charts/sleep-awake-multiday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

sleep_summaries %>% 
  filter(type == "stages") %>%
  filter(hoursAsleep > 5 ) %>%
  ggplot(aes(dateOfSleep, perc_awake)) +
  geom_point(aes(size = hoursAsleep, color = hoursAsleep), alpha = 0.8) + 
  geom_line(alpha = 1/4) + 
  scale_colour_gradient(low = "darkred", high = "lightgreen") + 
  geom_smooth(se = FALSE, method = "loess", color = trend_color) +
  theme_few() + 
  theme(legend.position = "bottom") +
  labs(title = "Percentage awake", x = "time", y = "% Awake", size = "Hours Asleep", color = "Hours Asleep")
ggsave("charts/sleep-perc-awake-multiday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")





# CHARTS SLEEP DETAILED -------------------------------------------------------

sleep_detailed %>%
  filter(as.Date(sleepdate) > today() - days(3)) %>%
  ggplot(aes(fix_start, level)) +
  geom_segment(aes(xend = fix_end, yend = level, color = level), size = 7) +
  facet_grid(fct_rev(as_factor(reorder(format(sleepdate, "%A"), sleepdate))) ~ .) +
  theme_few() + 
  scale_color_brewer(palette = "PuRd") +
  scale_x_datetime(breaks=date_breaks("2 hour"), labels=date_format("%H:%M")) +
  labs(title = "Sleep Last 3 Nights", x = "Time", y = "")
ggsave("charts/sleep-3nights", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")
# 





