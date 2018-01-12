require_relative './response_to_file_writer'

class Downloader
end

class ActivityIntraDayDownloader

  def initialize(fitbit_client)
    raise ArgumentError.new('No fitbit client provided') if fitbit_client == nil
    @client = fitbit_client.client
  end

  def download_calories
    result = @client.activity_intraday_time_series(resource = "calories", detail_level: "15min")

    data_array = result["activities-calories-intraday"]["dataset"]

    ResponseToFileWriter.write(
      data: data_array,
      to: "activities-calories-intraday.csv",
      header: "level,mets,time,value"
      )
  end

  def download_steps
    result = @client.activity_intraday_time_series(resource = "steps", detail_level: "15min")

    data_array = result["activities-steps-intraday"]["dataset"]

    ResponseToFileWriter.write(
      data: data_array,
      to: "activities-steps-intraday.csv",
      header: "time,value"
      )
  end

end
