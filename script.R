require(tidyverse) || install.packages("tidyverse") 
require(devtools) || install.packages("devtools")
require(fitbitr) || devtools::install_github("teramonagi/fitbitr")
require(ggthemes) || install.packages("ggthemes")

# DATA IMPORT -------------------------------------------------------------
intraday_steps <- readr::read_csv("csv/activities-steps-intraday.csv")
intraday_calories <- readr::read_csv("csv/activities-calories-intraday.csv")


# DATA WRANGLING ----------------------------------------------------------
today = as.character(first(intraday_steps$download_date))


# GRAPHS ------------------------------------------------------------------
ggplot(intraday_steps) +
  geom_area(aes(time, value)) +
  labs(title = paste("Steps taken on", today), x = "Time", y = "Steps") +
  theme_economist()

ggplot(intraday_calories) +
  geom_area(aes(time, value)) +
  labs(title = paste("Calories spent on", today), x = "Time", y = "Calories") +
  theme_economist()
