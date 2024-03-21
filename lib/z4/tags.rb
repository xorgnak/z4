module BAG
  @@BAG = Hash.new { |h,k| h[k] = Bag.new(k) }
  class Bag
    def initialize i
      @id = i
      @x = OBJ[:bag][i]
      @i = Hash.new { |h,k| h[k]= B.new(k) }
      @x.data.each { |e| @i[e] }
    end
    def id; @id; end                                                                                                                                                                                                    
    def [] k
      @x.data << k
      @i[k]
    end
    def []= k,v
      @x.data << k
      @i[k] = v
    end
    def data
      @x.data
    end
    def each &b
      @x.data.each { |e| b.call(@i[e]) }
    end
  end
  def self.[] k
    @@BAG[k]
  end
  def self.keys
    @@BAG.keys
  end
  
  class B
    def initialize k
      @id = k
      @x = OBJ[:b][k]
    end
    def id; @id; end
    def [] k
      @x.attr[k]
    end
    def []= k,v
      @x.attr[k] = v
    end
    def incr k
      @x.tags.incr(k)
    end
    def decr k
      @x.tags.decr(k)
    end
    def to_h
      h, t = {}, Time.now.utc.to_i
      @x.attr.keys.each  do |e|
        h[e] = @x.attr[e]
      end
      return h
    end
  end
end


module TAG
  @@TAG = Hash.new { |h,k| h[k] = T.new(k) }  

  class O
    attr_reader :obj
    def initialize k
      @k = self.class.to_s.downcase.to_sym
      @id = k
      @obj = OBJ[@k][k]
      puts %[#{@k}>#{k}]
    end
    def klass; @k; end
    def id; @id; end
    def to_h
      h = { class: @k, name: name, data: [], attr: @obj.attr.to_h, stat: @obj.stat.to_h, tags: @obj.tags.to_h, meta: @obj.meta.to_h }
      @obj.data.each { |e| h[:data] << e }
      return h
    end
  end

  class Tag < O
    def name
      %[Tag.]
    end
  end
  @@T = Hash.new { |h,k| h[k] = Tag.new(k) }
  def self.tags
    @@T
  end
  
  class Win < O
    def name
      %[Game tag.]
    end
  end
  @@W = Hash.new { |h,k| h[k] = Win.new(k) }
  def self.wins
    @@W
  end
  
  class Award < O
    def name
      %[Title game tag.]
    end
  end
  @@A = Hash.new { |h,k| h[k] = Award.new(k) }
  def self.awards
    @@A
  end
  
  class T
    def initialize k
      @id = k
      @t = Hash.new { |h,k| h[k] = TAG.tags[k] }
      @w = Hash.new { |h,k| h[k] = TAG.wins[k] }
      @a = Hash.new { |h,k| h[k] = TAG.awards[k] }
      @x = OBJ[:t][k]
      @id = k
      @x.data.each { |e| @t[e]; @w[e]; @a[e] }
    end
    def id; @id; end
    def [] k
      tag(k)
    end
    def keys
      a = []
      @x.data.each { |e| a << e }
      return a
    end
    def mark h={}
      BAG[h[:user]][@id] = Time.now.utc.to_i
      tag(h[:tag]).obj.tags.incr(@id)
    end
    def win h={}
      mark h
      @w[h[:tag]].obj.tags.incr(@id)
    end
    def award h={}
      win h
      @a[h[:tag]].obj.tags.incr(@id)
    end    
    def tag x
      @x.data << x
      @t[x]
    end
    def to_h
      h = {}
      @x.data.each { |e| h[e] = { mark: @t[e].to_h, win: @w[e].to_h, award: @a[e].to_h } }
      return h
    end
  end

  def self.keys
    @@TAG.keys
  end
  
  def self.[] k
    @@TAG[k]
  end  
end

