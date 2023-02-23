module Z4App
  class Error < StandardError; end
  class App < Sinatra::Base
    configure do
      set :bind, '0.0.0.0'
      set :port, 4567
      set :public_folder, "#{Dir.pwd}/public"
      set :views, "#{Dir.pwd}/views"
    end

    helpers do
      def valid?
        [:brand, :team, :user, :campaign].each {|e| if !params.has_key?(e); return false; end }
        @app = Z4[@host]
        @brand = @app.brand[params[:brand]]
        @team = @brand.team[params[:team]]
        @user = @app.user[params[:user]]
        @campaign = @team.campaign[params[:campaign]]
      end
      def tick!
        @user.incr(:campaigns, @campaign.id)
        @user.incr(:teams, @team.id)
        @user.incr(:brands, @brand.id)
        @team.incr(:promotors, @user.id)
        @team.incr(:campaigns, @campaign.id)
        @brand.incr(:teams, @team.id)
        @brand.incr(:promotors, @user.id)
        @brand.incr(:campaigns, @campaign.id)
        @app.incr(:brands, @brand.id)
        @app.incr(:teams, @team.id)
        @app.incr(:users, @user.id)
        @app.incr(:campaigns, @campaign.id)
        @user.credit @brand.exchange(@user.level)
        @brand.debit @brand.exchange(@user.level)
      end
      def debug *s
        if ENV['DEBUG'] != true
          puts %[request #{@host} #{request.query_string}]
          puts %[browser #{@browser}]
          puts %[A: #{@app}]
          puts %[B: #{@brand}]
          puts %[T: #{@team}]
          puts %[U: #{@user}]
          puts %[C: #{@campaign}]
          [s].flatten.each {|e| puts e }
        end
      end
      def fingerprint
        b = Browser.new(request.user_agent, accept_language: "en-us")
        return {
          dev_id: b.device.id,
          dev: b.device.name,
          platform_id: b.platform.id,
          platform: b.platform.name,
          browser: b.name,
          vrsion: b.full_version
        }
      end
    end
    
    before do
      @host = request.host
    end

    get('/favicon.ico') {}

    # background service worker
#    get('/sw.js') { erb :service_worker }

    # css
#    get('/theme.css') { erb :theme }

    # usage interfaces scannable / scanner / landing.
    get('/') {
      @app = Z4[@host]
      erb :index
    }
    
    get('/badge') {
      if valid?
        erb :badge
      end
    }
    
    get('/scanner') {
      if valid?
        erb :scanner
      end
    }
    
    # outside interactions
    # brand, team, user, campaign
    ##
    # team organization
    get('/plan') {
      if valid?
        erb :plan
      end
    }
    
    # badge scan interaction
    get('/scan') {
      if valid?
        tick!
        x = []; 6.times { x << rand(16).to_s(16) };
        @x = x.join('')
        @v = Z4Visit.new(@app.id, @brand.id, @team.id, @user.id, @campaign.id, @x)
        @v['fingerprint'] = fingerprint
        @v.credit
        debug %[@x: #{@x}], %[@v: #{@v} #{@v['fingerprint']}]
        erb :campaign
      end
    }

    # form submit
    post('/') {
      puts "POST: #{params}"
      @app = Z4[@host]
      @goto = request.fullpath
      if params.has_key? 'give'
        @u = @app.user[params['give']['user']]
        @b = @app.brand[params['brand']]
        @t = @b.team[params['team']]
        ['badges', 'titles'].each do |e|
          if params['give'].has_key? e
            puts "#{e}: #{params[e]}"
            @u.incr(e, params[e])
          end
          @u.credit(params['give']['credits'])
          @b.debit(params['give']['credits'])
          puts "credits: #{params['give']['credits']}"
        end
      end
      # synchronous post / redirect
      redirect %[#{params['goto']}]
    }
    
    # form push
    post('/async') {
      content_type 'application/json'
      @h = {}
      # async post / return json
      return JSON.generate(@h)
    }
    
    post('/scan') {
      if valid?
        content_type 'application/json'
        @h = {}
        
        # async post / return json
        return JSON.generate(@h)
      end
    }
    
  end
  def self.stop!
    begin
      App.quit!
    rescue => e
      puts "APP stop"
    end
  end
  def self.init!
    App.run!
  end
end
