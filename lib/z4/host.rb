class Z4Type
  def initialize *h
    @host = h[0]
    @type = :type
    @id = @host
  end
  def new?
    if !DB[@type].include? @id
      DB[@type].create(@id)
    end
  end
  def db
    DB[@type][@id]
  end
  
  def credits
    DB[@type][@id]['credits']
  end

  def exchange *v
    if v[0]
      (v[0] / exchange)
    else
      DB[@type][@id]['exchange']
    end
  end
  
  def worth
    (credits / exchange)
  end

  def [] k
    DB[@type][@id][k.to_s]
  end
  def []= k,v
    DB[@type].update(@id, { k => v })
  end
  def credit a
    DB[@type].credit @id, a.to_f
  end
  def debit a
    DB[@type].debit @id, a.to_f
  end
  def incr k, i, *a
    h = DB[@type][@id][k.to_s]
    h[i] ||= 0
    h[i] += a[0] || 1
    DB[@type].update(@id, { k => h })
  end
  def decr k, i, *a
    h = DB[@type][@id][k.to_s]
    h[i] ||= 0
    h[i] -= a[0] || 1
    DB[@type].update(@id, { k => h })
  end
  def id
    @id
  end
  def http
    "http://#{@id}"
  end
  def https
    "https://#{@id}"
  end
end

class Z4Host < Z4Type
  def initialize *h
    super
    @type = :host
    @brand = Hash.new { |h,k| h[k] = Z4Brand.new(@host, k) }
    @user = Hash.new { |h,k| h[k] = Z4User.new(@host, k) }
    new?
  end
  def brand
    @brand
  end
  def user
    @user
  end
end

class Z4Brand < Z4Type
  def initialize *h
    super
    @type = :brand
    @name = h[1]
    @id = "#{@name}"
    @team = Hash.new {|h,k| h[k] = Z4Team.new(@host, @id, k) }
    new?
  end
  def team
    @team
  end
end

class Z4Team < Z4Type
  def initialize *h
    super
    @type = :team
    @brand, @name = h[1], h[2]
    @id = "#{@name}"
    @item = Hash.new { |h,k| h[k] = Z4Item.new(@brand, @team, @id, k) }
    @place = Hash.new { |h,k| h[k] = Z4Place.new(@brand, @team, @id, k) }
    @campaign = Hash.new { |h,k| h[k] = Z4Campaign.new(@brand, @team, @id, k) }
    new?
  end
  def item
    @item
  end
  def place
    @place
  end
  def campaign
    @campaign
  end
end

class Z4Item < Z4Type
  def initialize *h
    super
    @type = :item
    @brand, @team, @name = h[1], h[2], h[3]
    @id = "#{@name}"
    new?
  end
end

class Z4Place < Z4Type
  def initialize *h
    super
    @type = :place
    @brand, @team, @name = h[1], h[2], h[3]
    @id = "#{@name}"
    new?
  end
end

class Z4Campaign < Z4Type
  def initialize *h
    super
    @type = :campaign
    @brand, @team, @name = h[1], h[2], h[3]
    @id = "#{@name}"
    new?
  end
end

class Z4User < Z4Type
  def initialize *h
    super
    @type = :user
    @name = h[1]
    @id = "#{@name}"
    new?
  end
  def level
    DB[@type][@id][:level]
  end
end

class Z4Chan < Z4Type
  def initialize *h
    super
    @type = :chan
    @name = h[1]
    @id = "#{@name}"
    new?
  end
end

# campaign visit
class Z4Visit < Z4Type
  def initialize *h
    super
    @type = :visit
    @brand, @team, @name, @campaign, @visit = h[1], h[2], h[3], h[4], h[5]
    @id = "#{@visit}"
    new?
    t = Time.now.utc.to_i
    DB[@type].update @id, { last: t }
    if DB[@type][@id][:created] == 0
      DB[@type].update @id, { created: Time.now.utc.to_i }
    end
  end
end

class Z4Badge
  def initialize host, brand, team, user, campaign
    @host, @brand, @team, @user, @campaign = host, brand, team, user, campaign 
  end
  def query h={}
    o = []
    { brand: @brand, team: @team, user: @user, campaign: @campaign }.merge(h).each_pair { |k,v|
      vv = ERB::Util.url_encode v
      o << %[#{k}=#{vv}]
    }
    return o.join("&")
  end
  def route r
    url r
  end
  def url r
    return %[https://#{@host}/#{r}?#{query}]
  end
  def campaign x
    return %[https://#{@host}/campaign/#{query({ x: x })}]                      
  end
  def scanner
    return %[https://#{@host}/user/#{query}]
  end
end


##
# Basic Routing
## cmd 
# Z4[host].brand[b].team[t]
# Z4[host].brand[b].team[t].item[i]
# Z4[host].brand[b].team[t].place[p]
# Z4[host].brand[b].campaign[c]
## mention
# Z4[host].user[u]
module Z4
  def self.[] k
    Z4Host.new(k)
  end
  def self.chan c
    Z4Chan.new('localhost', c)
  end
end
