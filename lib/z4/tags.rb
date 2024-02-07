module QUERY
  
  class Pool
    include Redis::Objects
    
    sorted_set :terms
    
    def initialize k
      @id = k
    end
    def length
      self.terms.members.length
    end
    def [] k
      self.terms.incr k
      Item.new(%[#{@id}-#{k}])
    end
    def each &b
      h = self.terms.members(with_scores: true).to_h.sort_by { |k,v| -v }
      h.to_h.each_pair { |k,v| b.call(k,v,Item.new(%[#{@id}-#{k}])) }
    end
    def id; @id; end
  end

  class Item
    include Redis::Objects
    sorted_set :items
    def initialize k
      @id = k
    end
    def length
      self.items.members.length
    end
    def each &b
      h = self.items.members(with_scores: true).to_h.sort_by { |k,v| -v }
      h.to_h.each_pair { |k,v| b.call(k,v) }
    end
    def id; @id; end
  end
  
  @@QUERY = Pool.new(:pool)
  def self.[] k
    @@QUERY[k]
  end
  def self.keys
    @@QUERY.terms.members.to_a
  end
  def self.boards
    a = []
    QUERY.keys.each { |e| if TAG[e].to_h.keys.length > 0; a << e; end }
    return a
  end
end


module BAG
  @@BAG = Hash.new { |h,k| h[k] = Bag.new(k) }
  class Bag
    include Redis::Objects
    set :bag
    def initialize k
      @id = k
    end
    def id; @id; end                                                                                                                                                                                                    
    def [] k
      self.bag << k
      return B.new(k)
    end
    def keys
      self.bag.members.to_a
    end
    def each &b
      keys.each { |e| b.call(B.new(e)) }
    end
  end
  def self.[] k
    @@BAG[k]
  end
  def self.keys
    @@BAGS.keys
  end
  
  class B
    include Redis::Objects
    
    value :now, :expireat => lambda { Time.now.utc.to_i + (60 * 60) }
    value :shift, :expireat => lambda { Time.now.utc.to_i + (60 * 60) }
    value :night, :expireat => lambda { Time.now.utc.to_i + ((60 * 60) * 12) }
    value :day, :expireat => lambda { Time.now.utc.to_i + ((60 * 60) * 24) }
    value :week, :expireat => lambda { Time.now.utc.to_i + (((60 * 60) * 24) * 7) }
    value :month, :expireat => lambda { Time.now.utc.to_i + (((60 * 60) * 24) * 30) }
    value :quarter, :expireat => lambda { Time.now.utc.to_i + (((60 * 60) * 24) * 90) }
    value :halfyear, :expireat => lambda { Time.now.utc.to_i + (((60 * 60) * 24) * 180) }
    value :year, :expireat => lambda { Time.now.utc.to_i + (((60 * 60) * 24) * 365) }
    
    def initialize k
      @id = k
      @n = 0
    end
    def id; @id; end
    def tokens
      { now: self.now, shift: self.shift, night: self.night, day: self.day, week: self.week, month: self.month, quarter: self.quarter, halfyear: self.halfyear, year: self.year }
    end
    def valid!
      t = Time.now.utc.to_i
      tokens.each_pair  do |k,v|
        if v.value == nil
          v.value = t
        end
      end
      return t
    end
    def to_h
      h, t = {}, Time.now.utc.to_i
      @n = 0
      tokens.each_pair  do |k,v|
        if v.value != nil 
          h[k] = v.to_i
        else
          @n += 1
          h[k] = false
        end
      end
      return h
    end
    def depth
      @n
    end
    def valid?
      h = to_h
      if @n < 9
        return h
      else
        return false
      end
    end
  end
end

module TAG
  
  @@TAG = Hash.new { |h,k| h[k] = Tag.new(k) }
  
  class T
    include Redis::Objects
    
    sorted_set :tags
    sorted_set :won
    sorted_set :awards
    
    def initialize k
      @id = %[#{k}]
    end
    def id; @id; end
    def to_h
      h = {}
      self.tags.members.to_a.each { |e| h[e] = { alternate_email: self.tags[e].to_i, star: self.won[e].to_i, workspace_premium: self.awards[e].to_i } }
      return h
    end
  end
  
  class Tag
    include Redis::Objects
    sorted_set :tags
    sorted_set :won
    sorted_set :awards
    def initialize k
      @t = Hash.new { |h,k| h[k] = T.new(k) }
      @id = %[#{k}]
    end
    def id; @id; end
    def [] k
      @t[k]
    end
    def validation x
      BAG[x][@id].valid?
    end
    def keys
      @t.keys
    end
    def tag y, x, *a
      BAG[x][@id].valid!
      u = OBJ[y][x]
      u.tags << @id
      self.tags.incr(x);
      object(x).tags.incr(@id)
      u.stat.incr(:xp)
      if a[0]
        self.won.incr(x);
        object(x).won.incr(@id)
        u.stat.incr(:xp)
        if a[1]
          self.awards.incr(x);
          object(x).awards.incr(@id)
          u.stat.incr(:xp)
          u.tag[@id] = a.join(" ")
        else
          u.tag[@id] = a[0]
        end
      end
    end
    def object x
      @t[x]
    end
    def to_h
      h = {}
      self.tags.members.to_a.each { |e| h[e] = { alternate_email: self.tags[e].to_i, star: self.won[e].to_i, workspace_premium: self.awards[e].to_i }  }
      return h
    end
  end

  @@TAGS = Hash.new { |h,k| h[k] = [] }
  
  def self.safe *t
    if t[0]
      if t[1]
        @@TAGS[t[0]] << t[1]
      else
        return @@TAGS[t[0]]
      end
    else
      return @@TAGS.keys
    end
  end

  @@AWARDS = Hash.new { |h,k| h[k] = [] }

  def self.award *t
    if t[0]
      if t[1]
        @@AWARDS[t[0]] << t[1]
      else
        return @@AWARDS[t[0]]
      end
    else
      return @@AWARDS.keys
    end
  end
  
  def self.[] k
    if @@TAGS.include? k
      @@TAG[k]
    end
  end  
end


# TAG.safe "beer"
# TAG["beer"].tag :obj, 'testobj', 'award'
# TAG["beer"].tag :obj, 'testobj', 'award', 'result'
# TAG["beer"].to_h
# TAG["beer"]['testobj']
# BAG['testobj'].each { |e| e.depth == level }
# BAG['testobj'].each {}

# OBJ[:user]['testuser'].bag => BAG['testuser']
