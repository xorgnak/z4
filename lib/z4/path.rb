module Z4
  ###
  ### URL SHORTENING
  ###
  
  class PATH
    include Redis::Objects

    hash_key :a
    hash_key :b

    def initialize
      @id = :path
    end

    def random
      a = []
      10.times { if rand(2) == 0; a << rand(16).to_s(16).upcase; else a << rand(16).to_s(16); end }
      return a.join("")
    end

    def make k, p
      self.a[k] = p
      self.b[p] = k
    end

  
    def make! p
      if !path? p
        k = random
        while key?(k) do
          k = random
        end
        make k, p
      end
      return path p
    end

    def path? k
      if self.b[k] != nil
        return true
      else
        return false
      end
    end

    def path k
      self.b[k]
    end


    def key? k
      if self.a[k] != nil
        return true
      else
        return false
      end
    end

    def key k
      self.a[k]
    end

    def id; @id; end
  end
  
  @@PATH = PATH.new
  
  def self.path
    @@PATH
  end
  end
