require(tidyverse) || install.packages("tidyverse") 
require(devtools) || install.packages("devtools")
require(fitbitr) || devtools::install_github("teramonagi/fitbitr")
require(ggthemes) || install.packages("ggthemes")
require(scales) || install.packages("scales")
require(lubridate) || install.packages("lubridate")

# DATA IMPORT -------------------------------------------------------------
# intraday
intraday_steps <- readr::read_csv("csv/activities-steps-intraday.csv")
intraday_calories <- readr::read_csv("csv/activities-calories-intraday.csv")
intraday_distance <- readr::read_csv("csv/activities-distance-intraday.csv")

# daily
daily_calories <- readr::read_csv("csv/activities-calories.csv")
daily_activities_sedentary <- readr::read_csv("csv/activities-minutes-sedentary.csv")
daily_activities_fairly_active <- readr::read_csv("csv/activities-minutes-fairly-active.csv")
daily_activities_lightly_active <- readr::read_csv("csv/activities-minutes-lightly-active.csv")
daily_activities_very_active <- readr::read_csv("csv/activities-minutes-very-active.csv")

# sleep summaries
sleep_summaries <- readr::read_csv("csv/sleep-summaries.csv")

# sleep detailed
sleep_detailed <- readr::read_csv("csv/sleep-time-series.csv")

# DATA WRANGLING ----------------------------------------------------------
# intraday
intraday_calories <- intraday_calories %>% rename(calories = value) 
intraday_calories <- intraday_calories %>% select(-download_date)
intraday_steps <- intraday_steps %>% rename(steps = value)
intraday_distance <- intraday_distance %>% rename(km = value)
intraday_distance <- intraday_distance %>% select(-download_date)

intraday <- full_join(intraday_steps, intraday_calories, by="time")
intraday <- full_join(intraday, intraday_distance, by="time")
intraday <- intraday %>% mutate(tmp = hms(time))

rm(list = c("intraday_calories", "intraday_steps", "intraday_distance"))

# daily
daily_calories <- daily_calories %>% rename(calories = value) 
daily_activities_sedentary <- daily_activities_sedentary %>% rename(sedentary = value) 
daily_activities_fairly_active <- daily_activities_fairly_active %>% rename(fairly_active = value) 
daily_activities_lightly_active <- daily_activities_lightly_active %>% rename(lightly_active = value) 
daily_activities_very_active <- daily_activities_very_active %>% rename(very_active = value) 

daily_activities_sedentary <- daily_activities_sedentary %>% select(-download_date) 
daily_activities_fairly_active <- daily_activities_fairly_active %>% select(-download_date) 
daily_activities_lightly_active <- daily_activities_lightly_active %>% select(-download_date) 
daily_activities_very_active <- daily_activities_very_active %>% select(-download_date) 

daily <- full_join(daily_activities_sedentary, daily_activities_fairly_active, by="time")
daily <- full_join(daily, daily_calories, by="time")
daily <- full_join(daily, daily_activities_lightly_active, by="time")
daily <- full_join(daily, daily_activities_very_active, by="time")

daily <- daily %>% select(download_date, time, calories, sedentary, fairly_active, lightly_active, very_active)
daily <- daily %>% rename(date = time)
daily <- daily %>% mutate(week = format(date, "%y%V"),
                          day.of.week = factor(format(date, "%u| %a")),
                          vacation = as.factor(ifelse(week %in% c(1724,1725,1726,1744,1745,1752), "vacation", "no vacation")),
                          workday = as.factor(ifelse(vacation == "no vacation" & day.of.week %in% c("2| Tue", "3| Wed", "4| Thu"), "workday", "non-workday"))
                          )

rm(list = c("daily_activities_sedentary", "daily_activities_fairly_active", "daily_activities_lightly_active", "daily_activities_very_active", "daily_calories"))

# sleep sumaries
sleep_summaries <- sleep_summaries %>% select(download_date, dateOfSleep, startTime, endTime, duration, efficiency,minutesToFallAsleep, minutesAsleep, minutesAwake, minutesAfterWakeup, minInBed, infoCode,logId, type)

# sleep detailed
sleep_detailed <- sleep_detailed %>% select(download_date, sleepdate, dateTime, level, seconds)

# additional variables
today = as.character(first(intraday$download_date))

# GRAPHS ------------------------------------------------------------------
# intraday steps
ggplot(intraday) +
  geom_area(aes(as.numeric(time)/3600, steps), fill = "#8B4513", color = "black", size = 1.5) +
  labs(title = paste("Steps taken on", today), x = "Time (hrs)", y = "Steps") +
  scale_x_continuous(breaks = seq(0,24, 1)) +
  theme_bw() 
ggsave("charts/steps-intraday.png", device = "png", width = 155 * 1.5, height = 86 * 1.5, units = "mm")

# intraday calories
ggplot(intraday) +
  geom_area(aes(as.numeric(time)/3600, calories - 19), fill = "#FF4500", color = "black", size = 1.5) +
  labs(title = paste("Calories spent on", today), x = "Time (hrs)", y = "Calories") +
  scale_x_continuous(breaks = seq(0,24, 1)) +
  theme_bw() 
ggsave("charts/cal-intraday.png", device = "png", width = 155 * 1.5, height = 86 * 1.5, units = "mm")

# mutli month calories
daily %>%
  ggplot(aes(date, calories)) +
  geom_point(aes(color = day.of.week), alpha = 2/3, size = 4) +
  geom_line() + 
  geom_smooth(se = FALSE, color = "#ff8080") +
  labs(title = "Calories spent per day", x = "Time", y = "Calories") +
  facet_wrap(~ workday) +
  theme_few() + 
  theme(legend.position = "bottom")
ggsave("charts/cal-day.png", device = "png", width = 155 * 1.5, height = 86 * 1.5, units = "mm")

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
ggsave("charts/cal-perday.png", device = "png", width = 155 * 1.5, height = 86 * 1.5, units = "mm")

daily %>% 
  ggplot(aes(format(date, "%y-%m | %b"), calories)) +
  geom_violin(alpha = 1/4) +
  geom_jitter(aes(color = workday, size = vacation), alpha = 2/4) +
  labs(title = "Calories spent per day", x = "Time", y = "Calories") +
  theme_few() 
ggsave("charts/cal-day2.png", device = "png", width = 155 * 1.5, height = 86 * 1.5, units = "mm")

# multi month type active
daily %>%
  filter(!sedentary > 1000 & !lightly_active > 500) %>%
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
ggsave("charts/act-type-weekly.png", device = "png", width = 155 * 1.5, height = 86 * 1.5, units = "mm")


