module Z4
  def self.message e
    @o, @a, @e, @t_start, @cmd, @act, @ok, @amt, @legal = [], [], e, Time.now.to_f, nil, false, true, 0, false
    
    @user = OBJ[:user][%[#{@e.user.id}]]
    @chan = OBJ[:chan][%[#{@e.channel.id}]]
    
    @text = @e.message.text
    @words = []
    @text.split(" ").each { |x| if !/<.+>/.match(x); @words << x; elsif m = /(.+)gp/.match(x); @amt = m[1].to_f; end }
    @text = @words.join(" ")
    
    if @e.user.name == @e.channel.name
      @dm = true
    else
      @dm = false
    end
    
    @priv = []; @e.user.roles.each { |x| @priv << x.name }
    
    @roles = []; @e.message.role_mentions.each { |x| @roles << x.name }
    
    @users = []; @e.message.mentions.each { |x|
      @users << %[#{x.id}] }
    
    @attachments = []; @e.message.attachments.each { |x|
      @attachments << x.url
    }
    
    if @user.attr[:DEBUG] == true
      @o << %[dm: #{@dm}]
      @o << %[users: #{@users}]
      @o << %[priv: #{@priv}]
      @o << %[roles: #{@roles}]
      @o << %[attachments: #{@attachments}]
    end
   
    if !/^.+\?$/.match(@words[0]) && !/^.+!$/.match(@words[0])
      if m = /##(.+)/.match(@words[0])
        @act = true
        @cmd = m[1]
        @words.shift
        @text = @words.join(" ")
        if @priv.include?('agent') || @priv.include?('operator')
          @chan.attr[@cmd.to_sym] = @text
          @a << %[CHANOP #{@e.channel.name} #{@cmd} #{@text}]
        else
          @a << %[## Must be an agent or operator to do that.]
        end
      elsif m = /#(.+)/.match(@words[0])        
        @act = true
        @cmd = m[1]
        @words.shift
        @text = @words.join(" ")
        if @cmd == "#"
          @act = true
          if @chan.attr[:affiliate] != nil
            @a << %[https://#{@chan.attr[:affiliate]}/qr?user=#{@user.id}&chan=#{@chan.id}&epoch=#{Time.now.utc.to_i}]
          end
        elsif @cmd == "##WIKI"
          @act = true
          @a << WIKI[@text]
        elsif @cmd == "##INFO"
          @act = true
          @a << INFO[@text]
        elsif @cmd == "##BOOK"
          @act << true
          @a << BOOK[@text]
        else
          if @cmd == 'age'
            if @text.to_i <= @chan.attr[:age].to_i
              @a << %[No. Go home. Stay off of the internet. Get good grades in school.  And don't smoke cigarettes!]
            else
              if @user.attr[:age] == nil
                @user.attr[@cmd.to_sym] = @text
                @a << %[Happy Birthday. Here's 50gp. You should probably also call your mom.]
                @user.stat.incr(:xp)
                @user.stat.incr(:gp,50)
              else
                @a << %[I'm sorry. I can't do that You must be at least #{@chan.attr[:age]} years old to use this channel.]
              end
            end
          else
            if @user.attr[:age] != nil
              @user.attr[@cmd.to_sym] = @text
            else
              @a << %[I'm sorry. I can't do that You must be at least #{@chan.attr[:age]} years old to join this channel.]
            end
          end
          
          if @cmd == 'area'
            @user.attr[:zone] = "#{@user.attr[:area]},#{@chan.attr[:city]},#{@chan.attr[:state]}"
            WIKI[@user.attr[:zone]];
            if WIKI.gps.has_key?(@text)
              @a << %[Your city (#{@user.attr[:zone]}) is a real city!\nHere's 20gp because I know things are expensive there.]
              @user.stat.incr(:xp)
              @user.stat.incr(:gp,20)
            end
          end
          
          if @cmd == 'job'
            if x = Iww[@text]
              @a << %[Did you know that there's a #{@text} union?]
              x.each_pair { |k,v| @a << %[The I.W.W. #{k} #{v} Workers.] }
              @a << %[If you're already a union member respond with '#union UNION'.]
              @a << %[If not, you can sign up at https://redcard.iww.org/user/register]
              @a << %[No pressure but workers are stronger together. :heart:]
            end
          end          
          
          if @cmd == 'union'
            @a << %[Union proud! I'll give you 25gp, for membership dues.]
            @user.stat.incr(:xp)
            @user.stat.incr(:gp,25)
          end

          if @cmd == 'img'
            @a << %[Updating one's image is a always important. Here's 5gp. Good job.]
            @user.stat.incr(:xp)
            @user.stat.incr(:gp,5)
          end

          if @cmd == 'store'
            @a << %[Designer merchandising enhances brand appeal.]
            @user.stat.incr(:xp)
            @user.stat.incr(:gp)
          end
          
          if @cmd == 'social'
            @a << %[Build your brand through social media credibility.]
            @user.stat.incr(:xp)
            @user.stat.incr(:gp)
          end

          if @cmd == 'tips'
            @a << %[Social tipping can be an excellent way to augment your brand's presence.]
            @user.stat.incr(:xp)
            @user.stat.incr(:gp)
          end

          if @cmd == 'phone'
            @a << %[Direct contact is always best.]
            @user.stat.incr(:xp)
            @user.stat.incr(:gp)
          end

          if @cmd == 'embed'
            @a << %[Embedding content directly is a great way to establish your brand.]
            @user.stat.incr(:xp)
            @user.stat.incr(:gp)
          end

          @a << %[Set #{@cmd} to #{@text}]
        end
      elsif @words[0] == "#"
        @act = true
        [:xp, :gp, :lvl].each { |x| @a << %[#{x}: #{@user.stat[x].to_f}] }
        @user.attr.to_h.each_pair { |k,v| @a << %[##{k} #{v}] }
      end
    end

    if @dm == false
      Z4.chan.each_pair do |k,v|
        if @ok == true && @chan.attr[k] == nil
          @ok = false
          @o << %[CHANNEL REQUIREMENT\n#{v}]
        end
      end
    end
    
    Z4.user.each_pair do |k,v|
      if @ok == true && @user.attr[k] == nil
        @ok = false
        @o << %[PROFILE REQUIREMENT\n#{v}]
      end
    end

    Z4.injection.each { |e|
      if @matchdata = Regexp.new(e).match(@text);
        @text = Z4.injection(e)
      end
    }
    
    Z4.canned.each { |e|
      if @matchdata = Regexp.new(e).match(@text);
        @ok = false
        @o << Z4.canned(e)
      end
    }
    
    @h = { input: @text, user: %[#{@e.user.id}], chan: %[#{@e.channel.id}], users: @users, roles: @roles, priv: @priv, attachments: @attachments }
    
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
          Z4.handle(@h).each { |x| @o << x.strip.gsub(@context.join(" "),'') }
        end
      else
        if @act == false
          @e.respond(%[Let me think...])
          @h[:info] = @context.join(" ")
          @h[:task] = @chan.attr[:task] || %[Respond to User.  Be helpful.]
          @h[:batch] = @chan.attr[:batch].to_i
          @h[:ext] = @chan.attr[:ext].to_i
          @hh = { batch: 256, ext: 0.1 }.merge(@h)
          Z4.handle(@hh).each { |x| @o << x.strip.gsub(@context.join(" "), '') }
        else
          @e.respond %[OK.]
        end
      end
    end      
    
    @t_took = Time.now.to_f - @t_start
    if @user.attr[:DEBUG] == true
      @o << %[took: #{t_took}\nused: #{@context.length}\ntask: #{@task}\ninfo: #{@info}]
      @o << %[dm: #{@dm}]
      @o << %[users: #{@users}]
      @o << %[priv: #{@priv}]
      @o << %[roles: #{@roles}]
      @o << %[attachments: #{@attachments}]
    end
  @o.each { |x| [x.split("\n")].flatten.uniq.each { |xx| if %[#{xx}].length > 0; @e.respond(xx); end }}
  @a.each { |x| [x.split("\n")].flatten.uniq.each { |xx| if %[#{xx}].length > 0; @e.user.pm(xx); end }}    
  end
end
