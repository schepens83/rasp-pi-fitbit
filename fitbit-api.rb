Dir[File.join(".", "lib/*.rb")].each do |f|
  require f
end

fitbit = Fitbit.new


aid = ActivityIntraDayDownloader.new(fitbit)
aid.download_calories("15min")
aid.download_steps("15min")


fitbit.clean_up





# p client.daily_activity_summary()

# result = JSON.pretty_generate(
#   client.daily_activity_summary(date = Date.today - 1, resource: "calories", detail_level: "1min")
#   )


# , start_time: "00:00:00", end_time: "00:50:00"

# result = client.activity_time_series(resource = "calories", start_date: Date.today - 10)



# temp: write result away for eye-ball inspecting
# File.open('result', 'w') do |f2|
#   # use "\n" for two lines of text
#   f2.puts JSON.pretty_generate(result)
# end






