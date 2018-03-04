source("init.R")



# GLOBAL FILTERS ----------------------------------------------------------
daily <- daily %>%
  filter(date > Sys.Date() - months(5))

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
  geom_point(aes(color = day.of.week), alpha = 2/3, size = 2) +
  geom_line() + 
  geom_smooth(se = FALSE, color = trend_color, method = "loess") +
  labs(title = "Calories spent per day", x = "Time", y = "Calories") +
  facet_wrap(~ workday) +
  theme_few() + 
  theme(legend.position = "bottom")
ggsave("charts/cal-day.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

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
  ggplot(aes(date, calories)) +
  geom_point(aes(color = vacation, size = calories), alpha = 2/3) +
  geom_line() + 
  geom_smooth(se = FALSE, color = "#ff8080", method = "loess") +
  labs(title = "Calories spent per day", x = "Time", y = "Calories") +
  facet_wrap(~ day.of.week) +
  scale_colour_colorblind() +
  theme_few() +
  theme(legend.position = "top")
# ggsave("charts/cal-perday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

daily %>% 
  filter(date != today) %>%
  ggplot(aes(x = reorder(format(date, "%b"), date), calories)) +
  geom_violin(alpha = 1/4, fill = calory_color) +
  geom_jitter(aes(color = workday, shape = vacation), alpha = 2/4) +
  labs(title = "Calories spent per day", x = "Time", y = "Calories") +
  scale_color_calc() +
  theme_few() 
ggsave("charts/cal-day2.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

# multi month type active
daily %>%
  filter(!sedentary > 1000 & !lightly_active > 500,
         date > as.Date(today) - 90) %>%
  group_by(Time = format(date, "%y%W")) %>%
  summarise(sedentary = sum(sedentary),
            fairly_active = sum(fairly_active),
            lightly_active = sum(lightly_active),
            very_active = sum(very_active)
            ) %>% 
  gather(key = "type_activity", value = "minutes", sedentary:very_active) %>% 
  mutate(type_activity = factor(type_activity, c("very_active", "fairly_active", "lightly_active", "sedentary")),
         hours = minutes / 60) %>% 
  ggplot() +
  geom_bar(stat="summary", fun.y=sum, position = "fill", aes(x = Time, y = hours, fill = type_activity)) +
  labs(title = "Time spent per Activity", y = "Fraction of Activity") +
  theme_few() +
  theme(legend.position = "bottom")
# ggsave("charts/act-type-weekly.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

# mutli month steps
daily %>%
  filter(date != today) %>%
  ggplot(aes(date, steps)) +
  geom_point(aes(color = day.of.week), alpha = 2/3, size = 2) +
  geom_line() + 
  geom_smooth(se = FALSE, color = "#ff8080", size = 0.8, method = "loess") +
  labs(title = "Steps per day", x = "Time", y = "Steps") +
  facet_grid(workday ~ .) +
  theme_few() + 
  scale_color_calc() +
  theme(legend.position = "right")
ggsave("charts/steps-day.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

# CHARTS SLEEP SUMARIES-------------------------------------------------------------

# sleep over days past
sleep_summaries %>%
  filter(type == "stages") %>%
  filter(hoursAsleep > 5 ) %>%
  ggplot(aes(dateOfSleep, hoursAsleep)) +
  geom_point(aes(color = hoursAwake), size = 2.5) + 
  geom_line(alpha = 1/4) + 
  facet_wrap(~ workday) + 
  scale_colour_gradient(low = "lightgreen", high = "darkred") + 
  geom_smooth(se = FALSE, method = "loess", color = trend_color) +
  theme_few() + 
  theme(legend.position = "bottom") + 
  labs(title = "Sleep Trends", x = "Time", y = "Hours Asleep", color = "Hours Awake")
ggsave("charts/sleep-multiday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

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

# sleep versus time to bed
sleep_summaries %>%
  filter(type == "stages") %>%
  filter(hour(startTime) > 19) %>% 
  filter(hoursAsleep > 5 ) %>%
  # filter(dateOfSleep > as_date("2017-10-01") ) %>%
  ggplot(aes(update(startTime, year = 2000, month = 1, day = 1), hoursAsleep)) +
  geom_point(aes(color = hoursAwake, shape = vacation), size = 2.5) + 
  facet_wrap(~ workday) + 
  scale_colour_gradient(low = "lightgreen", high = "darkred") + 
  geom_smooth(se = FALSE, method = "lm", color = trend_color) +
  theme_few() + 
  theme(legend.position = "bottom") + 
  scale_x_datetime(date_labels = "%H:%M") +
  labs(title = "Sleep vs time to bed", x = "Time to Bed", y = "Hours Asleep", color = "Hours Awake", shape = "")
# ggsave("charts/sleep-vs-timetobed.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

sleep_summaries %>% 
  filter(type == "stages") %>%
  filter(hoursAsleep > 5 ) %>%
  ggplot(aes(dateOfSleep, hoursAwake)) +
  geom_point(aes(color = efficiency), size = 2.5) + 
  geom_line(alpha = 1/4) + 
  scale_colour_gradient(low = "darkred", high = "lightgreen") + 
  geom_smooth(se = FALSE, method = "loess", color = trend_color) +
  theme_few() + 
  theme(legend.position = "bottom") 

sleep_summaries %>%
  filter(type == "stages") %>%
  filter(hour(startTime) > 19) %>% 
  filter(hoursAsleep > 5 ) %>%
  mutate(time_asleep = update(startTime, year = 2000, month = 1, day = 1)) %>% 
  ggplot(aes(dateOfSleep, hoursAsleep)) +
  geom_point(aes(color = time_asleep, size = time_asleep), alpha = 3/3) + 
  geom_line(alpha = 1/4) + 
  scale_colour_gradient(low = "darkred", high = "lightgreen") + 
  geom_smooth(se = FALSE, method = "loess", color = trend_color) +
  theme_few() + 
  theme(legend.position = "bottom") 


# sleep_summaries %>%
#   group_by(dateOfSleep) %>%
#   summarize_if(.predicate = "is.numeric", "sum") %>%
#   select(-dateOfSleep) %>%
#   chart.Correlation()


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
  
# CHARTS SLEEP BY HOUR ----------------------------------------------------

sleep_by_hr %>%
  ggplot(aes(date, time / 3600)) +
  geom_boxplot(aes(group = date, fill = level)) +
  facet_grid(level ~ .) +
  theme_few() + 
  labs(title = "Time per Sleep Phase", x = "Time", y = "Hours", fill = "Phase")
# ggsave("charts/sleep-per-phase-boxplot", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

sleep_by_hr %>%
  ggplot(aes(date, time / 3600)) +
  stat_summary(fun.y = "mean", geom = "bar", aes(fill = fct_rev(level)), position = "fill") +
  theme_few() + 
  labs(title = "Average Time per Sleep Phase", x = "Time", y = "Fraction", fill = "Phase")
# ggsave("charts/sleep-per-phase-boxplot", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

sleep_by_hr %>%
  # filter(days_ago < 14) %>%
  ggplot(aes(date, time / 3600)) +
  stat_summary(fun.y = "mean", geom = "bar", aes(fill = fct_rev(level)), position = "stack") +
  theme_few() + 
  facet_grid(. ~ workday) +
  labs(title = "Average Time per Sleep Phase", x = "Time", y = "Average Hours", fill = "Phase")

sleep_by_hr %>%
  filter(level == "wake") %>%
  filter(sleepdate > update(as_datetime(today) - months(3), day = 1)) %>%
  ggplot(aes(x = date, y = time / 3600)) +
  geom_smooth(aes(color = workday, linetype = workday), method = "loess") +
  geom_point(alpha = 1/4, aes(color = workday)) +
  facet_wrap(~ reorder(format(sleepdate, "%B %Y"), sleepdate)) +
  theme_few() +
  scale_x_datetime(breaks=date_breaks("3 hour"), labels=date_format("%H:%M")) +
  theme(legend.position = "right") +
  labs(title = "Average Time Awake", x = "Time", y = "Fraction Hour", color = "", linetype = "")
ggsave("charts/awake-month", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")





