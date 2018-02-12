require(tidyverse) 
require(devtools) 
# require(fitbitr) 
require(ggthemes) 
require(scales)
require(lubridate)
# require(PerformanceAnalytics)

# DATA IMPORT -------------------------------------------------------------
# intraday
intraday_steps <- readr::read_csv("csv/activities-steps-intraday.csv")
intraday_calories <- readr::read_csv("csv/activities-calories-intraday.csv")
intraday_distance <- readr::read_csv("csv/activities-distance-intraday.csv")

# daily
daily_calories <- readr::read_csv("csv/activities-calories.csv")
daily_steps <- readr::read_csv("csv/activities-steps.csv")
daily_activities_sedentary <- readr::read_csv("csv/activities-minutes-sedentary.csv")
daily_activities_fairly_active <- readr::read_csv("csv/activities-minutes-fairly-active.csv")
daily_activities_lightly_active <- readr::read_csv("csv/activities-minutes-lightly-active.csv")
daily_activities_very_active <- readr::read_csv("csv/activities-minutes-very-active.csv")

# sleep summaries
sleep_summaries <- readr::read_csv("csv/sleep-summaries.csv")

# sleep detailed
sleep_detailed <- readr::read_csv("csv/sleep-time-series.csv")


# FUNCTIONS ---------------------------------------------------------------
just_time <- function(datetime, mdy, hr, mn, sec){
  return(update(datetime, year = 2000, month = 1, mday = mdy, hour = hr, min = mn, second = sec))
}

seconds_overlap <- function(interval, startTime, hr) {
  tmp = interval(update(startTime, hour = hr, minute = 0, second = 0), update(startTime, hour = hr + 1, minute = 0, second = 0))
  return(seconds(as.period(intersect(interval, tmp), "seconds")))
}

# ADDITIONAL VARS ---------------------------------------------------------
today = as.character(first(daily_calories$download_date))
chart_magnifier = 1
calory_color = "#FF4500"
step_color = "#8B4513"
vacation_weeks = c(1724,1725,1726,1744,1745,1752)
trend_color = "#ff8080"


# WRANGLING INTRADAY ----------------------------------------------------------
intraday_calories <- intraday_calories %>% rename(calories = value,
                                                  calorie_level = level,
                                                  calorie_mets = mets
                                                  ) 
intraday_calories <- intraday_calories %>% mutate(datetime = as.POSIXct(paste(date, time), format="%Y-%m-%d %H:%M:%S"))
intraday_calories <- intraday_calories %>% select(-download_date, -time, -date)

intraday_steps <- intraday_steps %>% rename(steps = value)
intraday_steps <- intraday_steps %>% mutate(datetime = as.POSIXct(paste(date, time), format="%Y-%m-%d %H:%M:%S"))
intraday_steps <- intraday_steps %>% select(-time, -date)

intraday_distance <- intraday_distance %>% rename(km = value)
intraday_distance <- intraday_distance %>% mutate(datetime = as.POSIXct(paste(date, time), format="%Y-%m-%d %H:%M:%S"))
intraday_distance <- intraday_distance %>% select(-download_date, -date)

intraday <- full_join(intraday_steps, intraday_calories, by="datetime")
intraday <- full_join(intraday, intraday_distance, by="datetime")
intraday <- intraday %>% select(download_date, datetime, everything())

rm(list = c("intraday_calories", "intraday_steps", "intraday_distance"))

# WRANGLING DAILY ---------------------------------------------------------
daily_calories <- daily_calories %>% rename(calories = value) 
daily_steps <- daily_steps %>% rename(steps = value) 
daily_activities_sedentary <- daily_activities_sedentary %>% rename(sedentary = value) 
daily_activities_fairly_active <- daily_activities_fairly_active %>% rename(fairly_active = value) 
daily_activities_lightly_active <- daily_activities_lightly_active %>% rename(lightly_active = value) 
daily_activities_very_active <- daily_activities_very_active %>% rename(very_active = value) 

daily_steps <- daily_steps %>% select(-download_date) 
daily_activities_sedentary <- daily_activities_sedentary %>% select(-download_date) 
daily_activities_fairly_active <- daily_activities_fairly_active %>% select(-download_date) 
daily_activities_lightly_active <- daily_activities_lightly_active %>% select(-download_date) 
daily_activities_very_active <- daily_activities_very_active %>% select(-download_date) 

daily <- full_join(daily_activities_sedentary, daily_activities_fairly_active, by="time")
daily <- full_join(daily, daily_calories, by="time")
daily <- full_join(daily, daily_steps, by="time")
daily <- full_join(daily, daily_activities_lightly_active, by="time")
daily <- full_join(daily, daily_activities_very_active, by="time")

daily <- daily %>% select(download_date, time, calories, steps, sedentary, fairly_active, lightly_active, very_active)
daily <- daily %>% rename(date = time)

