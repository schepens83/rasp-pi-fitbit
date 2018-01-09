class Downloader
  def write_csv(filename = "csv/activities-calories-intraday.csv", data_array)
    # header
    File.open(filename, 'w') do |f2|
      f2.puts "level,mets,time,value"
    end

    # lines
    CSV.open(filename, "a") do |csv|
      data_array.each do |hash|
        csv << hash.values
      end
    end
  end
end
