Dir[File.join(".", "lib/*.rb")].each { |f| require f }

fitbit = Fitbit.new


aid = ActivityIntraDayDownloader.new(fitbit, detail: "15min", days_back: 7)
aid.download_calories()
aid.download_steps()
aid.download_distance()


amd = ActivityMultiDayDownloader.new(fitbit)
amd.download_calories()
amd.download_steps()
amd.download_minutes_sedentary()
amd.download_minutes_fairly_active()
amd.download_minutes_lightly_active()
amd.download_minutes_very_active()

sd = SleepDownloader.new(fitbit)
sd.download_sleep_time_series
sd.download_sleep_summary


fitbit.clean_up
