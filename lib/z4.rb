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

require 'git'

require 'astronomy'

require 'fortune'

require 'active_support'

require 'maiden'

require 'iww'

require 'remind'

Redis::Objects.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(:host => '127.0.0.1', :port => 6379) }

REDISEARCH = RediSearch::Index.new(:redisearch) { text_field :text }
REDISEARCH.create

module Z4  
  def self.redis
    Redis::Objects.redis
  end
  def self.flushdb
    Z4.redis.flushdb
  end
  def self.redisearch
    REDISEARCH
  end
end

class H
  def initialize(url)
    @url, @headers = url, {}
  end
  def headers h={}
    @headers = h
  end
  def get(r, h={})
    Faraday.new( url: @url, params: h, headers: @headers ).get("/#{r}", h)
  end
  def post(r, h={})
    Faraday.new( url: @url, params: h, headers: @headers ).post("/#{r}", h)
  end
end

module Z4
  @@API = Hash.new { |h,k| h[k] = H.new(k) }
  def self.api
    @@API
  end
end


Dir['lib/z4/*'].each do |e|
    puts %[loading #{e}];
    load(e);
end

BOT = Discordrb::Commands::CommandBot.new( token: ENV['Z4_DISCORD_TOKEN'], prefix: '#' )

BOT.message() do |e|
  Z4.message(e)
end

class APP < Sinatra::Base
  configure do
    set :bind, '0.0.0.0'
    set :port, 4567
    set :public_folder, 'public/'
    set :views, 'views/'
  end                                                                                                                                                                                                            
  ['robots.txt'].each { |e| get("/#{e}") { }}
  get('/manifest.webmanifest') {
    content_type('application/manifest+json');
    JSON.generate({ name: request.host, shortname: request.host, display: 'standalone', start_url: %[https://#{request.host}/#{params[:route]}?user=#{params[:user]}&chan=#{params[:chan]}] })
  }                                                                                                                                                                      
  get('/service-worker.js') { content_type('application/javascript'); erb(:service_worker, layout: false) }
  get('/cal/:c') { Z4.calendar(params[:c]) }
  get('/') { @q = rand(0..2); @z = rand(0..2); erb :index }
  get('/:app') { erb params[:app].to_sym }                                                                                                                                                                                
  post('/') {
    content_type = 'application/json'
    return JSON.generate(Z4.post(request, params))
  }  
end

# load local config
load 'z4.rb'

# start app and bot.
def init!
  @app = Process.detach( fork { APP.start! } )
  @bot = Process.detach( fork { BOT.run } )
end

