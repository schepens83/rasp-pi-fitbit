require(tidyverse) || install.packages("tidyverse") 
require(devtools) || install.packages("devtools")
require(fitbitr) || devtools::install_github("teramonagi/fitbitr")

# DATA IMPORT -------------------------------------------------------------
intraday_steps <- readr::read_csv("csv/activities-steps-intraday.csv")
intraday_calories <- readr::read_csv("csv/activities-calories-intraday.csv")


# GRAPHS ------------------------------------------------------------------
ggplot(intraday_steps) +
  geom_line(aes(time, value))

ggplot(intraday_calories) +
  geom_line(aes(time, value))
