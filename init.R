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
