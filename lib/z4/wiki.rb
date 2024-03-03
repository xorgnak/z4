module INFO
  @@INFO = Hash.new do |h,k|
    h[k] = Wikipedia.find(k.to_s).summary.gsub(/\n+/,"\n").split("\n")
  end
  def self.[] k
    @@INFO[k]
  end
  def self.keys
    @@INFO.keys
  end
  def self.to_h
    @@INFO
  end
end

module WIKI
  
  @@GPS = Hash.new { |h,k| h[k] = Gps.new(k) }
  class Gps
    def initialize k
      @id = k
      @x = OBJ[:gps][k]
    end
    def obj
      @x
    end
    def weather
      Z4.weather(lat: @x.attr[:lat].to_f, lon: @x.attr[:lon].to_f)
    end
    def grid
      GRID.to_grid(@x.attr[:lat].to_f, @x.attr[:lon].to_f)
    end
    def id; @id; end
  end
  
  def self.gps
    @@GPS
  end

  @@W = Hash.new { |h,k| h[k] = W.new(k) }
  class W
    def initialize k
      @id = k
      @x = OBJ[:wiki][k]
    end
    def obj
      @x
    end
    def id; @id; end
    
  end

  
  @@WIKI = Hash.new do |h,k|
    a, x = [], @@W[k.to_s]
    if x.obj.attr[:text] == nil
      s = Wikipedia.find(k.to_s)
      if s.class != nil
        %[#{s.summary}].split("\n").each { |e|
          if !/^=+/.match(e)
            a << %[#{e}]
          end
        }
        aa = []; a.join("\n").split(/\n+/).each { |e| aa << e.gsub('"',"'").gsub(/\s+/," ").strip }
        x.obj.attr[:text] = aa.join("\n\n")
        x.obj.attr[:url] = s.fullurl
        x.obj.attr[:edit] = s.editurl
        cc, c = [], [];
        [s.categories].flatten.each { |e| if e != nil; cc << e.gsub("Category:",""); end }
        cc.each { |e|
          if !/^All articles/.match(e) && !/^Articles/.match(e) && !/^Coordinates on/.match(e) && !/^Short description is/.match(e)
            c << e
          end
        }
        x.obj.attr[:categories] = c.join("\n\n")
        
        x.obj.attr[:google] = "https://www.google.com/search?q=#{k.gsub(" ","+")}"
        
        x.obj.attr[:map] = "https://www.google.com/maps/place/#{k.gsub(" ","+")}"
        
        xx = s.coordinates
        
        if xx != nil
          x.obj.attr[:grid] = GRID.to_grid(xx[0], xx[1])
          x.obj.attr[:lat] = xx[0]
          x.obj.attr[:lon] = xx[1]
          g = @@GPS[k.to_s]
          g.obj.attr[:lat] = xx[0]
          g.obj.attr[:lon] = xx[1]
          g.obj.attr[:map] = x.obj.attr[:map]
          g.obj.attr[:google] = x.obj.attr[:google]
          g.obj.attr[:edit] = x.obj.attr[:edit]
          g.obj.attr[:url] = x.obj.attr[:url]
          g.obj.attr[:text] = x.obj.attr[:text]          
        end
      end
      h[k] = x
    end
  end 
  def self.[] k
    @@WIKI[k]
  end
  def self.keys
    @@WIKI.keys
  end
  def self.to_h
    @@WIKI
  end
end
