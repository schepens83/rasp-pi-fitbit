require 'dropbox_api'

# read and write refresh token to a file
class DropboxToken
  def initialize()
    @path = 'secret/token_dropbox'
    # read refresh token
    @tkn = ""
    File.open(@path, 'r') do |f1|
      @tkn = f1.gets.sub(/\n$/, "")
    end
  end

  def token
    @tkn
  end
end

def move_files_2_dropbox_in_daily_folder(dir)
  # create dropbox client
  client = DropboxApi::Client.new(DropboxToken.new.token)

  # create the folder if needed
  folder = dir + "-daily"
  unless File.directory?(folder)
    client.create_folder("/#{folder}")
  end

  # move the files
  Dir.glob("#{dir}/*") do |filename|
   file_content = IO.read filename
   client.upload "/#{folder}/#{File.basename(filename)}", file_content, mode: :overwrite
  end
end

def move_files_2_dropbox(dir)
  # create dropbox client
  client = DropboxApi::Client.new(DropboxToken.new.token)

  # move the files
  Dir.glob("#{dir}/*") do |filename|
   file_content = IO.read filename
   client.upload "/#{File.basename(filename, ".*") + "_" + Time.now.strftime("%Y-%m").to_s + File.extname(filename)}", file_content, mode: :overwrite
  end
end

if Time.now.day == 28
  move_files_2_dropbox("charts")
  move_files_2_dropbox("csv")
end

move_files_2_dropbox_in_daily_folder("charts")
