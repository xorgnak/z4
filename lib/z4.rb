
require 'hugging_face'

require 'eqn'

require 'faraday'

require 'textmood'

require 'wikipedia-client'

require 'erb'

require 'redi_search'

require 'redis-objects'

require 'sinatra/base'

require 'connection_pool'

require 'discordrb'

require 'gemoji'

Redis::Objects.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(:host => '127.0.0.1', :port => 6379) }

REDISEARCH = RediSearch::Index.new(:redisearch) { text_field :text }
REDISEARCH.create

module Z4

  ###
  ### QUERY POOL
  ###

  class Pool
    include Redis::Objects

    sorted_set :terms
    
    def initialize k
      @id = k
    end
    def length
      self.terms.members.length
    end
    def [] k
      Item.new(%[#{@id}-#{k}])
    end
    def each &b
      h = self.terms.members(with_scores: true).to_h.sort_by { |k,v| -v }
      h.to_h.each_pair { |k,v| b.call(k,v,Item.new(%[#{@id}-#{k}])) }
    end
    def id; @id; end
  end
  
  class Item
    include Redis::Objects
    sorted_set :items
    def initialize k
      @id = k
    end
    def length
      self.items.members.length
    end    
    def each &b
      h = self.items.members(with_scores: true).to_h.sort_by { |k,v| -v }
      h.to_h.each_pair { |k,v| b.call(k,v) }
    end
    def id; @id; end
  end
  
  @@QUERY = Pool.new(:pool)  
  def self.query
    @@QUERY
  end

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

  ###                                                                                                                                                                                                                            
  ### WIKIPEDIA LOOKUP                                                                                                                                                                                                           
  ###
  
  @@WIKI = Hash.new do |h,k|
    a = []
    s = Wikipedia.find(k.to_s)
    if s
      x = Wikipedia.find(k.to_s)
      s.page['extract'].split("\n").each { |e|                                                                                                                                                                           
        if !/^=+/.match(e)                                                                                                                                                                                                       
          a << %[#{e}]
        end
      }
      aa = []; a.join("\n").split(/\n+/).each { |e| aa << e.gsub('"',"'").gsub(/\s+/," ").strip }
      h[k] = aa
    else
      return false
    end
  end
  ### info lookup stub.                                                                                                                                                                                                         
  def self.wiki
    @@WIKI
  end
  
  @@GPS = Hash.new do |h,k|
    x = Wikipedia.find(k.to_s)
    if x
      xx = x.coordinates
      if xx != nil
        h[k] = [ xx[0], xx[1] ]
      end
    end
  end
  ### gps coordinates from wikipedia stub
  def self.place
    @@GPS
  end


  ###                                                                                                                                                                                                                            
  ### LLM                                                                                                                                                                                                                        
  ###
  
  # process input.
  def self.handle h={}
    w = h[:input].split(" ")

    c = w[0]

    cmd = false
    
    puts %[handle h: #{h}]

    r = []
    
    @user = Z4.make h[:user], :user
    @chan = Z4.make h[:chan], :chan
    
    if m = /^#(.+)!$/.match(c)
      cmd = true
      w.shift

      [m[1].split("-")].flatten.each do |et|
        i = %[#{@chan.attr[:name].gsub(" ","_")}-#{@user.attr[:nick].gsub(" ","_")}-#{et}]
        s = %[#{et}: #{w.join(" ")} per #{@user.attr[:nick]} at #{Time.now.utc.strftime("%F %T")}]        
        puts %[handle tag: #{et}]
        Z4.query.terms.incr(et)
        Z4.query[et].items.incr(w.join(" "))
        Z4.tag[et].tag(h[:user])
        puts %[handle tag: #{h[:user]}]
        h[:users].each { |ee|
          puts %[handle win: #{ee}]
          Z4.tag[et].win(ee)
        }
        @chan.index id: i, text: s
        Z4.index id: i, text: s        
      end
      
      @user.stat.incr(:xp)
      @user.stat.incr(:gp)
      @chan.stat.incr(:xp)
      @chan.stat.incr(:gp)

      r << %[#{m[1]} HEARD.]

    elsif m = /^#(.+)\?$/.match(c)
      w.shift
      @chan.search(m[1]).each { |x| r << x }
      Z4.search(m[1]).each { |x| r << x }
    end
    
    #    puts %[handle R: #{r.length}]
    if r.length == 0
      if cmd == false && w.length > 0
        hh = { batch: 256, ext: 0.1 }.merge(h)
        #      puts %[handle hh: #{hh}]
        p = %[#{hh[:info]}\n#{hh[:task]}\nUser: #{w.join(" ")}\nBot: ]
        #      puts %[handle p: #{p}]
        a = %[-b #{hh[:batch]} --rope-scaling yarn --yarn-ext-factor #{hh[:ext]}]
        #      puts %[handle a: #{a}]
        `llama #{a} -p "#{p}" 2> /dev/null`.gsub(p,"").strip.split("\n").each { |e| puts %[handle e: #{e}]; r << e }
      end
    end
    
    puts %[handle return #{r}]
    return r
  end
  
  # llama predefined response getter/setter
  @@CANNED = {}
  def self.canned k, v
    @@CANNED[k] = v
  end

  def self.predefines
    @@CANNED
  end
  
  # random prompts for stock frontend.
  @@RAND = []
  def self.random *k
    if k[0]
      @@RAND << k[0]
    else
      @@RAND.sample
    end
  end
  
  # the z4 bank.
  def self.xfer h={}
    hh = { from: 'Z4 Bank', to: 'Z4 Bank', amt: 0, memo: "Z4 transaction." }.merge(h)
    t,o = 0,[]
    f = Z4.make(hh[:from], :user)
    [hh[:to]].flatten.each { |e|
      u = Z4.make(e, :user)
      u.stat.incr(:gp, hh[:amt].to_f);
      f.stat.decr(:gp, hh[:amt].to_f);
      t += hh[:amt].to_f
      o << %[#{f.attr[:name] || hh[:from]} --(#{hh[:amt]})-> #{u.attr[:name] || e} #{hh[:memo]}]
    }
    o << %[#{f.attr[:name] || hh[:from]} ==(#{t})=> #{hh[:to]} #{hh[:memo]}]
    return o
  end


  ###
  ### SEARCH
  ###

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
  
  def self.cortex u, &b
    o = []
    REDISEARCH.search(u).each { |e|
      #puts %[search e: #{e.methods}]
      if block_given?
        o << b.call(e)
      else
        o << e.text
      end
    }
    return o
  end

  
  # generic container class
  @@XX = Hash.new { |h,k| h[k] = XX.new(k) }
  class XX
    include Redis::Objects

    hash_key :attr
    sorted_set :stat
    sorted_set :has
    sorted_set :need
    set :children
    set :privledges
    
    def initialize k
      @id = k
      @base = Z4.level[k]
      @redisearch = RediSearch::Index.new(@id) { text_field :text }
      @redisearch.create
    end
    def id; @id; end
    def base; @base; end
    def index h={}
      @redisearch.add(RediSearch::Document.for_object(@redisearch, O.new(h)))
    end
    def search i, &b
      o = []
      @redisearch.search(i, fuzziness: 2).each { |e|
        #puts %[search e: #{e.methods}]                                                                                                                                                              
        if block_given?
          o << b.call(e)
        else
          o << e.text
        end
      }
      return o
    end
    def redisearch
      @redisearch
    end
  end
  def self.type
    @@XX
  end

  # generic singleton class
  @@X = Hash.new { |h,k| h[k] = X.new(k) }
  # base object
  class X
    include Redis::Objects
    # universally unique id
    value :uuid
    # locations while active
    sorted_set :grid
    # qr scans
    sorted_set :epoch
    # id of parent object or nil
    value :parent
    # node: number of children to be viable
    counter :node
    # cohort: number of children to be effective
    counter :cohort
    # school: number of children to be visible
    counter :school
    # capacity
    counter :full
    # set of ids of children
    set :children
    # hash of attributes (name, age, desc, etc...)
    hash_key :attr
    # inventory
    sorted_set :inv
    # stats (xp, gp, etc...)
    sorted_set :stat
    # items using
    list :equip
    # object, item, chan, user
    value :type
    # chans
    set :chans
    # users
    set :users
    # interests
    set :topics
    # certifications
    set :badges
    # input history
    list :hist
    
    def initialize k, h={}
      @id = k
      if h.has_key? :uuid
        self.uuid.value = h[:uuid]
      end
      if h.has_key? :parent
        self.parent.value = h[:parent]
      end
      if h.has_key? :full
        self.full.value = h[:full]
      end
      if h.has_key? :type
        self.type.value = h[:type]
        if self.uuid.value != nil
          Z4.type[h[:type].to_sym].children << id
        end
      end
      if h.has_key? :grid
        self.grid.value = h[:grid]
      end
      
      @redisearch = RediSearch::Index.new(@id) { text_field :text }
      @redisearch.create
    end
    def id;
      @id
    end




    
    def tokens
      Z4.token[@id]
    end
    def tag
      
    end





    def index h={}
      @redisearch.add(RediSearch::Document.for_object(@redisearch, O.new(h)))
    end
    def search i, &b
      o = []
      @redisearch.search(i, fuzziness: 1).each { |e|
        puts %[search e: #{e}]
        if block_given?
          o << b.call(e)
        else
          o << e.text
        end
      }
      return o
    end
    def redisearch
      @redisearch
    end
  end



  # singleton type casting
  def self.make k, t
    @@X[k] = X.new(k,Z4.level[t])
  end
  # singleton lookup
  def self.[] k
    @@X[k]
  end
  # all singletons
  def self.all
    @@X.keys
  end
  
  def self.level
    return {
      user: { type: :user, node: 2, cohort: 10, school: 50, full: 100},
      chan: { type: :chan, node: 3, cohort: 200, school: 750, full: 1000},
      item: { type: :item, node: 5, cohort: 5, school: 7, full: 10},
      object: { type: :object, node: 10, cohort: 5, school: 15, full: 20},
      place: { type: :place, node: 100, cohort: 1000, school: 7500, full: 10000},
      topic: { type: :topic, node: 1000, cohort: 10000, school: 50000, full: 100000},
    }
  end
  # startup object mapping
  def self.init!
    Z4.level.keys.each { |e| Z4.type[e].children.members.each { |ee| Z4[ee] } }
  end
  # required singleton attributes
  @@REQ = {}
  def self.require
    @@REQ
  end
  def self.redis
    Redis::Objects.redis
  end
  def self.flushdb
    Z4.redis.flushdb
  end

  def self.lvl n
    %[#{n.to_i}].length - 1
  end
  def self.heart
    [ 'volunteer_activism', 'favorite_border', 'favorite', 'loyalty', 'diversity_2', 'diversity_1', 'monitor_heart' ]
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
  
  ###
  ### URL SHORTENING
  ###
  
  class PATH
    include Redis::Objects

    hash_key :a
    hash_key :b
    
    def initialize
      @id = :path
    end

    def random
      a = []
      10.times { if rand(2) == 0; a << rand(16).to_s(16).upcase; else a << rand(16).to_s(16); end }
      return a.join("")
    end

    def make k, p
      self.a[k] = p
      self.b[p] = k
    end

    def make! p
      if !path? p
        k = random
        while key?(k) do
          k = random
        end
        make k, p 
      end
      return path p
    end
    
    def path? k
      if self.b[k] != nil
        return true
      else
        return false
      end
    end

    def path k
      self.b[k]
    end

    def key? k
      if self.a[k] != nil
        return true
      else
        return false
      end
    end

    def key k
      self.a[k]
    end
    
    def id; @id; end
  end
  
  @@PATH = PATH.new
  
  def self.path
    @@PATH
  end

  ###
  ### TOKENS
  ###
  @@BAG = Hash.new { |h,k| h[k] = Bag.new(k) }
  @@TOKEN = Hash.new { |h,k| h[k] = Token.new(k) }
  class Bag
    include Redis::Objects
    set :token
    def initialize k
      @id = k
    end
    def id; @id; end
    def tokens
      h = {}
      self.token.members.each do |e|
        h[e] = {};
        [:short, :long].each do |ee|
          if tkn(e)[ee].valid?;
            h[e][ee] = true;
          else
            h[e][ee] = false;
          end
        end
        if h[e][:short] == false && h[e][:long] == false;
          self.token.delete(e);
        end
      end
      return h
    end
    # user token
    def [] k
      self.token << k
      return tkn(k)
    end
    # token object
    def tkn k
      return { short: Short.new(%[#{@id}-#{k}-short]), long: Long.new(%[#{@id}-#{k}-long]) }
    end
  end
  # list of tokens
  def self.bag
    @@BAG
  end
  # lists of tokens
  def self.bags
    @@BAG.keys
  end
  
  class Short
    include Redis::Objects
    
    value :valid, :expireat => lambda { Time.now.utc.to_i + ((60 * 60) * 24) }
    
    def initialize k
      @id = k
    end
    def id; @id; end
    def valid!
      self.valid.value = Time.now.utc.to_i
    end
    # valid until or false
    def valid?
      if self.valid.value != nil
        return self.valid.value.to_i
      else
        return false
      end
    end
  end

  class Long
    include Redis::Objects

    value :valid, :expireat => lambda { Time.now.utc.to_i + (((60 * 60) * 24) * 7) } 
    def initialize k
      @id = k
    end
    def id; @id; end
    def valid!
      self.valid.value = Time.now.utc.to_i
    end
    # valid until or false
    def valid?
      if self.valid.value != nil
        return self.valid.value.to_i
      else
        return false
      end
    end
  end
  
  # Z4.token[X] => bag of obj's tokens
  # Z4.token[X][tag] => obj token
  # Z4.token[X][tag].valid! => validate obj token
  # Z4.token[X].each { |e| ... } => each obj valid token
  def self.token
    @@BAG
  end

  ###
  ### TAG LEADERS
  ###
  
  @@TAG = Hash.new { |h,k| h[k] = Tag.new(k) }
  
  class T
    include Redis::Objects
    sorted_set :tag
    sorted_set :won
    def initialize k
      @id = k
    end
    def id; @id; end
    def to_h
      h = {}
      self.tag.members(with_scores: true).to_h.each_pair { |t,n| h[t] = { tagged: n.to_i, won: self.won[t].to_i } }
      return h
    end
  end
  class Tag
    include Redis::Objects
    sorted_set :tagged
    sorted_set :won
    def initialize k
      @id = k
    end
    def id; @id; end
    def [] k
      player(k)
    end
    def tag x
      t = Z4.token[x][@id]
      [:short, :long].each { |e| t[e].valid! }      
      self.tagged.incr(x); player(x).tag.incr(@id)
    end
    def win x
      tag(x)
      self.won.incr(x);
      player(x).won.incr(@id)
    end
    def player x
      T.new(%[#{@id}-#{x}])
    end
    def to_h
      h = {}
      self.tagged.members(with_scores: true).to_a.each { |u, t| h[u] = { tagged: t.to_i, won: self.won[u].to_i }  }
      return h
    end
  end
  
  # Z4.tag[tag].tag! u => add tag to player, validate token
  # Z4.tag[tag].win u => incr won for player within tag, validate token
  # Z4.tag[tag][X] => validate token return player
  def self.tag
    @@TAG
  end
end

Dir['lib/z4/*'].each { |e| if !/^.*~$/.match(e); puts %[loading #{e}]; load(e); end }

###
### BOT
###


BOT = Discordrb::Commands::CommandBot.new token: ENV['Z4_DISCORD_TOKEN'], prefix: '#'

BOT.message() do |e|
  t_start, o, a, @cmd, @act, @ok = Time.now.to_f, [], [], nil, false, true
  
  @user = Z4.make(%[#{e.user.id}], :user)
  @chan = Z4.make(%[#{e.channel.id}], :chan)
  
  @text = e.message.text
  @words = []
  @text.split(" ").each { |x| if !/<.+>/.match(x); @words << x; end }
  @text = @words.join(" ")
 
  if e.user.name == e.channel.name
    @dm = true
  else
    @dm = false
  end
  
  @priv = []; e.user.roles.each { |x| @priv << x.name }
  
  @roles = []; e.message.role_mentions.each { |x| @roles << x.name }

  @users = []; e.message.mentions.each { |x|
    puts %[users: #{x.id}]
    @users << %[#{x.id}] }
  
  @attachments = []; e.message.attachments.each { |x|
    @attachments << x.url
  }

  if @user.attr[:DEBUG] == true
    o << %[dm: #{@dm}]
    o << %[users: #{@users}]
    o << %[priv: #{@priv}]
    o << %[roles: #{@roles}]
    o << %[attachments: #{@attachments}]
  end

  Z4.predefines.each_pair { |k,v|                                                                                                                                                                                         
    if @matchdata = Regexp.new(k).match(@text);
      @ok = false
      o << ERB.new(v).result(binding);                                                                                                                                                                                 
    end
  }
  
  if !/^.+\?$/.match(@words[0]) && !/^.+!$/.match(@words[0])
    # first pass handling
    if m = /##(.+)/.match(@words[0])
      ###
      ### CHANOPS
      ###
      @act = true
      @cmd = m[1]
#      puts %[CMD: #{@cmd}]
      @words.shift
      @text = @words.join(" ")
      if @priv.include?('agent') || @priv.include?('operator')
        @chan.attr[@cmd.to_sym] = @text
        a << %[CHANOP #{@cmd} #{@text}]
      else 
        a << %[## Must be an agent or operator to do that.]
      end
    elsif m = /#(.+)/.match(@words[0])
      ###
      ### USEROPS
      ###
      @act = true
      @cmd = m[1]
#      puts %[cmd: #{@cmd}]
      @words.shift
      @text = @words.join(" ")
      if @cmd == "#"
        a << %[channel info.]
      else
        @user.attr[@cmd.to_sym] = @text
        a << %[Set #{@cmd} to #{@text}]
      end
    elsif @words[0] == "#"
      ###
      ### USERID
      ###
      @act = true
      [:xp, :gp, :lvl].each { |x| a << %[#{x}: #{@user.stat[x].to_f}] }
      @chan.attr.to_h.each_pair { |k,v| a << %[###{k} #{v}] }
      @user.attr.to_h.each_pair { |k,v| a << %[##{k} #{v}] }
      if @chan.attr[:affiliate] != nil
        a << %[https://#{@chan.attr[:affiliate]}/qr?user=#{@user.id}&chan=#{@chan.id}&epoch=#{Time.now.utc.to_i}]
      end
    end
  end
  
  # handle attribute requirements
  Z4.require.each_pair do |k,v|
      if @ok == true && @user.attr[k] == nil
        @ok = false
        a << %[REQUIRED: #{v}]
      end
  end


  @h = { input: @text, user: %[#{e.user.id}], chan: %[#{e.channel.id}], users: @users, roles: @roles, priv: @priv, attachments: @attachments }
  
  if @ok == true
    if @cmd == nil && @text.length > 0
      @context = [ %[The #{@chan.attr[:name]} channel is is affiliated with #{@chan.attr[:affiliate]} and is for #{@chan.attr[:purpose]}.] ]    
      @context << %[User's name is #{@user.attr[:name]} and is #{@user.attr[:age]} years old.]
      @context << %[User has lived in #{@user.attr[:city]} since #{@user.attr[:since]}.]
      
      if @user.attr[:job] != nil
        @context << %[User's is a #{@user.attr[:job]}.]
      end
      
      if @user.attr[:union] != nil
        @context << %[And User is a member of the #{@user.attr[:union]} union.]
      end
      
      if @dm == false  
        # channel privledges.
        if @priv.length > 0
          if @priv.length > 1
            @context << %[User has the roles of #{@priv.join(" and ")}.]
          else
            @context << %[User has the role of #{@priv[0]}.]
          end
        end
        # channel deep organization.
        if @chan.attr[:task] != nil
          @h[:task] = @chan.attr[:task]
        end
      end
      @h[:info] = @context.join(" ")
      if @act == false
        Z4.handle(@h).each { |x| o << x.strip.gsub(@context.join(" "),'') }
      end
    else
      if @act == false
        e.respond(%[Let me think...])
        @h[:info] = @context.join(" ")
        @h[:task] = @chan.attr[:task] || %[Respond to User.  Be helpful.]
        @h[:batch] = @chan.attr[:batch].to_i
        @h[:ext] = @chan.attr[:ext].to_i
        @hh = { batch: 256, ext: 0.1 }.merge(@h)
        Z4.handle(@hh).each { |x| o << x.strip.gsub(@context.join(" "), '') }
      else
        e.respond %[OK.]
      end
    end
  end
  
  t_took = Time.now.to_f - t_start
  if @user.attr[:DEBUG] == true
    o << %[took: #{t_took}\nused: #{@context.length}\ntask: #{@task}\ninfo: #{@info}]
    o << %[dm: #{@dm}]
    o << %[users: #{@users}]
    o << %[priv: #{@priv}]
    o << %[roles: #{@roles}]
    o << %[attachments: #{@attachments}]
  end
  
  o.each { |x| [x.split("\n")].flatten.uniq.each { |xx| if %[#{xx}].length > 0; e.respond(xx); end }}
  a.each { |x| [x.split("\n")].flatten.uniq.each { |xx| if %[#{xx}].length > 0; e.user.pm(xx); end }}
end
# fork and background

class APP < Sinatra::Base
  configure do
    set :bind, '0.0.0.0'
    set :port, 4567
    set :public_folder, 'public/'
    set :views, 'views/'
  end
  
  on_start { puts "[z4] running." }
  
  def die!
    Process.kill('TERM', Process.pid)
  end

  before do
    puts %[#{request.fullpath} #{request.user_agent} #{params}]
  end
  
  # handle dumb shit                                                                                                                                                                                                            
  ['robots.txt', 'favicon.ico'].each { |e| get("/#{e}") { }}
  
  # pwa requirement                                                                                                                                                                                                             
  get('/manifest.webmanifest') {
    content_type 'application/manifest+json'
    h = { name: request.host, shortname: request.host, display: 'standalone', start_url: %[https://#{request.host}/#{params[:route]}?user=#{params[:user]}&chan=#{params[:chan]}] }
    return JSON.generate(h)
  }                                                                                                                                                                      
  get('/service-worker.js') { content_type('application/javascript'); erb(:service_worker, layout: false) } 
  get('/') { erb :index }
  get('/:app') { erb params[:app].to_sym }
  # handle json post                                                                                                                                                                                                            
  post('/') {
    content_type = 'application/json'
    h = {}
    a = []
    op = false

    if params.has_key?(:lat) && params.has_key?(:lon)
      [:lat, :lon].each { |e| h[e] = params[e] }
      h[:grid] = Z4.to_grid(params[:lat],params[:log])
    end
    
    if params.has_key?(:user)
      u = Z4.make(params[:user], :user);
      u.stat.incr(:xp)
      u.stat.incr(:gp)
      if h.has_key? :grid
        u.grid.incr(h[:grid])
        u.attr[:lat] = params[:lat]
        u.attr[:lon] = params[:lon]
        u.attr[:grid] = h[:grid]
      end
      if params.has_key? :epoch
        u.epoch.incr(params[:epoch])
      end
      h[:user] = params[:user]
      [:xp, :gp, :lvl].each { |e| h[e] = u.stat[e] }
      [ :name, :nick, :age, :city, :since, :job, :union ].each { |e| h[e] = u.attr[e] }
      op = true
    end

    if params.has_key?(:chan)
      c = Z4.make(params[:chan], :chan);
      c.stat.incr(:xp)
      c.stat.incr(:gp)
      if h.has_key? :grid
        c.grid.incr(h[:grid])
      end
      if params.has_key? :epoch
        c.epoch.incr(params[:epoch])
      end      
      h[:chan] = params[:chan]
      [ :affiliate, :item ].each { |e| h[e] = c.attr[e] }
      op = true
    end
 
    if params.has_key?(:query)
      h[:query] = params[:query]
      if params[:query].split(" ").length > 1
        Z4.predefines.each_pair { |k,v|                                                                                                                                                                 
          if @matchdata = Regexp.new(k).match(params[:query].strip);
            a << %[<p class='i'>#{ERB.new(v).result(binding)}</p>];
          end
        }
      else
        #if params.has_key?(:user)
          #Z4.cortex(Z4.make(params[:user],:user).attr[:nick]).each { |e| a << %[<p class='i'>#{e}</p>] }
        #else
          #Z4.search(params[:query]).each { |e| a << %[<p class='i'>#{e}</p>] }
          hx = Z4.query[params[:query]].items.members(with_scores: true).to_h.sort_by { |k,v| -v }
          hx.to_h.each_pair { |k,v| a << %[<p class='c'><span class='material-icons' style='color: red;'>#{Z4.heart[Z4.lvl(v)]}</span><span class='box'>#{k}</span></p>] }
          Z4.tag[params[:query]].to_h.each_pair { |k,v|
            aa = [
              %[<span><span class='material-icons'>emoji_events</span><span>#{v[:won]}</span></span>],
              %[<span><span class='material-icons'>stars</span><span>#{v[:tagged]}</span></span>]
            ].join("")
            a << %[<p class='c'><span style='padding: 0 5% 0 0;'>#{Z4.make(k,:user).attr[:nick]}</span><span>#{aa}</span></p>]
          }
        #end
      end
      h[:items] = a.flatten.join('')
    end
    
    if params.has_key?(:input)
      h[:input] = params[:input]
      hhh = { batch: 256, ext: 0.1, info: 'Respond like User is a child.', task: 'Be helpful.', input: params[:input] }
      Z4.handle(hhh).each { |x| a << %[<p class='i'>#{x.strip.gsub(con, '')}</p>] }
      h[:output]= a.flatten.join('')
    end
    
    ################################## WORK
    return JSON.generate(h)
  }  
end

# initialize z4 databases
Z4.init!

# load local config
load 'z4.rb'

# start app and bot.
def server!
@app = Process.detach( fork { APP.start! } )
@bot = Process.detach( fork { BOT.run } )
end

# interact with data and monitor
def client!
  
  puts %[#####--- WELCOME! ---######]
end
