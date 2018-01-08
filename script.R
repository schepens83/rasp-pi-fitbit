require(tidyverse) || install.packages("tidyverse") 
require(devtools) || install.packages("devtools")
require(fitbitr) || devtools::install_github("teramonagi/fitbitr")


# set some global variables
cred <- read.csv("credentials/cred.txt")
trim.leading <- function (x)  sub("^\\s+", "", x)
FITBIT_KEY    <- cred %>% filter(var == "key") %>% select("val")
FITBIT_KEY <- trim.leading(sprintf(as.character(FITBIT_KEY[,1])))
FITBIT_SECRET <- cred %>% filter(var == "secret") %>% select("val")
FITBIT_SECRET <- trim.leading(sprintf(as.character(FITBIT_SECRET[,1])))
rm(cred)
FITBIT_CALLBACK <- "http://localhost:1410" 

token <- fitbitr::oauth_token()
