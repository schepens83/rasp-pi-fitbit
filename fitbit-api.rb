require 'fitbit_api'
require 'csv'
require 'json'


# read refresh token
refresh_tkn = ""
File.open('secret/refresh_token', 'r') do |f1|
  refresh_tkn = f1.gets.sub(/\n$/, "")
end

# make a client
client = FitbitAPI::Client.new(client_id: '22CHR2',
                               client_secret: '141de0f8d38c79deed5493191c42d633',
                               refresh_token: refresh_tkn, unit_system: 'any')


# p client.daily_activity_summary()

# result = JSON.pretty_generate(
#   client.daily_activity_summary(date = Date.today - 1, resource: "calories", detail_level: "1min")
#   )

result = client.activity_intraday_time_series(resource = "calories", detail_level: "1min")

# , start_time: "00:00:00", end_time: "00:50:00"

# result = client.activity_time_series(resource = "calories", start_date: Date.today - 10)




# temp: write result away
File.open('result', 'w') do |f2|
  # use "\n" for two lines of text
  f2.puts JSON.pretty_generate(result)
end



p csv_string = CSV.generate do |csv|
  JSON.parse(File.open("foo.json").read).each do |hash|
    csv << hash.values
  end
end



# write refresh token away
File.open('secret/refresh_token', 'w') do |f2|
  # use "\n" for two lines of text
  f2.puts client.refresh_token.refresh_token
end
