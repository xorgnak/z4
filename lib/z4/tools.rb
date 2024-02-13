module Z4
###

### TEXT ANALYSIS

###

  def self.analyze t
    WordCountAnalyzer::Analyzer.new.analyze(t)
  end

  ###
  
  ### EQUATION HANDLER
  
  ###
  
  
  def self.equation f, h={}
    x = Eqn::Calculator.new(f)
    x.set(h)
    return x.calc
  end

  ###
  
  ### TEMPLATES
  
  ###
  
  
  @@TEMPLATES = {}
  ### use template
  
  def self.template t, x
    if x.class == String
      @@TEMPLATES[t] = s
    else
      @opts = x.to_h
      ERB.new(@@TEMPLATES[t]).result(binding)
    end
  end

  @@COLORS = {}

  def self.colors *i
    if i[0]
      if i[1]
        if !@@COLORS.has_key? i[0]
          @@COLORS[i[0]] = i[1]
        end
      else
        if !@@COLORS.has_key? i[0]
          return -1
        else
          @@COLORS[i[0]]
        end
      end
    else
      return @@COLORS
    end
  end
  
  
  # the z4 bank.
  
  def self.xfer h={}
    hh = { from: 'Z4 Bank', to: 'Z4 Bank', amt: 0, memo: "Z4 transaction." }.merge(h)
    t,o = 0,[]
    f = OBJ[:user][hh[:from]]
    [hh[:to]].flatten.each { |e|
      u = OBJ[:user][e]
      u.stat.incr(:gp, hh[:amt].to_f);
      f.stat.decr(:gp, hh[:amt].to_f);
      t += hh[:amt].to_f
      o << %[#{f.attr[:name] || hh[:from]} --(#{hh[:amt]})-> #{u.attr[:name] || e} #{hh[:memo]}]
    }
    o << %[#{f.attr[:name] || hh[:from]} ==(#{t})=> #{hh[:to]} #{hh[:memo]}]
    return o
  end

  def self.level n
    %[#{n.to_i}].length - 1
  end

  def self.heart
    [ 'volunteer_activism', 'favorite_border', 'favorite', 'loyalty', 'diversity_2', 'diversity_1', 'monitor_heart' ]
  end

  def self.star
    [ 'star_border', 'star', 'hotel_class', 'auto_awesome', 'military_tech', 'emoji_events', 'tour', 'flag' ]
  end

  def self.border
    [ 'solid', 'solid', 'solid', 'dashed', 'dashed', 'dashed', 'dotted', 'dotted' ]
  end

  def self.color
    [ 'black', 'red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'violet' ]
  end
  
  ###
  
  ### EMOJI
  
  ###
  
  
  @@GEMOJI = Hash.new { |h,k| x = Emoji.find_by_alias(k.to_s); if x != nil; h[k] = x; end }
  def self.emoji
    @@GEMOJI
  end
  def self.emojis
    @@GEMOJI.keys
  end
  
end
