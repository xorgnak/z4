
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

    set :terms
    
    def initialize k
      @id = k
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

  @@HF = HuggingFace::InferenceApi.new(api_token: ENV['HUGGING_FACE_API_TOKEN'])

  def self.embedding *i
    @@HF.embedding(input: i)
  end

  def self.condense *i
    a = []
    [i].flatten.each { |ee| @@HF.summarization(input: ee).each { |e| a << e["summary_text"].strip } }
    return a
  end

  def self.expand *i
    a = []
    [i].flatten.each { |ee| @@HF.text_generation(input: ee).each { |e| a << e["generated_text"].strip } }
    return a
  end

  # process input.
  def self.handle h={}
    w = h[:input].split(" ")

    c = w[0]

    cmd = false
    
    puts %[handle h: #{h}]

    r = []
    
    @user = Z4.make h[:user], :user
    @chan = Z4.make h[:chan], :chan
    
    @@CANNED.each_pair { |k,v|
      #puts %[handle @@CANNED: #{k} #{v}]
      if @matchdata = Regexp.new(k).match(h[:input].strip);
        puts %[handle @matchdata: #{@matchdata}]
        r << ERB.new(v).result(binding);
        puts %[handle r: #{r}]
      end
    }
    
    
    if m = /^#(.+)!$/.match(c)
      cmd = true
      w.shift
      @chan.index id: m[1], text: %[#{m[1]}: #{w.join(" ")} per #{@user.attr[:name]} at #{Time.now.utc.strftime("%F %T")}]
      Z4.index id: m[1], text: %[#{m[1]}: #{w.join(" ")}]
      Z4.query.terms << m[1]
      r << %[#{m[1]} HEARD.]
    elsif m = /^#(.+)\?$/.match(c)
      w.shift
      puts %[handle ?: #{m[1]}]
      @chan.search(m[1]).each { |x| r << x }
      Z4.search(m[1]).each { |x| r << x }
    end
    
    puts %[handle R: #{r.length}]
    #if r.length == 0
    if cmd == false && w.length > 0
      hh = { batch: 256, ext: 0.1 }.merge(h)
      puts %[handle hh: #{hh}]
      p = %[#{hh[:info]}\n#{hh[:task]}\nUser: #{w.join(" ")}\nBot: ]
      puts %[handle p: #{p}]
      a = %[-b #{hh[:batch]} --rope-scaling yarn --yarn-ext-factor #{hh[:ext]}]
      puts %[handle a: #{a}]
      `llama #{a} -p "#{p}" 2> /dev/null`.gsub(p,"").strip.split("\n").each { |e| puts %[handle e: #{e}]; r << e }
    end
    #end
  
    puts %[handle return #{r}]
    return r
  end
  
  # llama prompt info getter/setter
  @@PERSONALITY = {}
  def self.personality k, v
    @@PERSONALITY[k] = v
  end
  
  # llama predefined response getter/setter
  @@CANNED = {}
  def self.canned k, v
    @@CANNED[k] = v
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
    # location
    value :grid
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
end

Dir['lib/z4/*'].each { |e| if !/^.*~$/.match(e); puts %[loading #{e}]; load(e); end }

###
### BOT
###


BOT = Discordrb::Commands::CommandBot.new token: ENV['Z4_DISCORD_TOKEN'], prefix: '#'

BOT.message() do |e|
  t_start, o, @cmd, @act = Time.now.to_f, [], nil, false
  
  @user = Z4.make(%[#{e.user.id}], :user)
  @chan = Z4.make(%[#{e.channel.id}], :chan)

  if @user.attr[:stats] == true
    [:xp, :gp, :lvl].each { |x| o << %[STAT #{x} #{@user.stat[x].to_f}] }
  end
  
  if @user.attr[:item] != nil
    @item = Z4.make @user.attr[:item], :item
  end
  
  if @chan.attr[:object] != nil
    @object = Z4.make @chan.attr[:object], :object
  end

  if @user.attr[:place] != nil
    @place = Z4.make @user.attr[:place], :place
  end

  if @chan.attr[:topic] != nil
    @topic = Z4.make @chan.attr[:topic], :item
  end
  
  @text = e.message.text
  @words = []
  @text.split(" ").each { |x| if !/<.+>/.match(x); @words << x; end }
  @text = @words.join(" ")
 
  if e.user.name == e.channel.name
    @dm = true
  else
    @dm = false
  end
  if @user.attr[:DEBUG] == true
    o << %[dm: #{@dm}]
  end

  @priv = []; e.user.roles.each { |x| @priv << x.name }
  if @user.attr[:DEBUG] == true
    o << %[priv: #{@priv}]
  end
  
  @roles = []; e.message.role_mentions.each { |x| @roles << x.name }
  if @user.attr[:DEBUG] == true
    o << %[roles: #{@roles}]
  end

  @users = []; e.message.mentions.each { |x| @users << Z4.make(%[#{x.id}], :user) }
  if @user.attr[:DEBUG] == true
    o << %[users: #{@users}]
  end
  
  @attachments = []; e.message.attachments.each { |x|
    @attachments << x.url
  }
  if @user.attr[:DEBUG] == true
    o << %[attachments: #{@attachments}]
  end

  if !/^.+\?$/.match(@words[0]) && !/^.+!$/.match(@words[0])
    # first pass handling
    if m = /##(.+)/.match(@words[0])
      ###
      ### CHANOPS
      ###
      @act = true
      @cmd = m[1]
      puts %[CMD: #{@cmd}]
      @words.shift
      @text = @words.join(" ")
      if @priv.include?('agent') || @priv.include?('operator')
        @chan.attr[@cmd.to_sym] = @text
        o << %[CHANOP #{@cmd} #{@text}]
      else 
        o << %[## Must be an agent or operator to do that.]
      end
    elsif m = /#(.+)/.match(@words[0])
      ###
      ### USEROPS
      ###
      @act = true
      @cmd = m[1]
      puts %[cmd: #{@cmd}]
      @words.shift
      @text = @words.join(" ")
      if @cmd == "#"
        ###
        ### CHANID
        ###
        @chan.attr.to_h.each_pair { |k,v| o << %[#{k}: #{v}] }
      else
        @user.attr[@cmd.to_sym] = @text
        e.user.pm %[Set #{@cmd} to #{@text}]
      end
    elsif @words[0] == "#"
      ###
      ### USERID
      ###
      @act = true
      @user.attr.to_h.each_pair { |k,v| e.user.pm %[#{k}: #{v}] }
      if @chan.attr[:affiliate] != nil
        e.user.pm %[https://#{@chan.attr[:affiliate]}/?user=#{@user.id}&chan=#{@chan.id}]
      end
    end
  end
  
  # handle attribute requirements
  Z4.require.each_pair do |k,v|
    if @user.attr[k] == nil
      e.user.pm %[REQUIRED: #{v}]
    end
  end


  @h = { input: @text, user: @user.id, chan: @chan.id }

  
  if @cmd == nil && @text.length > 0
    @context = [ %[Communication in the #{@chan.attr[:name]} channel is for #{@chan.attr[:purpose]}.] ]

    #@context << %[The time is #{Time.now.utc} and User's local offset from utc is #{Time.now.utc_offset}.]
    
    @context << %[User's name is #{@user.attr[:name]} and is #{@user.attr[:age]} years old.]

    @context << %[User has lived in #{@user.attr[:city]} since #{@user.attr[:since]}.]

    if @user.attr[:union] != nil
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
      Z4.handle(@h).each { |x| puts %[handle x: #{x}]; o << x.strip.gsub(@context.join(" "),'') }
    end
  else
    if @act == false
      e.respond(%[Let me think...])
      @h[:info] = @context.join(" ")
      @h[:task] = @chan.attr[:task] || %[Respond to User.  Be helpful.]
      @h[:batch] = @chan.attr[:batch].to_i
      @h[:ext] = @chan.attr[:ext].to_i
      @hh = { batch: 256, ext: 0.1 }.merge(@h)
      Z4.handle(@hh).each { |x| puts %[handle x: #{x}]; o << x.strip.gsub(@context.join(" "), '') }
    else
      e.respond %[OK.]
    end
  end
  
  t_took = Time.now.to_f - t_start
  if @user.attr[:DEBUG] == true
    o << %[took: #{t_took}\nused: #{@context.length}\ntask: #{@task}\ninfo: #{@info}]
  end
  
  a = []
  puts %[BOT o: #{o}]
  o.each { |x| [x.split("\n")].flatten.uniq.each { |xx| if %[#{xx}].length > 0; e.respond(xx); end }}
end
# fork and background

class APP < Sinatra::Base
  configure do
    set :bind, '0.0.0.0'
    set :port, 4567
    set :public_folder, 'public/'
    set :views, 'views/'
  end
  on_start { puts "[z4app] OK." }
  
  def die!
    Process.kill('TERM', Process.pid)
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
    if params.has_key?(:lat) && params.has_key?(:lon)
      h[:grid] = Z4.to_grid(params[:lat],params[:long])
    end
    if params.has_key?(:query)
      o = []
      Z4.search(m[1]).each { |x| o << %[<p><span>#{x}</span></p>] }
      h[:items] = o.join("")
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
