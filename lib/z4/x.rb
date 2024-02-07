module OBJ
  class X
    include Redis::Objects
    
    value :uuid    
    sorted_set :grid
    sorted_set :epoch
    value :parent
    set :children
    hash_key :attr
    sorted_set :stat
    hash_key :tag
    set :tags
    list :hist

    def initialize k, h={}
      @id = k
      if h.has_key? :uuid
        self.uuid.value = h[:uuid]
      end
      if h.has_key? :parent
        self.parent.value = h[:parent]
      end
      @redisearch = RediSearch::Index.new(@id) { text_field :text }
      @redisearch.create
    end
    def id;
      @id
    end
    def bag
      BAG[@id]
    end
    def index h={}
      @redisearch.add(RediSearch::Document.for_object(@redisearch, O.new(h)))
    end
    def search i, &b
      o = []
      @redisearch.search(i, fuzziness: 1).each { |e| if block_given?; o << b.call(e); else; o << e.text; end }
      return o
    end
    def redisearch
      @redisearch
    end
  end
  @@XX = Hash.new { |h,k| h[k] = XX.new(k) }
  class XX
    include Redis::Objects
    hash_key :attr
    sorted_set :stat
    set :children
    set :privledges
    def initialize k
      @id = k
      @x = Hash.new { |h,k| h[k] = X.new(k) }
      @redisearch = RediSearch::Index.new(@id) { text_field :text }
      @redisearch.create
    end
    def [] k
      @x[k]
    end
    def keys
      @x.keys
    end
    def id; @id; end
    def index h={}
      @redisearch.add(RediSearch::Document.for_object(@redisearch, O.new(h)))
    end
    def search i, &b
      o = []
      @redisearch.search(i, fuzziness: 2).each { |e| if block_given?; o << b.call(e); else; o << e.text; end }
      return o
    end
    def redisearch
      @redisearch
    end
  end   
  def self.[] k
    @@XX[k]
  end
  def self.keys
    @@XX.keys
  end
end
