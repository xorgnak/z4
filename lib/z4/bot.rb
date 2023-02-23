module Z4Bot

  @@BOT = Discordrb::Bot.new token: ENV['DISCORD_TOKEN']
  @@CMD = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], prefix: '#'
  @@ON = Hash.new {|h,k| h[k] = lambda() { |e,x| puts "ON: #{k}" } }
  @@C = Hash.new {|h,k| h[k] = lambda() { |e,x| puts "C: #{k}" } }
  @@L = Hash.new {|h,k| h[k] = lambda() { |*a| puts "L: #{k}"} }
  @@F = Hash.new {|h,k| h[k] = lambda() { |*a| puts "F: #{k} #{a[1]}" } }
  @@M = {}
  @@H = {}

  def self.bot
    @@BOT
  end
  def self.cmd
    @@CMD
  end
  def self.[] k
    h = { bot: @@BOT, cmd: @@CMD }
    return h[k]
  end
  
  def self.msg e, h={}
    u = []; e.message.mentions.each {|ee| u << ee.name }
    r = []; e.message.role_mentions.each {|ee| r << ee.name }
    return {
      body: e.content.gsub(/<.*>/, ''),
      users: u,
      roles: r
    }.merge(h)
  end
  def self.on e, &b
    @@ON[e] = b
  end
  def self.ons
    @@ON
  end
  def self.macro k, v 
    @@M[k] = v
  end
  def self.macros
    @@M
  end
  def self.function k, &b
    @@F[k] = b
  end
  def self.functions
    @@F
  end
  def self.command c, h={}, &b
    @@H[c] = h
    @@C[c] = b
  end
  def self.commands
    @@C
  end
  def self.level k, &b
    @@L[k] = b
  end
  def self.levels
    @@L
  end
  def self.oauth
    %[#{@@BOT.invite_url}%20applications.commands&permissions=#{ENV['DISCORD_PERMISSIONS']}]
  end

  def self.owner
    @@BOT.bot_application.owner.id
  end
  def self.stop!
    #    @@BOT.stop
    begin
      @@CMD.stop
    rescue => e
      puts "BOT stop"
    end
  end
  def self.init!
#    @@BOT.mention() do |event|
#      x = Z4Bot.msg(event, action: :msg);
#      Z4Bot.ons[:mention].call(event, x)
#    end
    @@BOT.message() do |event|
      x = Z4Bot.msg(event, action: :msg);
      puts "MSG: #{event.methods}"
      Z4Bot.ons[:message].call(event, x)
    end
    @@C.each_pair do |k,v|
      @@CMD.command(k) { |e, *a|
#        puts "CMD: #{k} #{e} #{aZ4Badge.new(@app.id, @brand.id, @team.id, @user.id, @campaign.id).route('badge')}"
        x = Z4Bot.msg(e, cmd: k,
                      input: a,
                      from: e.user.name,
                      chan: e.channel.name
                     );
        v.call(e, x)
      }
    end
    @@CMD.run
  end
end

module Z4
  def self.handle ev, ro, h={}
    {
      role: ro,
      team: "#{h[:server]} ##{h[:chan]}"
    }.merge(h)
  end
end

#[:mention, :message].each do |type|
#  Z4Bot.on(type) do |event, params|
#    if @h = Z4.handle(event, 'everyone', params)
#      puts "#{type}: #{@h}"
#      event.respond "OK"
#    end
#  end
#end
Z4Bot.on(:message) do |event, params|
  puts "PM: #{params}"
  params[:command] = 'zyphr'
  params[:cmd] = params[:input][0]
  params[:input].shift
  params[:server] = 'localhost'
  params[:chan] = event.channel.name
  params[:from] = event.user.name
  r = []; event.user.roles.each {|e| r << e.name }
  params[:roles] = r
  bot_handle_setup event, '@everyone', params
  if @h[:cmd] == nil
    if ENV['DEBUG'] != 'false'
      @output << %[handle: #{@h}]
    end
    
    badge = Z4Badge.new(@app.id, @brand.id, @team.id, @user.id, @campaign.id)
    if @h[:roles].include? 'promotor'
      @output << %[[badge]]
      @output << badge.url('badge')
    end
    if @h[:roles].include? 'influencer'
      @output << %[[info]]
      @output << badge.url('plan')
    end
    
    if @h[:roles].include? 'ambassador'
      @output << %[[scanner]]
      @output << badge.url('scanner')
    end
    @output << %[abilities: #{Z4Bot.functions.keys}]
  else
    if @h[:cmd] != nil && Z4Bot.functions.has_key?(@h[:cmd].to_sym)
      @output << Z4Bot.functions[@h[:cmd].to_sym].call(event, @h)
    end
  end
  bot_debug
  event.user.pm(@output.join("\n"))
end

@help_ = [%[Thank you for reading the manual.  The z4 system is used to manage teams engaged in campaigns to facilitate brand development.  It has two major parts.  The discord bot, which manages the channel, host, brand, team, and user.  And the web host which provides qr badge generation and validation, and campaign reporting and information.],
          %[[*structure*]],
          %[The system is built around six user levels of responsibilities and access.  Users should get their level of server roles as well as those below that level.  Specialtiy roles should also be given to allow `@role` requests for services.],
          %[[*economy*]],
          %[A credit is valued at one visitor scan.  Each channel has it's own credit exchange rate. By default, one credit is equal to $1.  It's dollar value can be modified using the `#exchange` comand.],
          %[Credits can also be charged using the scanner interface byt managers and above.  It is hignly reccommeded for brands to accept credits.],
          %[[*planning*]],
          %[The plan interface is used to coordinate team members for campaign activities. The current campaign data elements are displayed as well as the gnatt chart of the campaign. Organizatonal information and success reporting is also here.]
         ]

@help = {
  objects: [
    %[The z4 system operates within a single discord channel and uses three basic objects, the channel itself, and a tool to interact with the web interface.],
    %[],
    %[*#my* the user.  Everyone has the ability to interact with these settings.],
    %[],
    %[*#brand* the brand represented by the channel. This can be set and interacted by an agent.],
    %[],
    %[*#campaign* the marketing focus of the channel. This can be set and interacted with by a manager.],
    %[],
    %[*#chan* the channel administration tool.  This can only be used by an operator.],
    %[],
    %[[*The `#z4` tool.*]],
    %[],
    %[The `#z4` tool is used to generate the qr badge used to generate visitor interactions.  It can also be used to set the random event source used to determine success during the visitor interaction.  By generating a random event using this tool, the team's random value is generated.  This value determines if a value generated by the same method in the visitor interaction is successful or not.]
  ],
  levels: [
    %[Everyone has access to the `#z4` tools. They provide utilities to be used for system tasks such as generating a random outcome or displaying interface links.],
    %[Each new level gains a new ability.  Some new levels can also set various data elements within the system.],
    %[],
    %[*#promotor* the ability to display a campaign badge.  Promotors are the backbone of the z4 system.  Every team member should be able to do the job of a promotor.],
    %[],
    %[*#influencer* set the team's place.  Places shold be coordinated with the team's operator and ambassador for greater effect. Influencers are used to focus the team's activities for public consumption.],
    %[],
    %[*#ambasador* set the team's campaign item.  The campaign item is the mechanism the team uses to further the goals of the campaign.  Ambassadors should be publically positively associated with the brand.  They can open the scanner interface to interact with campaign qr badges.],
    %[],
    %[*#manager* set a team's campaign.  The campaign are the overall goals of the team condensed into a single statement.],
    %[],
    %[*#agent* set a team's brand.  Each team can only represent one brand at a time. Agents function as go betweens for brands and teams.],
    %[],
    %[*#operator* set a team's domain.  Operators are responsible for keping everything running.  Brands should be represented under a domain with which signifigantly aligns. Operators may change this domain as necessary.  The localhost domain is only accessible for development and testing.]
  ],
  interfaces: [
    %[The z4 system provides two web interfaces.],
    %[*badge* a qr code which relays a visitor to the appropriate campaign.  Whem scanned, a visitor is sent to the campaign's interface which contains basic outside contact and referral information, as well as the campaign and item.],
    %[],
    %[*scanner* a tool to interact with qr badges.  This interface validates campaign qr codes.  User qr codes allow titles and badges to be given.  Credits can be given or taken using this tool aswell.],
    %[],
    %[*plan* an organizatonal breakdown of a campaign and reports about it's usage. The plan has the most currently available channel settings, a staged gnatt chart to display plan state, and charts for campaign data.],
    %[],
    %[These tools can be accessed using the `#z4` command in a channel.]
  ],
}

@man = {
  manual: "display the user manual.",
  z4: "interact with the server.",
  my: "set your data elements.",
  brand: "set the data elements of the brand.",
  campaign: "set the data elements of the campaign.",
  operator: "manage coordination resources.",
  agent: "set the channel brand.",
  manager: "set the channel campaign.",
  ambassador: "set the channel campaign item.",
  influencer: "set the channel location.",
  echo: "make the bot respond to you."
}

@usage = {
  manual: "#manual [topic]",
  z4: "#z4 [function] [*args]",
  my: "#my <key> <value>",
  brand: "#brand <key> <value>",
  campaign: "#campaign <key> <value>",
  operator: "#operator <domain>",
  agent: "#agent <brand>",
  manager: "#manager <campaign>",
  ambassador: "#ambassador <item>",
  influencer: "#influencer <place>",
  echo: "#echo <input>",
}

@info = {
  operator: ["operators set the channel domain.  This determines the domain used to generate links and what domain the brand is represented by."],
  agent: ["agents set the channel brand.  The brand is the organization the channel represents."],
  manager: ["managers set the channel campaign.  A campaign is the goal of the channel."],
  ambassador: ["ambasadors set the channel item.  Each campaign can have multiple items which can be used to further the campaign's goals."],
  influencer: ["influencers set the channel place.  This is used to coordinate the team's actions at a specific location."]
}

def bot_handle_setup e, l, p
  puts %[setup: #{e} #{l} #{p}]
  @h = Z4.handle(e, l, p)
  puts %[ready: #{@h}]
  @chan, @output = Z4.chan(@h[:chan]), []
  if ENV['DEBUG'] != 'false'
    @output << %[level: #{l}]
    @output << %[lvl: #{Z4.levels(l)}]
    @output << %[event: #{e}]
    @output << %[params: #{p}]
    @output << %[chan: #{@chan}]
    @output << %[----------]
  end

  @app = Z4[@chan[:host]]
  @brand = @app.brand[@chan[:brand]]
  @team = @brand.team[@chan.id]
  @user = @app.user[@h[:from]]
  @campaign = @team.campaign[@chan[:campaign]]
end

def bot_debug
  if ENV['DEBUG'] != 'false'
    @output << %[----------]
    @output << %[h: #{@h}]
    @output << %[app: #{@app.id}]
    @output << %[brand: #{@brand.id}]
    @output << %[team: #{@team.id}]
    @output << %[user: #{@user.id}]
    @output << %[campaign: #{@campaign.id}]
  end
end

##
# overwrite standard #help
Z4Bot.command(:help, description: "How to use this thing and what it is.", usage: "#help [topic]") do |event, params|
  params[:command] = 'help'
  params[:cmd] = params[:input][0]
  params[:input].shift
  params[:server] = 'localhost'
  params[:chan] = event.channel.name
  params[:from] = event.user.name
  r = []; event.user.roles.each {|e| r << e.name }
  params[:roles] = r
  bot_handle_setup event, '@everyone', params
  if @h[:cmd] != nil
    @output << %[usage: #{@usage[@h[:cmd].to_sym]}]
    @output << %[[what it does]]
    @output << @man[@h[:cmd].to_sym]
  else
    @output << %[For more info:\n`#help <command>`]
    @output << %[commands: #{@man.keys.join(', ')}]
  end
  bot_debug
  event.respond(@output.join("\n"))
  
end

##
# set team exchange rate.
# default: 1 = $1
# exchange sets the rate of exchange by team.
# if 1 = $5
# #exchange 0.2
# if 1 = $0.01
# #exchange 100
Z4Bot.command(:exchange, description: "set brand exchange rate.", usage: "#exchange <value>") do |event, params|
  params[:command] = 'exchange'
  params[:cmd] = 'excange'
  params[:server] = 'localhost'
  params[:chan] = event.channel.name
  params[:from] = event.user.name
  r = []; event.user.roles.each {|e| r << e.name }
  params[:roles] = r
  bot_handle_setup event, 'operator', params
  if @h[:roles].include?('operator') && params[:input].length == 1
    k = params[:input].shift
    @team[:exchange] = k
  end
  @output << %[current exchange rate: #{@team[:exchange]}]
  bot_debug
  event.respond(@output.join("\n"))
end

##
# channel admin
Z4Bot.command(:chan, description: "internal settings handler.", usage: "#chan <key> <value>") do |event, params|
  params[:command] = 'chan'
  params[:cmd] = 'chan'
  params[:server] = 'localhost'
  params[:chan] = event.channel.name
  params[:from] = event.user.name
  r = []; event.user.roles.each {|e| r << e.name }
  params[:roles] = r
  bot_handle_setup event, 'operator', params
  if @h[:roles].include?('operator')
    k = params[:input].shift
    v = params[:input].join(' ')
    @chan[k] = v
    @output << %[#{@team.id}[#{k}]: #{v}]
  else
    @output << %[usage: #op <key> <value>]
  end
  bot_debug
  event.respond(@output.join("\n"))
end

##
# credit payout by mention
Z4Bot.command(:give, description: "give credits to mentioned users", usage: "#give <amount> @mention...") do |event, params|
  params[:command] = 'give'
  params[:cmd] = 'give'
  params[:server] = 'localhost'
  params[:chan] = event.channel.name
  params[:from] = event.user.name
  r = []; event.user.roles.each {|e| r << e.name }
  params[:roles] = r
  bot_handle_setup event, 'manager', params
  if @h[:roles].include?('manager')
    @output << %[#{@user.id} gave:]
    a = params[:input][0]
    params[:users].each do |usr|
      @user.credit a
      @brand.debit a
      @output << %[- #{usr} #{a} #{@brand.id} #{@team.id} credits.]
    end
  else
    @output << %[usage: #give <amount> @mention...]
  end
  bot_debug
  event.respond(@output.join("\n"))
end

##
# user manual.
Z4Bot.command(:manual, description: "How to use this thing and what it is.", usage: @usage[:manual]) do |event, params|
  params[:command] = 'manual'
  params[:cmd] = params[:input][0]
  params[:input].shift
  params[:server] = 'localhost'
  params[:chan] = event.channel.name
  params[:from] = event.user.name
  r = []; event.user.roles.each {|e| r << e.name }
  params[:roles] = r
  bot_handle_setup event, '@everyone', params
  if @h[:cmd] != nil
    @output << @help[@h[:cmd].to_sym]
  else
    @output << @help_.join("\n")
    @output << %[[*more info*]]
    @output << %[Use the `#manual <section>` command to read more.]
    @output << %[sections: #{@help.keys.join(', ')}]
  end
  bot_debug
  event.respond(@output.join("\n"))
end

# can interact with the bot
Z4Bot.command(:z4, description: "the z4 plan administration tool.", usage: @usage[:z4]) do |event, params|
  puts "ZYPHR: "
  params[:command] = 'zyphr'
  params[:cmd] = params[:input][0]
  params[:input].shift
  params[:server] = 'localhost'
  params[:chan] = event.channel.name
  params[:from] = event.user.name
  r = []; event.user.roles.each {|e| r << e.name }
  params[:roles] = r
  bot_handle_setup event, '@everyone', params
  if @h[:cmd] == nil
    if ENV['DEBUG'] != 'false'
      @output << %[handle: #{@h}]
    end
    
    badge = Z4Badge.new(@app.id, @brand.id, @team.id, @user.id, @campaign.id)
    if @h[:roles].include? 'promotor'
      @output << %[[badge]]
      @output << badge.url('badge')
    end
    if @h[:roles].include? 'influencer'
      @output << %[[info]]
      @output << badge.url('plan')
    end
    if @h[:roles].include? 'ambassador'
      @output << %[[scanner]]
      @output << badge.url('scanner')
    end
    @output << %[abilities: #{Z4Bot.functions.keys}]
  else
    if @h[:cmd] != nil && Z4Bot.functions.has_key?(@h[:cmd].to_sym)
      @output << Z4Bot.functions[@h[:cmd].to_sym].call(event, @h)
    end
  end
  bot_debug
  event.user.pm(@output.join("\n"))
end

{
  brand: ['agent', [:desc, :contact, :link, :img, :button]],
  campaign: ['manager', [:body, :item]],
  my: ['@everyone', [:name, :title]]
}.each_pair do |type, keys|
  Z4Bot.command(type, description: "#{type} administration tool.", usage: @usage[type]) do |event, params|
    params[:command] = 'set'
    params[:cmd] = 'set'
    params[:server] = event.server.name
    params[:chan] = event.channel.name
    params[:from] = event.user.name
    r = []; event.user.roles.each {|e| r << e.name }
    params[:roles] = r
    bot_handle_setup(event, keys[0], params)
    puts "SET: #{type} #{keys} #{params}"
    if @h[:input].length > 0
      k = params[:input].shift
      v = params[:input].join(" ")
      if @h[:roles].include?(keys[0]) && keys[1].include?(k.to_sym)
        if type == :brand
          o = @brand
        elsif type == :campaign
          o = @campaign
        elsif type == :my
          o = @user
        end
        o[k.to_sym] = v
        @output << %[*#{@user.id}* -> #{type}[#{k}]: #{v}]
      else
        @output << %[you cannot set the #{type}[#{k}] data element.]
      end
    else
      @output << %[usage: #{@usage[type]}]
      @output << %[keys: #{keys[1].join(', ')}]
    end
    bot_debug
    event.respond(@output.join("\n"))
  end
end

Z4.levels[2..-1].each_with_index do |level, lvl|
  Z4Bot.command(level, description: "#{level} tool.", usage: @usage[level.to_sym]) do |event, params|
    params[:command] = level.to_s
    params[:cmd] = 'level'
    params[:server] = event.server.name
    params[:chan] = event.channel.name
    params[:from] = event.user.name
    r = []; event.user.roles.each {|e| r << e.name }
    params[:roles] = r
    bot_handle_setup(event, level, params)
    if @h[:input].length > 0
      @output << Z4Bot.levels[level].call(@h[:input])
    else
      @output << @usage[level]
      @output << @man[level]
      @output << @info[level].join("\n")
    end
    bot_debug
    event.respond(@output.join("\n"))
  end
end

Z4Bot.command(:echo, description: "print text to the channel.", usage: @usage[:echo]) do |event, params|
  params[:command] = 'echo'
  params[:cmd] = 'echo'
#  params[:server] = event.server.name
  params[:chan] = event.channel.name
  params[:from] = event.user.name
  r = []; event.user.roles.each {|e| r << e.name }
  params[:roles] = r
  bot_handle_setup event, '@everyone', params
  if @h[:roles].include? "operator"
    @output << ERB.new(event.content).result(binding)
  else
    @output << params[:input].join(' ')
  end
  bot_debug
  event.respond(@output.join("\n"))
end

##
# random output generators
Z4Bot.function(:roll) do |ev, params|
  if params[:input].length >= 2
    n = params[:input][0].to_i
    s = params[:input][1].to_i
    t = params[:input][2].to_i
    oo = []
    mt = "roll #{n} #{s} #{t}"
    x = 0
    d = []
    n.times { r = rand(s) + 1; x += r; d << r; }
    if x >= t
      r = :success
    else
      r = :failed
    end
    v = "#{r} #{x} <- #{d}"
    params[:users].each do |user|
      x, d = 0, []; n.times { r = rand(s) + 1; x += r; d << r; }
      if x > t
        r = :success
      else
        r = :failed
      end
      oo << "#{user} rolled #{n}d#{s} > #{t} for #{r} #{x} <- #{d}"
    end
    @campaign[:method] = mt
    @campaign[:value] = v
    ev.respond [%[method: #{mt}\nvalue: #{v}], oo].join("\n")
  else
    ev.user.pm "usage: roll <number> <sides> [plus] [success]"
  end
  %[OK #{params[:body]}]
end

Z4Bot.function(:cards) do |ev, params|
  if params[:input].length >= 1
    deck = []
    ["\u2661", "\u2662", "\u2664", "\u2667"].each {|face|
      (2..10).each {|e| deck << %[[#{e}#{face}]] }
      [:A, :J, :Q, :K].each {|e| deck << %[[#{e}#{face}]] }
    }
    if params[:input].length == 2
      params[:input][1].to_i.times {|e| deck << %[[\u2606]] }
    end
    deck.shuffle!
    oo = []
    m = "cards #{params[:input][0]} #{params[:input][1]}"
    v = []
    params[:input][0].to_i.times { v << deck.shift }
    params[:users].each do |user|
      d = []; params[:input][0].to_i.times { d << deck.shift }
      oo << "#{user}: #{d.join(' ')}"
    end
    @campaign[:method] = m
    @campaign[:value] = v
    ev.respond [%[method: #{m}\nvalue: #{v.join(' ')}], oo].join("\n")
  else
    ev.user.pm "usage: cards <number> [jokers]"
  end
  %[OK #{params[:body]}]
end

Z4Bot.function(:tarot) do |ev, params|
  def updn
    rand(2) == 0 ? "\u2191" : "\u2193"
  end
  if params[:input].length >= 1
    deck = []
    [:pentacles, :swords, :cups, :wands].each {|face|
      (2..10).each {|e| deck << %[[#{updn} #{e} of #{face}]] }
      [:ace, :page, :knight, :queen, :king].each {|e| deck << %[[#{updn} #{e} of #{face}]] }
    }
    [:fool, :juggler, :popess, :empress, :emperor, :pope, :lovers, :justice, :hermit,
     :wheel, :strength, :hanged, :death, :temperance, :devil, :house, :star, :moon,
     :sun, :judgement, :world].each_with_index { |e, i| deck << %[[#{updn} #{e} (#{i})]] }
    deck.shuffle!
    oo = []
    m = "tarot #{params[:input][0]}"
    v = []
    params[:input][0].to_i.times { v << deck.shift }
    params[:users].each do |user|
      d = []; params[:input][0].to_i.times { d << deck.shift }
      oo << "#{user}: #{d.join(' ')}"
    end
    @campaign[:method] = m
    @campaign[:value] = v
    ev.respond [%[method: #{m}\nvalue: #{v.join(' ')}], oo].join("\n")
  else
    ev.user.pm "usage: tarot <number>"
  end
  %[OK #{params[:body]}]
end

Z4Bot.function(:coin) do |ev, params|
  i = params[:input].join(" ")
  if /.* | .*/.match(i)
    ii = i.split(" | ")
    m = "coin #{i}"
    v = ii[rand(2)]
    @campaign[:method] = m
    @campaign[:value] = v
    ev.respond "method: #{m}\nvalue: #{v}"
  else
    ev.user.pm "usage: coin <heads> | <tails>"
  end
  %[OK #{params[:body]}]
end

Z4Bot.function(:pick) do |ev, params|
  if params[:users].length > 1
    m = "pick #{params[:users].join(' ')}"
    u = params[:users].sample
    @campaign[:method] = m
    @campaign[:value] = u
    ev.respond "method: #{m}\nvalue: #{u}"
  else
    ev.user.pm "usage: pick <@user> <user>..."
  end
  %[OK #{params[:body]}]
end

##
# standard member level abilities
{
  influencer: :place,
  ambassador: :item,
  manager: :campaign,
  agent: :brand,
  operator: :host
}.each_pair do |level, key|
  Z4Bot.level(level) do |input|
    v = input.join(" ")
    @chan[key] = v
    %[*#{level}* #{@user.id} -> #{key}: #{v}]
  end
end

