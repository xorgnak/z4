
class E 
  def initialize k
    @id = k
    @rem = []
  end
  def id; @id; end
  
  def [] k
    @rem << k
    R.new(k)
  end

  def agenda
    `remind -t1 rem/#{@id}.rem`.split("\n\n")
  end

  def to_rem
    a = [];
    @rem.each { |e| a << R.new(e).to_rem }
    return a.join("\n")
  end
  
  def to_rem!
    File.open("rem/#{@id}.rem",'w') { |f| f.write(to_rem); }
  end
end


class R

  attr_accessor :attr
  
  def initialize k
    @id = k
    @attr = {}
  end
  
  def id; @id; end
  
  def to_rem
    a = []
    if @attr.has_key? :date
      a << %[#{@attr[:date]}]
      if @attr.has_key? :lead
        a << %[++#{@attr[:lead]}]
      end
      if @attr.has_key? :repeat
        a << %[*#{@attr[:repeat]}]
      end
      if @attr.has_key? :until
        a << %[UNTIL #{@attr[:until]}]
      end
    end
    if @attr.has_key? :hour
      if @attr.has_key? :minute
        a << %[AT #{@attr[:hour]}:#{@attr[:minute]}]
      else
        a << %[AT #{@attr[:hour]}:00]
      end
    end
    if @attr.has_key? :duration
      a << %[DURATION #{@attr[:duration]}]
    end
    if @attr.has_key? :at
      a << %[TAG #{@attr[:at]}]
    end
    if @attr.has_key? :type 
      a << %[TAG #{@attr[:type]}]
    end    
    return %[REM #{a.join(" ")} MSG %b %2 #{@id}]
  end
end

module REM
  @@REM = Hash.new { |h,k| h[k] = E.new(k) }
  def self.[] k
    @@REM[k]
  end
end
