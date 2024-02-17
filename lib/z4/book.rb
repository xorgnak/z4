module BOOK
  class O
    def initialize h={}
      h.each_pair { |k,v| self.define_singleton_method(k.to_sym) { %[#{v}] } }
    end
  end
  @@BOOKS = RediSearch::Index.new(:redisearch) { text_field :text }
  @@BOOKS.create
  
  @@BOOK = Hash.new { |h,k| h[k] = File.read(k).split("\r\n\r\n").compact }
  
  def self.book
    @@BOOK
  end
  
  Dir['books/*.txt'].each { |e| @@BOOK[e] }
  
  @@BOOK.each_pair { |k,v|
    vs = v.length
    v.each_with_index { |e, i|
      h = {
        id: "#{k}-#{i}",
        text: "#{k}:#{i}: #{e}"
      }
      @@BOOKS.add(RediSearch::Document.for_object(REDISEARCH, O.new(h)))
    }
  }

  def self.search i, &b
    o = []
    @@BOOKS.search(i).each { |e| 
      if block_given?
        o << b.call(e)
      else
        o << e.text
      end
    }
    return o
  end
  
  def self.[] k
    o = []
    [k.split(" ")].flatten.each { |e|
      if !["the","and","a","in","by"].include? e
        BOOK.search(e).each { |ee|
          x = ee.split(" ");
          xA = x.shift;
          p = x.join(" ");
          xAA = xA.split(":");
          o << %[About #{e} in #{xAA[0].gsub("books/","").gsub(".txt","").gsub("_", " ")} on line #{xAA[1]}: #{p}]
        }
      end
    }
    return o
  end
end
