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

def move_files_2_dropbox(dir)
  # create dropbox client
  client = DropboxApi::Client.new(DropboxToken.new.token)

  # create the folder
  folder = dir + "-" + Time.now.to_s.gsub(" ", "~")
  client.create_folder("/#{folder}")

  # move the files
  Dir.glob("#{dir}/*") do |filename|
   file_content = IO.read filename
   client.upload "/#{folder}/#{File.basename(filename)}", file_content
  end
end

move_files_2_dropbox("charts")
move_files_2_dropbox("csv")




# Dir.glob("charts/*") do |filename|
#   p filename
#   file_content = IO.read filename
#   # mtime = file_content.mtime
#   new_filename = "#{File.basename(filename)}"

#   puts "moving #{filename} to #{new_filename} ..."

#   client.upload new_filename, file_content
# end






# p result = client.search("tst")
# result = client.list_folder("/Picturescraps")
#=> #<DropboxApi::Results::ListFolderResult>
# p result.entries
#=> [#<DropboxApi::Metadata::Folder>, #<DropboxApi::Metadata::File>]
# p result.has_more?
#=> false




