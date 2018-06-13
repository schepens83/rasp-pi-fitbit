module Dropbox
  require 'dropbox_api'

  class DropboxToken
    def initialize()
      @path = 'secret/token_dropbox'

      @tkn = ""
      File.open(@path, 'r') do |f1|
        @tkn = f1.gets.sub(/\n$/, "")
      end
    end

    def token
      @tkn
    end
  end


  class FileMover
    attr_reader :client

    DAILY_FOLDER = "-daily"

    def initialize()
      @client = DropboxApi::Client.new(DropboxToken.new.token)
    end

    # move to the same folder with the same path every time
    def move_files_to_daily(from_folder)
      to_folder = from_folder + DAILY_FOLDER

      create_folder_if_needed(to_folder)

      Dir.glob("#{from_folder}/*") do |filename|
        to_path = "/#{to_folder}/#{File.basename(filename)}"
        delete_file_if_there(to_path)
        move_file(filename, to_path)
      end
    end

    # move to a timestamped file with the same path
    def move_files_to(from_folder)

      Dir.glob("#{from_folder}/*") do |filename|
        to_path = "#{timestamped(filename)}"
        delete_file_if_there(to_path)
        move_file(filename, to_path)
      end
    end

    private

    def create_folder_if_needed(folder)
      result = client.search folder
      if result.matches.empty?
        client.create_folder("/#{folder}")
      end
    end

    def delete_file_if_there(path)
      begin
        client.delete path
      rescue
      end
    end

    def move_file(filename, to_path)
      file_content = IO.read filename
      client.upload to_path, file_content
    end

    def timestamped(filename)
      "/#{File.basename(filename, ".*") + "_" + Time.now.strftime("%Y-%m").to_s + File.extname(filename)}"
    end
  end
end
