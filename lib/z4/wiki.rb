module WIKI
  @@GPS = Hash.new { |h,k| h[k] = Gps.new(k) }
  class Gps
    include Redis::Objects
    value :lat
    value :lon
    value :grid
    value :categories
    value :url
    value :edit
    value :text
    value :google
    value :map

    set :tags

    def initialize k
      @id = k
    end
    def id; @id; end
  end
  
  def self.gps
    @@GPS
  end
  
  @@WIKI = Hash.new do |h,k|
    a, x = [], {}
    s = Wikipedia.find(k.to_s)
    if s.class != nil
      %[#{s.summary}].split("\n").each { |e|
        if !/^=+/.match(e)
          a << %[#{e}]
        end
      }
      aa = []; a.join("\n").split(/\n+/).each { |e| aa << e.gsub('"',"'").gsub(/\s+/," ").strip }
      x[:text] = aa.join("\n\n")
      x[:url] = s.fullurl
      x[:edit] = s.editurl
      cc, c = [], [];
      [s.categories].flatten.each { |e| if e != nil; cc << e.gsub("Category:",""); end }
      cc.each { |e|
        if !/^All articles/.match(e) && !/^Articles/.match(e) && !/^Coordinates on/.match(e) && !/^Short description is/.match(e)
          c << e
        end
      }
      x[:categories] = c.join("\n\n")
      
      x[:google] = "https://www.google.com/search?q=#{k.gsub(" ","+")}"
      
      x[:map] = "https://www.google.com/maps/place/#{k.gsub(" ","+")}"
      
      xx = s.coordinates

      if xx != nil
        x[:grid] = Z4.to_grid(xx[0], xx[1])
        x[:lat] = xx[0]
        x[:lon] = xx[1]
        g = @@GPS[k.to_s]
        g.lat.value = x[:lat]
        g.lon,value = x[:lon]
        g.grid.value = x[:grid]
        g.map.value = x[:map]
        g.google.value = x[:google]
        g.edit.value = x[:edit]
        g.url.value = x[:url]
        g.text.value = x[:text]
      end
      
      h[k] = x
    else
      h[k] = false
    end
  end 
  def self.[] k
    @@WIKI[k]
  end
  def self.keys
    @@WIKI.keys
  end
end
