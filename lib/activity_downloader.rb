class ActivityDownloader

  def initialize(path)

  end

  def activity_intraday_time_series
    result = client.activity_intraday_time_series(resource = "calories", detail_level: "1min")

    data_array = result["activities-calories-intraday"]["dataset"]

  end
end
