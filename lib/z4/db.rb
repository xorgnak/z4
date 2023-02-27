
module Z4Db
  class Error < StandardError; end
  @@DB = {}
  # create table
  def self.table t, h={}
    hh = {
      credits: 0,
      exchange: 1,
      img: '/bg.img',
      body: 'Welcome to the future!',
      button: 'wb_twilight',
      contact: 'set contact in channel.',
      link: 'set link in channel.'
    }
    @@DB[t] = Db.new(t, hh.merge(h))
    puts "[Z4][DB] #{t} created."
  end
  # read table
  def self.[] k
    @@DB[k]
  end
  # update table
  def self.update k, h
    hh = @@DB[k].skel.merge(h)
    @@DB[k].skel = hh
  end
  # destroy table
  def self.destroy k
    @@DB.delete k
  end
  # list tables
  def self.tables
    @@DB.keys
  end
  
  class Db
    def initialize db, skel={}
      @skel = skel
      @table = db
      @db = DBM.new("db/#{db}.db", 0666, DBM::WRCREAT)
    end
    # update entry
    def update k, h={}
      if @db.has_key? k
        g = read(k)
        h.each_pair {|k,v| g[k.to_s] = v }
        @db[k] = JSON.generate(g)
      else
        return false
      end
    end

    def credit k, *a
      if @db.has_key? k
        g = read(k)
        gg = g['credits'].to_f
        g['credits'] = gg + a[0] || 1
        @db[k] = JSON.generate(g)
      else
        return false
      end
    end

    def debit k, *a
      if @db.has_key? k
        g = read(k)
        gg = g['credits'].to_f
        g['credits'] = gg - a[0] || 1
        @db[k] = JSON.generate(g)
      else
        return false
      end
    end
    
    
    # get entry
    def read k
      if @db.has_key? k
        JSON.parse(@db[k])
      else
        return false
      end
    end
    # make new entry
    def create k
      if !@db.has_key? k
        @db[k] = JSON.generate(@skel)
      end
    end
    def [] k
      read k
    end
    # delete entry
    def destroy k
      @db.delete k
    end
    # update template
    def skel
      @skel
    end
    def entries
      @db.keys
    end
    def include? k
      entries.include? k
    end
  end
end

module DB
  def self.[] k
    Z4Db[k.to_sym]
  end
  def self.table n, h={}
    Z4Db.table n, h
  end
end
