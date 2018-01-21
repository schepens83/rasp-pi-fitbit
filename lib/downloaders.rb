require_relative './response_to_file_writer'
require 'date'
require 'HTTParty'
require 'json'

class Downloader

  START_DATE = "2017-08-01"
  END_DATE = Date.today
  def initialize(fitbit_client, args = {})
    raise ArgumentError.new('No fitbit client provided') if fitbit_client == nil
    @client = fitbit_client.client
  end
end

class ActivityIntraDayDownloader < Downloader
  attr_reader :detail_lvl, :days_back

  def initialize(fitbit_client, args = {})
    super
    @detail_lvl = args[:detail] || "15min"
    @days_back = args[:days_back] || 0 # nr of days in addition to today.
  end

  def download_calories()
    data_array = get_data(type = "calories")

    ResponseToFileWriter.write(
      data: data_array,
      to: "activities-calories-intraday.csv",
      header: "level,mets,time,value,date"
      )
  end

  def download_distance()
    data_array = get_data(type = "distance")

    ResponseToFileWriter.write(
      data: data_array,
      to: "activities-distance-intraday.csv",
      header: "time,value,date"
      )
  end

  def download_steps()
    data_array = get_data(type = "steps")

    ResponseToFileWriter.write(
      data: data_array,
      to: "activities-steps-intraday.csv",
      header: "time,value,date"
      )
  end

  private

  def get_data(type)
    all = []
    days_array = (Date.today - days_back..Date.today).map(&:to_s)

    days_array.each do |date|
      result = @client.activity_intraday_time_series(resource = type.to_s, detail_level: detail_lvl, date: date)

      all = all + result["activities-#{type.to_s}-intraday"]["dataset"].each { |e| e["date"] = date } # add date to each entry
    end

    return all
  end
end

class ActivityMultiDayDownloader < Downloader

  def initialize(fitbit_client)
    super
  end

  def download_steps(start_date = START_DATE)
    result = @client.activity_time_series(resource = "steps", start_date: start_date, end_date: END_DATE)

    data_array = result

    ResponseToFileWriter.write(
      data: data_array,
      to: "activities-steps.csv",
      header: "time,value"
      )
  end

  def download_calories(start_date = START_DATE)
    result = @client.activity_time_series(resource = "calories", start_date: start_date, end_date: END_DATE)

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
    result = @client.activity_time_series(resource = resource, start_date: start_date, end_date: END_DATE)

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
    days_to_download = (Date.today - Date.parse(START_DATE)).to_i
    @sleep_data = get_sleep_data(days = days_to_download)
  end

  # for debugging purposes only
  def json_sleep_data
    File.open("tmp", 'w') do |f|
      f.puts "#{JSON.pretty_generate(sleep_data)}"
    end
  end

  def download_sleep_summary
    sleep_data.each { |day| day.delete("levels") }
    data_array = sleep_data

    ResponseToFileWriter.write(
      data: data_array,
      to: "sleep-summaries.csv",
      header: "dateOfSleep,duration,efficiency,endTime,infoCode,logId,minutesAfterWakeup,minutesAsleep,minutesAwake,minutesToFallAsleep,startTime,minInBed,type"
      )
  end

  def download_sleep_time_series
    data_array = []
    sleep_data.each do |day|
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

    all = []
    (0..days).each_slice(100) do |n|
      from = n.last
      to = n.first

      result = @client.get("user/-/sleep/date/#{@client.format_date(Date.today - from)}/#{@client.format_date(Date.today - to)}.json", {})
      all = all + result["sleep"]

    end
    @client.api_version = "1"

    return all
  end
end
