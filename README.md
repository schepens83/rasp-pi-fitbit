# Readme
## Introduction
This is a personal project to get my raspberry pi to display charts from my fitbit tracker

## To install on the rasp pi
- Install R
`sudo apt-get update && sudo apt-get install r-base`
- Install ruby 2.3
`sudo apt install ruby2.3`
- Make sure this is also the version that is used.
- download this repo
`git clone https://github.com/schepens83/rasp-pi-fitbit.git`
- install bundle and install gems. While in the directory type:
`gem install bundle && bundle install`
- create the charts, csv and secret folders
`mkdir charts csv secret`

### To get the refresh_token
[see also this url for more information:](https://github.com/zokioki/fitbit_api#oauth-20-authorization-flow)
open `irb` in the terminal, then:
- `require_relative "lib/client"`
- `client = FitbitAPI::Client.new(client_id: 'XXXXXX', client_secret: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', redirect_uri: 'http://localhost:1410')`
- where the redirect_uri is the callback url you have defined in the dev dashboard.
- `client.auth_url`
- go to the url.
- copy the code that is provided (between = and #. It should be 40 chars long)
- `client.get_token("code")` (where code is the code copied above. make sure to put it between "" as it should be a string.)
- `client.refresh_token` gives you a string that is your refresh token. Put it in the secret/refresh_token file.

For a collapse of the above steps into 2:
- `require_relative "lib/client"; client = FitbitAPI::Client.new(client_id: 'XXXXXX', client_secret: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', redirect_uri: 'http://localhost:1410'); client.auth_url`
- `client.get_token("code").refresh_token`

## To do
### Things to chart
- activity and sleep together and chart.Correlation
- add  workday friday as of 2018
- steps over longer period (similar to calories, violin charts)

### Things to register
#### Get Activity Intraday Time Series
- activities/floors

#### Activity Time Series
- activities/steps & calories multidays
- activities/activityCalories

#### Get Activity goals
save each time as new csv in order to keep record of goals

#### Get Sleep Logs List
- add times awake (mini moments)

#### Get Heart Rate Time Series
maybe useful?

#### Get Activity Logs List
for running

