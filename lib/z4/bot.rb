module Z4
  def self.message e
    @o, @a, @e, @t_start, @cmd, @act, @ok, @amt, @legal = [], [], e, Time.now.to_f, nil, false, true, 0, false
    
    @user = OBJ[:user][%[#{@e.user.id}]]
    @chan = OBJ[:chan][%[#{@e.channel.id}]]

    @context = []
    
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
  
    if /^#.+/.match(@words[0])
      puts %[#################]
      if !/^.+\?$/.match(@words[0]) && !/^.+!$/.match(@words[0])
        puts %[datapoint]
        if m = /##(.+)/.match(@words[0])
          puts %[chan set]
          @ok = false
          @cmd = m[1]
          @words.shift
          @text = @words.join(" ")
          if @priv.include?('agent') || @priv.include?('operator')
            if @cmd == "#"
              @o << %[#{Bubble.new(@user.id).instance_eval(@text)}]
            else
              @chan.attr[@cmd.to_sym] = @text
              @a << %[[CHANOP][#{@e.channel.name}]##{@cmd} #{@text}]
            end
          else
            @a << %[## Must be an agent or operator to do that.]
          end
        elsif m = /#(.+)/.match(@words[0])
          puts %[user set]
          @ok = false
          @act = true
          @cmd = m[1]
          @words.shift
          @text = @words.join(" ")
          if @cmd == "#"
            if @chan.attr[:affiliate] != nil
              @a << %[https://#{@chan.attr[:affiliate]}/qr?user=#{@user.id}&chan=#{@chan.id}&epoch=#{Time.now.utc.to_i}]
            else
              @a << %[## An affiliate must be set to generate a qr badge.]
            end
          else
            @ok = false
            @act = true
            @user.attr[@cmd.to_sym] = @text
            
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
          [:xp, :gp, :lvl].each { |x| @a << %[#{x}: #{@user.stat[x].to_f}] }
          @user.attr.to_h.each_pair { |k,v| @a << %[##{k} #{v}] }
        end
      else
        puts %[dataset]
        if m = /^#(.+)\?$/.match(@words[0])
          puts "get #{m[1]}"
          tag = m[1]
          @words.shift
          @text = @words.join(" ")
          # ADD: WIKI, BOOK
          @context << %[known #{tag} at #{TAG[tag].keys.uniq.insert(-2, "and").join(", ")}.]
        elsif m = /^#(.+)!$/.match(@words[0])
          @words.shift
          @text = @words.join(" ")
          @ok = false
          mx = m[1].split(">")
          tag = mx[0]
          sub = mx[1]
          pip = mx[2]
#          QUERY[mx[0]] << @text
          TAG[tag].mark(tag: @text, user: @user.id)
          @users.each do |ee|
            if sub
              if pip
                TAG[tag].award(tag: @text, user: ee, category: sub, award: pip)
              else
                TAG[tag].win(tag: @text, user: ee, category: sub)
              end
            end
            if @amt > 0
              Z4.xfer from: @user.id, to: ee, amt: @amt, memo: "#{tag}: #{@text}"
            end
          end
          @o << %[TAG: #{m[1]}\nWHEN: #{Time.now.utc}\nWHAT: #{@text}\nPROOF:\n#{@attachments.join("\n")}]
        end
      end
    end

    if @dm == false
      Z4.chan.each_pair do |k,v|
        if @act == true && @ok == true && @chan.attr[k] == nil
          @ok = false
          @o << %[CHANNEL REQUIREMENT\n#{v}]
        end
      end
    end

    Z4.user.each_pair do |k,v|
      if @act == true && @ok == true && @user.attr[k] == nil
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
    
    if @words[0] == "z4:"
      if @words[0] == "z4:"
        @words.shift
        @text = @words.join(" ")
        ev = EVENT[@text]
        if ev.event?
          @ok = false
          if @dm == false
            Remind.set(%[#{@chan.id}], @text)
          end
          Remind.set(%[#{@user.id}], @text)
          @o << %[I'll remember #{@text}]
        end
      end
    end

    @context << Remind.get(@user.id)
    @context << Remind.get(@chan.id)
    @context << Meiou[@text]

    @context.flatten!
    @context.uniq!
    
    if @user.attr[:DEBUG] == "true"
      [%[| DEBUG: PRE | #{@cmd} | #{@ok} | #{@act} | #{@dm} | #{@text}],
       %[| #{@context}]].each { |e| @e.respond(e) }
    end
    
    if @ok == true
      @e.respond [%[Let me think about that...], @context,].flatten.uniq.join("\n")  
      if @dm == true
        @o << Llamafile.llama(%[#{@context.join("\n")}\n#{@text}\n])[:output]
      else
        @o << Meiou[@text]    
      end
    end
    
    @t_took = Time.now.to_f - @t_start
    
    if @user.attr[:DEBUG] == "true"
      @o << %[| DEBUG: POST | #{@t_took} | #{@context.length} | #{@task} #{@info} #{@dm}]
      @o << %[| #{@users} | #{@priv} | #{@roles}]
      @o << %[| #{@attachments}]
    end
    
    @o.each { |x| [x.split("\n")].flatten.uniq.each { |xx| if %[#{xx}].length > 0; @e.respond(xx); end }}
    @a.each { |x| [x.split("\n")].flatten.uniq.each { |xx| if %[#{xx}].length > 0; @e.user.pm(xx); end }}    
  end
end
