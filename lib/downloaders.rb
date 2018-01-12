require_relative './response_to_file_writer'
require 'date'

class Downloader
end

class ActivityIntraDayDownloader

  def initialize(fitbit_client)
    raise ArgumentError.new('No fitbit client provided') if fitbit_client == nil
    @client = fitbit_client.client
  end

  def download_calories_today(detail_lvl = "15min")
    result = @client.activity_intraday_time_series(resource = "calories", detail_level: detail_lvl)

    data_array = result["activities-calories-intraday"]["dataset"]

    ResponseToFileWriter.write(
      data: data_array,
      to: "activities-calories-intraday.csv",
      header: "level,mets,time,value"
      )
  end

  def download_steps_today(detail_lvl = "15min")
    result = @client.activity_intraday_time_series(resource = "steps", detail_level: detail_lvl)

    data_array = result["activities-steps-intraday"]["dataset"]

    ResponseToFileWriter.write(
      data: data_array,
      to: "activities-steps-intraday.csv",
      header: "time,value"
      )
  end

  def download_calories(start_date = "2017-08-01")
    result = @client.activity_time_series(resource = "calories", start_date: start_date, end_date: Date.today)

    data_array = result

    ResponseToFileWriter.write(
      data: data_array,
      to: "activities-calories.csv",
      header: "time,value"
      )
  end

end
