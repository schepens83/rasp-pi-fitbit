require 'csv'

class ResponseToFileWriter
  FILEPATH = "csv/"

  def self.write(args)
    data = args[:data]
    to = args[:to]
    header = args[:header]
    raise ArgumentError.new('No header argument provided') if header == nil
    raise ArgumentError.new('No to argument provided') if to == nil
    raise ArgumentError.new('No data argument provided') if data == nil

    path = FILEPATH + to
    # header
    File.open(path, 'w') do |f|
      f.puts header
    end

    # lines
    CSV.open(path, "a") do |csv|
      data.each do |hash|
        csv << hash.values
      end
    end
  end
end
