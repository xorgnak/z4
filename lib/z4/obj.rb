
module OBJ
  @@TINY = 15
  @@SMALL = 50
  @@MED = 70
  @@LARGE = 100
  
  class DataSet
    include OBJ
    def initialize p, k
      @id = "#{p}-#{k}"
      @parent = p
      @db = PStore.new("db/dataset-#{@id}.pstore")
      @info = PStore.new("db/dataset-#{@id}-meta.pstore")
    end
    def id; @id; end
    def transaction &b
      @db.transaction { |db| b.call(db) }
    end
    def [] k
      get k
    end
    def get k
      @db.transaction { |db| db[k] }
    end
    def << k
      add k
    end
    def add k
      i = length
      if !include? k
        @db.transaction { |db| db[i] = k }
      end
    end
    def sort *i
      if i[1]
        @info.transaction { |db| if !db.key?(i[0]); db[i[0]] = []; end; db[i[0]] << i[1]; db[i[0]].uniq }
      else
        @info.transaction { |db| db[i[0]] }
      end
    end
    def import c
      c.gsub(/\r\n/,"\n").gsub(/\n\n+/,"\n\n").split("\n\n").each_with_index { |e,i|
        x = e.gsub(/\n/," ").gsub(/\s+/," ").strip;
        w = x.split(/\s/)
        if w.length < @@TINY
          s = :info
          #sort s, i
        elsif w.length > @@TINY && w.length <= @@SMALL
          s = :tiny
          sort s, i
        elsif w.length > @@SMALL && w.length <= @@MED
          s = :small
          #sort s, i
        elsif w.length > @@MED && w.length <= @@LARGE
          s = :medium
          #sort s, i
        elsif w.length > @@LARGE
          s = :large
          #sort s, i
        end
        if [:tiny].include? s
          @db.transaction { |db| db[i] = x }
        end
      }
    end
    def length
      @db.transaction { |db| db.keys.length }
    end
    def clear!
      @db.transaction { |db| db.keys.each { |e| db.delete(e); } }
    end    
    def include? i
      r = false
      @db.transaction { |db| db.keys.each { |e| if i == db[e]; r = true; end; } }
      return r
    end
    def filter *k
      h = Hash.new { |h,k| h[k] = [] }
      [k].flatten.each do |key|
        @db.transaction { |db| db.keys.each { |e| if Regexp.new(key).match(db[e]); h[key] << e; end; } }
      end
      a = []
      h.each_pair { |k,v| if a.length == 0; a = v; else; a = v.intersection(a) end; }
      return a
    end
    def each &b
      @db.transaction { |db| db.keys.each_with_index { |e,i| b.call(db[e], e, i) } }
    end
  end
  
  
  class SortedSet
    def initialize p, k
      @id = "#{p}-#{k}"
      @parent = p
      @db = PStore.new("db/sortedset-#{@id}.pstore")
    end
    def id; @id; end
    def transaction &b
      @db.transaction { |db| b.call(db) }
    end    
    def has_key? i
      @db.transaction { |db| db.key?(i) }
    end
    def [] k
      get(k)
    end
    def []= k,v
      set k,v
    end
    def delete k
      @db.transaction { |db| db.delete(k); }
    end
    def clear!
      @db.transaction { |db| db.keys.each { |e| db.delete(e); } }
    end    
    def incr k, *n
      xx = n[0] || 1
      @db.transaction { |db| x = db[k].to_f; db[k] = x + xx }
    end
    def decr k, *n
      xx = n[0] || 1
      @db.transaction { |db| x = db[k].to_f; db[k] = x - xx }
    end
    def get k
      @db.transaction { |db| db[k] }
    end
    def set k, v
      @db.transaction { |db| db[k] = v }
    end
    def keys
      @db.transaction { |db| db.keys }
    end
    def to_h &b
      h = {}
      @db.transaction { |db| db.keys.each { |e| h[e] = db[e] } }
      if block_given?
        b.call(h)
      else
        return h
      end
    end
  end
  
  
  class HashKey
    def initialize p, k
      @id = "#{p}-#{k}"
      @parent = p
      @db = PStore.new("db/hashkey-#{@id}.pstore")
    end
    def id; @id; end
    def transaction &b
      @db.transaction { |db| b.call(db) }
    end
    def has_key? i
      @db.transaction { |db| db.key?(i) }
    end
    def [] k
      get(k)
    end
    def []= k,v
      set k,v
    end
    def get k
      @db.transaction { |db| db[k] }
    end
    def set k, v
      @db.transaction { |db| db[k] = v }
    end
    def keys
      @db.transaction { |db| db.keys }
    end
    def delete k
      @db.transaction { |db| db.delete(k); }
    end
    def clear!
      @db.transaction { |db| db.keys.each { |e| db.delete(e); } }
    end    
    def to_h
      h = {}
      @db.transaction { |db| db.keys.each { |e| h[e] = db[e] } }
      if block_given?
        b.call(h)
      else
        return h
      end
    end  
  end
  
  
  class X
    attr_reader :id, :type, :meta, :attr, :stat, :data
    
    def initialize t, k
      @type = t
      @id = k
      @meta = HashKey.new(@id, :meta)
      @attr = HashKey.new(@id, :attr)
      @stat = SortedSet.new(@id, :stat)
      @data = DataSet.new(@id, :data)
    end
  end
  
  class XX
    attr_reader :id
    def initialize k
      @id = k
      @x = Hash.new { |h,k| h[k] = X.new(@id, k) }
    end
    def keys
      @x.keys
    end
    def [] k
      @x[k]
    end
    def filter *kk
      h = {}
      @x.each_pair { |k,v| h[k] = v.data.filter(kk) }
      return h
    end
    def sort kk
      h = {}
      @x.each_pair { |k,v| h[k] = v.data.sort(kk) }
      return h
    end
    def compile *kk
      a = []
      filter(kk).each_pair { |k,v|
        if v.length > 0;
          if v.length > 1
            r = rand(1..2)
            v.sample(r).each { |e| a << @x[k].data[e].strip }
          else
            a << @x[k].data[v[0]].strip
          end
        end
      }
      return a.join("\n").strip
    end
  end

  @@X = Hash.new { |h,k| h[k] = XX.new(k) }
  def self.[] k
    @@X[k]
  end
  def self.keys
    @@X.keys
  end
end

