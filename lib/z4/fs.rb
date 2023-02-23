module Z4Fs

  def self.actor
    Actor.new(DropboxApi::Authenticator.new(ENV['DROPBOX_CLIENT_ID'], ENV['DROPBOX_CLIENT_SECRET']))
  end
  
  class Actor
    def initialize auth
      @auth = auth
      @client = false
    end
    def auth
      @auth.auth_code.authorize_url
    end
    def init code
      @client = DropboxApi::Client.new(access_token: @auth.auth_code.get_token(code))
    end
    def client
      @client
    end
    def do &b
      b.call(@client)
    end
    def mkdir h
      @client.create_folder h
    end
    def read f
      Net::HTTP.get(URI(@client.get_temporary_link(f).link))
    end
    def write f, b, opts={}
      @client.upload(f, b, opts)
    end
    def delete f
      @client.delete(f)
    end
  end
end

