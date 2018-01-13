# Introduction
This is a personal project to get my raspberry pi to display charts from my fitbit tracker

# To install on the rasp pi
- Install R
`sudo apt-get update && sudo apt-get install r-base`
- Install ruby 2.3
`sudo apt install ruby2.3`
- Make sure this is also the version that is used.
- download this repo
`git clone https://github.com/schepens83/rasp-pi-fitbit.git`
- install bundle and install gems. While in the directory type:
`gem install bundle && bundle install`


# Things to register (to do)
## Get Activity Intraday Time Series
- activities/calories [done]
- activities/steps [done]
- activities/floors

## Activity Time Series
- activities/calories [done]
- activities/steps
- activities/minutesSedentary [done]
- activities/minutesLightlyActive [done]
- activities/minutesFairlyActive [done]
- activities/minutesVeryActive [done]
- activities/activityCalories

## Get Activity goals
save each time as new csv in order to keep record of goals

## Get Sleep Logs List
- detailed sleep logs [done]
- summary sleep logs [done]

## Get Heart Rate Time Series
maybe useful?

## Get Activity Logs List
for running
