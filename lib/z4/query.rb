module QUERY

  class Query
    def initialize i
      @id = i
      @x = OBJ[:pool][i]
      @i = Hash.new { |h,k| Q.new(k) }
      @x.data.each { |e| @i[e] }
    end
    def length
      @x.data.length
    end
    def [] k
      kk = %[#{@id}-#{k}]
      @x.data.add kk
      @i[kk]
    end
    def keys
      a = []
      each { |e| a << e }
      return a
    end
    def each &b
      @x.data.each { |e| b.call(@i[e]) }
    end
    def id; @id; end
  end
  
  class Q
    def initialize i
      @id = i
      @x = OBJ[:item][i]
    end
    def << i
      @x.data << i
    end
    def keys
      a = []
      each { |e| a << e }
      return a
    end    
    def each &b
      @x.data.each { |e| b.call(e) }
    end
    def id; @id; end
  end
  
  @@QUERY = Query.new(:pool)
  def self.[] k
    @@QUERY[k]
  end
  def self.keys
    @@QUERY.keys
  end
end

