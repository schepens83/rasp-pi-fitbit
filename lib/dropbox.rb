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


    def move_files_2_daily_folder(from_folder)
      to_folder = from_folder + DAILY_FOLDER

      create_folder_if_needed(to_folder)

      Dir.glob("#{from_folder}/*") do |filename|
        path = "/#{to_folder}/#{File.basename(filename)}"
        delete_file_if_there(path)

        file_content = IO.read filename
        client.upload path, file_content
      end
    end

    def move_files_2_dropbox(dir)

      client = DropboxApi::Client.new(DropboxToken.new.token)


      Dir.glob("#{dir}/*") do |filename|
        file_content = IO.read filename
        path = "/#{File.basename(filename, ".*") + "_" + Time.now.strftime("%Y-%m").to_s + File.extname(filename)}"
        begin
          client.delete path
        rescue
        end
        client.upload path, file_content
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


  end
end
