module Z4Auth
  class Totp
    def initialize sec
      @totp = ROTP::TOTP.new(sec, issuer: "Z4")
    end
    def now *k
      if k[0]
        @totp.verify(k[0])
      else
        @totp.now
      end
    end
  end
  def self.[] k
    Totp.new k
  end
end
module Z4Sec
  class Cipher
    def initialize a
      @auth = a
      @cipher = OpenSSL::Cipher::AES.new(256, :GCM)
    end
    def encode **h
      @cipher.encrypt
      if h.has_key? :key
        @cipher.key = h[:key]
        key = h[:key]
      else
        key = @cipher.random_key
      end

      if h.has_key? :iv
        @cipher.iv = h[:iv]
        iv = h[:iv]
      else
        iv = @cipher.random_iv
      end
      
      @cipher.auth_data = @auth
      
      encrypted = @cipher.update(h[:data]) + @cipher.final
      tag = @cipher.auth_tag # produces 16 bytes tag by default
      return { key: key, iv: iv, tag: tag, data: encrypted }
    end
    def decode **h
      raise "tag is truncated!" unless h[:tag].bytesize == 16
      @cipher.decrypt
      @cipher.key = h[:key]
      @cipher.iv = h[:iv]
      @cipher.auth_tag = h[:tag]
      @cipher.auth_data = @auth
      @cipher.update(h[:data]) + @cipher.final
    end
  end
  def self.[] k
    Cipher.new k
  end
end
