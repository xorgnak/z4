module Z4
  class O
    def initialize h={}
      h.each_pair { |k,v| self.define_singleton_method(k.to_sym) { %[#{v}] } }
    end
  end

  def self.index h={}
    REDISEARCH.add(RediSearch::Document.for_object(REDISEARCH, O.new(h)))
  end

  def self.search i, &b
    o = []
    REDISEARCH.search(i, fuzziness: 2).each { |e|
      #puts %[search e: #{e.methods}]
      if block_given?
        o << b.call(e)
      else
        o << e.text
      end
    }
    return o
  end

end
