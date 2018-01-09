require 'fitbit_api'
require 'json'

# read and write refresh token to a file
class RefreshToken
  def initialize()

    @path = 'secret/refresh_token'
    # read refresh token
    @refresh_tkn = ""
    File.open(@path, 'r') do |f1|
      @refresh_tkn = f1.gets.sub(/\n$/, "")
    end
  end

  def string
    @refresh_tkn
  end

  # write refresh token away
  def refresh!(client)
    File.open(@path, 'w') do |f2|
      f2.puts client.refresh_token.refresh_token
    end
  end
end

# load api id and secret from json
class Credentials
  def initialize(path = 'secret/cred.json')
    @data_hash = JSON.parse(File.read(path))
  end

  def id
    id = @data_hash["key"]
  end

  def secret
    secret = @data_hash["secret"]
  end
end


class Fitbit
  attr_accessor :client

  def initialize
    @refresh_token = RefreshToken.new

    # make a client
    credentials = Credentials.new
    @client = FitbitAPI::Client.new(client_id: credentials.id, client_secret: credentials.secret, refresh_token: @refresh_token.string, unit_system: 'any')
  end

  def clean_up
    @refresh_token.refresh!(client)
  end

  private
end
