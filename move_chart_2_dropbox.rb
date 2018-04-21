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


client = DropboxApi::Client.new(DropboxToken.new.token)

result = client.list_folder "/Picturescraps"
#=> #<DropboxApi::Results::ListFolderResult>
p result.entries
#=> [#<DropboxApi::Metadata::Folder>, #<DropboxApi::Metadata::File>]
p result.has_more?
#=> false




