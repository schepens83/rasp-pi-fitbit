require(tidyverse) || install.packages("tidyverse") 
require(devtools) || install.packages("devtools")
require(fitbitr) || devtools::install_github("teramonagi/fitbitr")
require(ggthemes) || install.packages("ggthemes")
require(scales) || install.packages("scales")
require(lubridate) || install.packages("lubridate")
require(PerformanceAnalytics) || install.packages("PerformanceAnalytics")

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

# ADDITIONAL VARS ---------------------------------------------------------
today = as.character(first(intraday$download_date))
chart_magnifier = 1
calory_color = "#FF4500"
vacation_weeks = c(1724,1725,1726,1744,1745,1752)
trend_color = "#ff8080"


# WRANGLING INTRADAY ----------------------------------------------------------
intraday_calories <- intraday_calories %>% rename(calories = value) 
intraday_calories <- intraday_calories %>% select(-download_date)
intraday_steps <- intraday_steps %>% rename(steps = value)
intraday_distance <- intraday_distance %>% rename(km = value)
intraday_distance <- intraday_distance %>% select(-download_date)

intraday <- full_join(intraday_steps, intraday_calories, by="time")
intraday <- full_join(intraday, intraday_distance, by="time")
intraday <- intraday %>% mutate(tmp = hms(time))

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
            type = first(type))

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





# CHARTS INTRADAY  ------------------------------------------------------------------
# intraday steps
ggplot(intraday) +
  geom_area(aes(as.numeric(time)/3600, steps), fill = "#8B4513", color = "black", size = 1.5) +
  labs(title = paste("Steps taken on", today), x = "Time (hrs)", y = "Steps") +
  scale_x_continuous(breaks = seq(0,24, 1)) +
  theme_bw() 
ggsave("charts/steps-intraday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

# intraday calories
ggplot(intraday) +
  geom_area(aes(as.numeric(time)/3600, calories - 19), fill = calory_color, color = "black", size = 1.5) +
  labs(title = paste("Calories spent on", today), x = "Time (hrs)", y = "Calories") +
  scale_x_continuous(breaks = seq(0,24, 1)) +
  theme_bw() 
ggsave("charts/cal-intraday.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")


# CHARTS DAILY  ------------------------------------------------------
# mutli month calories
daily %>%
  filter(date != today) %>%
  ggplot(aes(date, calories)) +
  geom_point(aes(color = day.of.week), alpha = 2/3, size = 2) +
  geom_line() + 
  geom_smooth(se = FALSE, color = trend_color) +
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
  geom_smooth(se = FALSE, color = "#ff8080") +
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
ggsave("charts/act-type-weekly.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

# mutli month steps
daily %>%
  filter(date != today) %>%
  ggplot(aes(date, steps)) +
  geom_point(aes(color = day.of.week), alpha = 2/3, size = 2) +
  geom_line() + 
  geom_smooth(se = FALSE, color = "#ff8080", size = 0.8) +
  labs(title = "Steps per day", x = "Time", y = "Steps") +
  facet_grid(workday ~ .) +
  theme_few() + 
  scale_color_calc() +
  theme(legend.position = "bottom")
ggsave("charts/steps-day.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

# CHARTS SLEEP SUMARIES-------------------------------------------------------------

# sleep over days past
sleep_summaries %>%
  filter(type == "stages") %>%
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

# sleep versus time to bed
sleep_summaries %>%
  filter(type == "stages") %>%
  filter(hour(startTime) > 6) %>%
  ggplot(aes(update(startTime, year = 2000, month = 1, day = 1), hoursAsleep)) +
  geom_point(aes(color = hoursAwake), size = 2.5) + 
  geom_line(alpha = 1/4) + 
  facet_wrap(~ workday) + 
  scale_colour_gradient(low = "lightgreen", high = "darkred") + 
  geom_smooth(se = FALSE, method = "lm", color = trend_color) +
  theme_few() + 
  theme(legend.position = "bottom") + 
  scale_x_datetime(date_labels = "%H:%M") +
  labs(title = "Sleep vs time to bed", x = "Time", y = "Hours Asleep", color = "Hours Awake")
ggsave("charts/sleep-vs-timetobed.png", device = "png", width = 155 * chart_magnifier, height = 93 * chart_magnifier, units = "mm")

sleep_summaries %>% 
  group_by(dateOfSleep) %>% 
  summarize_if(.predicate = "is.numeric", "sum") %>% 
  select(-dateOfSleep) %>%
  chart.Correlation()


# CHARTS SLEEP DETAILED -------------------------------------------------------


