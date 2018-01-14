Dir[File.join(".", "lib/*.rb")].each do |f|
  require f
end

fitbit = Fitbit.new


aid = ActivityIntraDayDownloader.new(fitbit)
aid.download_calories_today("15min")
aid.download_steps_today("15min")
aid.download_distance_today("15min")

amd = ActivityMultiDayDownloader.new(fitbit)
amd.download_calories()
amd.download_minutes_sedentary()
amd.download_minutes_fairly_active()
amd.download_minutes_lightly_active()
amd.download_minutes_very_active()

sd = SleepDownloader.new(fitbit)
sd.download_sleep_time_series
sd.download_sleep_summary


fitbit.clean_up
