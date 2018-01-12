require(tidyverse) || install.packages("tidyverse") 
require(devtools) || install.packages("devtools")
require(fitbitr) || devtools::install_github("teramonagi/fitbitr")
require(ggthemes) || install.packages("ggthemes")

# DATA IMPORT -------------------------------------------------------------
intraday_steps <- readr::read_csv("csv/activities-steps-intraday.csv")
intraday_calories <- readr::read_csv("csv/activities-calories-intraday.csv")
daily_calories <- readr::read_csv("csv/activities-calories.csv")

# DATA WRANGLING ----------------------------------------------------------
today = as.character(first(intraday_steps$download_date))
daily_calories <- daily_calories %>% mutate(week = format(time, "%y%V"),
                                            day.of.week = factor(format(time, "%u| %a")),
                                            vacation = ifelse(week %in% c(1724,1725,1726,1744,1745,1752), "vacation", "no vacation"),
                                            workday = ifelse(vacation == "no vacation" & day.of.week %in% c("2| Tue", "3| Wed", "4| Thu"), "workday", "non-workday")
                                            )

# GRAPHS ------------------------------------------------------------------
# intraday steps
ggplot(intraday_steps) +
  geom_line(aes(time, value), color = "#8B4513") +
  labs(title = paste("Steps taken on", today), x = "Time", y = "Steps") +
  theme_few() +
  ggsave("charts/steps-intraday.png", device = "png", width = 155 * 1.5, height = 86 * 1.5, units = "mm")

# intraday calories
ggplot(intraday_calories) +
  geom_line(aes(time, value), color = "#FF4500") +
  labs(title = paste("Calories spent on", today), x = "Time", y = "Calories") +
  theme_few() +
  ggsave("charts/cal-intraday.png", device = "png", width = 155 * 1.5, height = 86 * 1.5, units = "mm")

# mutli month calories
daily_calories %>%
  ggplot(aes(time, value)) +
  geom_point(aes(size = day.of.week, color = day.of.week), alpha = 2/3) +
  geom_line() + 
  geom_smooth(se = FALSE, color = "#ff8080") +
  labs(title = "Calories spent per day", x = "Time", y = "Calories") +
  facet_wrap(~ workday) +
  theme_few()
ggsave("charts/cal-day.png", device = "png", width = 155 * 1.5, height = 86 * 1.5, units = "mm")

daily_calories %>% 
  ggplot(aes(format(time, "%y-%m | %b"),value)) +
  geom_violin(alpha = 1/4) +
  geom_jitter(aes(color = workday, size = vacation),alpha = 3/4) +
  labs(title = "Calories spent per day", x = "Time", y = "Calories") +
  theme_few()
ggsave("charts/cal-day2.png", device = "png", width = 155 * 1.5, height = 86 * 1.5, units = "mm")

# multi month steps
