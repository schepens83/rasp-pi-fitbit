require_relative './response_to_file_writer'
require 'date'
require 'HTTParty'
require 'json'

class Downloader

  START_DATE = "2017-08-01"
  def initialize(fitbit_client)
    raise ArgumentError.new('No fitbit client provided') if fitbit_client == nil
    @client = fitbit_client.client
  end
end

class ActivityIntraDayDownloader < Downloader

  def initialize(fitbit_client)
    super
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
end

class ActivityMultiDayDownloader < Downloader

  def initialize(fitbit_client)
    super
  end

  def download_calories(start_date = START_DATE)
    result = @client.activity_time_series(resource = "calories", start_date: start_date, end_date: Date.today)

    data_array = result

    ResponseToFileWriter.write(
      data: data_array,
      to: "activities-calories.csv",
      header: "time,value"
      )
  end

  def download_minutes_sedentary(start_date = START_DATE)
    download_act_type(resource = "minutesSedentary", csv_name = "activities-minutes-sedentary.csv")
  end

  def download_minutes_lightly_active(start_date = START_DATE)
    download_act_type(resource = "minutesLightlyActive", csv_name = "activities-minutes-lightly-active.csv")
  end

  def download_minutes_fairly_active(start_date = START_DATE)
    download_act_type(resource = "minutesFairlyActive", csv_name = "activities-minutes-fairly-active.csv")
  end

  def download_minutes_very_active(start_date = START_DATE)
    download_act_type(resource = "minutesVeryActive", csv_name = "activities-minutes-very-active.csv")
  end

  private

  def download_act_type(start_date = START_DATE, resource, csv_name)
    result = @client.activity_time_series(resource = resource, start_date: start_date, end_date: Date.today)

    data_array = result

    ResponseToFileWriter.write(
      data: data_array,
      to: csv_name,
      header: "time,value"
      )
  end
end

class SleepDownloader < Downloader
  attr_reader :sleep_data

  def initialize(fitbit_client)
    super
    @sleep_data = get_sleep_data(days = 1)
  end

  # for debugging purposes only
  def json_sleep_data
    File.open("tmp", 'w') do |f|
      f.puts "#{JSON.pretty_generate(sleep_data)}"
    end
  end

  def download_sleep_summary
    sleep_data["sleep"].each { |day| day.delete("levels") }
    data_array = sleep_data["sleep"]

    ResponseToFileWriter.write(
      data: data_array,
      to: "sleep-summaries.csv",
      header: "dateOfSleep,duration,efficiency,endTime,infoCode,logId,minutesAfterWakeup,minutesAsleep,minutesAwake,minutesToFallAsleep,startTime,minInBed,type"
      )
  end

  def download_sleep_time_series
    data_array = []
    sleep_data["sleep"].each do |day|
      date_of_sleep = day["dateOfSleep"]
      data_array << day["levels"]["data"].each { |e| e["sleepdate"] = date_of_sleep } # add sleepdate to each entry
    end
    data_array.flatten!

    ResponseToFileWriter.write(
      data: data_array,
      to: "sleep-time-series.csv",
      header: "dateTime,level,seconds,sleepdate"
      )
  end



  private

  def get_sleep_data(days = 100)
    @client.api_version = "1.2"

    result = @client.get("user/-/sleep/date/#{@client.format_date(Date.today - days)}/#{@client.format_date(Date.today)}.json", {})

    @client.api_version = "1"

    return result
  end
end