daily <- daily %>% mutate(week = format(date, "%y%V"),
                          day.of.week = factor(format(date, "%a"), levels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")),
                          vacation = as.factor(ifelse(week %in% vacation_weeks, "vacation", "no vacation")),
                          workday = as.factor(ifelse(vacation == "no vacation" & day.of.week %in% c("Tue", "Wed", "Thu"), "workday", "non-workday"))
                          )

rm(list = c("daily_activities_sedentary", "daily_activities_fairly_active", "daily_activities_lightly_active", "daily_activities_very_active", "daily_calories", "daily_steps"))


# WRANGLING SLEEP SUMARIES ------------------------------------------------
# set in the right sequence
sleep_summaries <- sleep_summaries %>% 
  select(download_date, dateOfSleep, startTime, endTime, duration, efficiency,minutesToFallAsleep, minutesAsleep, minutesAwake, minutesAfterWakeup, minInBed, infoCode,logId, type)

sleep_summaries <- sleep_summaries %>%
  filter(type != "classic",
         efficiency < 100,
         efficiency > 70)

sleep_summaries <- sleep_summaries %>% 
  group_by(dateOfSleep) %>% 
  summarise(download_date = first(download_date),
            startTime = first(startTime),
            endTime = last(endTime),
            efficiency = sum(efficiency),
            duration = sum(duration),
            minutesToFallAsleep = sum(minutesToFallAsleep),
            minutesAsleep = sum(minutesAsleep),
            minutesAwake = sum(minutesAwake),
            minutesAfterWakeup = sum(minutesAfterWakeup),
            minInBed = sum(minInBed),
            infoCode = last(infoCode),
            type = last(type))

sleep_summaries <- sleep_summaries %>% 
  mutate(duration.min = duration / 60000,
         duration.hrs = duration / 3600000,
         hoursAsleep = minutesAsleep / 60,
         hoursAwake = minutesAwake / 60) %>%
  select(-duration)

sleep_summaries <- sleep_summaries %>%
  mutate(week = format(dateOfSleep, "%y%V"),
         day.of.week = factor(format(dateOfSleep, "%a"), levels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")),
         vacation = as.factor(ifelse(week %in% vacation_weeks, "vacation", "no vacation")),
         workday = as.factor(ifelse(vacation == "no vacation" & day.of.week %in% c("Tue", "Wed", "Thu"), "workday", "non-workday")),
         weekend = as.factor(ifelse(day.of.week %in% c("Sat", "Sun"), "weekend", "non-weekend"))
         )
  
# WRANGLING SLEEP DETAILED ------------------------------------------------
sleep_detailed <- sleep_detailed %>% select(download_date, sleepdate, dateTime, level, seconds)

sleep_detailed <- sleep_detailed %>% 
  mutate(start = dateTime,
         end = dateTime + seconds)

  
sleep_detailed <- sleep_detailed %>%
  mutate(date = ymd_hms("2020-01-02 01:00:00"),
         dy_start = ifelse(as.integer(hour(start)) > 18, day(date) - 1, day(date)),
         dy_end = ifelse(as.integer(hour(end)) > 18, day(date) - 1, day(date)),         
         fix_start = update(date, hour = hour(start), minute = minute(start), second = second(start), day = dy_start),
         fix_end = update(date, hour = hour(end), minute = minute(end), second = second(end), day = dy_end)
  ) %>%
  select(-dy_start, -dy_end, -date)

# WRANGLING SLEEP BY HOUR ------------------------------------------------
sleep_by_hr <- sleep_detailed %>% select(download_date, sleepdate, dateTime, level, seconds)

sleep_by_hr <- sleep_by_hr %>% 
  filter(level != "asleep") %>% 
  filter(level != "awake") %>% 
  filter(level != "restless") %>% 
  mutate(endTime = dateTime + seconds,
         startTime = dateTime,
         startDay = day(startTime),
         interval = interval(startTime, endTime),
         now = Sys.Date(),
         `21` = seconds_overlap(interval, startTime, 21),
         `22` = seconds_overlap(interval, startTime, 22),
         `23` = seconds_overlap(interval, startTime, 23),
         tmp = interval(update(endTime, hour = 0, minute = 0, second = 1), update(endTime, hour = 1, minute = 0, second = 0)),
         `0` = seconds(as.period(intersect(interval, tmp), "seconds")) + 1,
         `1` = seconds_overlap(interval, endTime, 1),
         `2` = seconds_overlap(interval, endTime, 2),
         `3` = seconds_overlap(interval, endTime, 3),
         `4` = seconds_overlap(interval, endTime, 4),
         `5` = seconds_overlap(interval, endTime, 5),
         `6` = seconds_overlap(interval, endTime, 6),
         `7` = seconds_overlap(interval, endTime, 7),
         `8` = seconds_overlap(interval, endTime, 8),
         `9` = seconds_overlap(interval, endTime, 9),
         `10` = seconds_overlap(interval, endTime, 10),
         week = format(sleepdate, "%y%V"),
         day.of.week = factor(format(sleepdate, "%a"), levels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")),
         vacation = as.factor(ifelse(week %in% vacation_weeks, "vacation", "no vacation")),
         workday = as.factor(ifelse(vacation == "no vacation" & day.of.week %in% c("Tue", "Wed", "Thu"), "workday", "non-workday")),
         days_ago = as.integer(as_date(today) - sleepdate)
        ) %>% 
  select(-now, -startDay, -tmp, -dateTime, -download_date, -interval, -seconds) %>%
  gather(`21`, `22`, `23`, `0`, `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, key = "hour", value = "time") %>%
  filter(is.na(time) == FALSE) 

(date <- ymd_hms("2016-07-08 12:34:56"))

sleep_by_hr <- sleep_by_hr %>%
  mutate(date = ymd_hms("2020-01-02 01:00:00"),
         dy = ifelse(as.integer(hour) > 18, day(date) - 1, day(date)),
         date = update(date, hour = as.integer(hour), day = dy)
         ) %>%
  select(-dy)


sleep_by_hr <- sleep_by_hr %>%
  group_by(sleepdate, date, vacation, workday, day.of.week, days_ago, level) %>%
  summarise(time = sum(time))


# 

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





