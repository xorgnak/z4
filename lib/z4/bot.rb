module Z4
  def self.message e
    @o, @a, @e, @t_start, @cmd, @act, @ok, @amt, @legal = [], [], e, Time.now.to_f, nil, false, true, 0, false

    @context = []
    
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
    

    if /^#.+/.match(@words[0])
      puts %[#################]
      if !/^.+\?$/.match(@words[0]) && !/^.+!$/.match(@words[0])
        puts %[datapoint]
        if m = /##(.+)/.match(@words[0])
          puts %[chan set]
          @act = true
          @cmd = m[1]
          @words.shift
          @text = @words.join(" ")
          if @priv.include?('agent') || @priv.include?('operator')
            if @cmd == "#"
              @o << %[#{Bubble.new(@user.id).instance_eval(@text)}]
            else
              @chan.attr[@cmd.to_sym] = @text
              @a << %[CHANOP #{@e.channel.name} #{@cmd} #{@text}]
            end
          else
            @a << %[## Must be an agent or operator to do that.]
          end
        elsif m = /#(.+)/.match(@words[0])
          puts %[user set]
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
            #if @cmd == 'age'
            #  if @text.to_i <= @chan.attr[:age].to_i
            #    @a << %[No. Go home. Stay off of the internet. Get good grades in school.  And don't smoke cigarettes!]
            #  else
            #    if @user.attr[:age] == nil
            #      @user.attr[@cmd.to_sym] = @text
            #      @a << %[Happy Birthday. Here's 50gp. You should probably also call your mom.]
            #      @user.stat.incr(:xp)
            #      @user.stat.incr(:gp,50)
            #    else
            #      @a << %[I'm sorry. I can't do that You must be at least #{@chan.attr[:age]} years old to use this channel.]
            #    end
            #  end
            #else
              #if @user.attr[:age] != nil
                @user.attr[@cmd.to_sym] = @text
              #else
                #@a << %[I'm sorry. I can't do that You must be at least #{@chan.attr[:age]} years old to join this channel.]
              #end
            #end
            
#            if @cmd == 'area'
#              @user.attr[:zone] = "#{@user.attr[:area]},#{@chan.attr[:city]},#{@chan.attr[:state]}"
#              WIKI[@user.attr[:zone]];
#              if WIKI.gps.has_key?(@text)
#                @a << %[Your city (#{@user.attr[:zone]}) is a real city!\nHere's 20gp because I know things are expensive there.]
#                @user.stat.incr(:xp)
#                @user.stat.incr(:gp,20)
#              end
#            end
            
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
      else
        puts %[dataset]
        if m = /^#(.+)\?$/.match(@words[0])
          puts "get #{m[1]}"
          @act = true
          tag = m[1]
          @words.shift
          @text = @words.join(" ")
          c = []

          
          
          @o << c
          
        elsif m = /^#(.+)!$/.match(@words[0])
          puts "set #{m[1]} #{m[2]}"
          @words.shift
          @text = @words.join(" ")
          puts "SET #{@text}"
          @act = true
          mx = m[1].split("-")
          tag = mx[0]
          mx.shift
          if TAG.safe.include? tag
            #TAG[tag].mark(@text, @user.id)
            QUERY[tag] << @text
            @o << %[HEARD #{tag} #{mx[0]} #{mx[1]}]
            @users.each do |ee|
              if "#{mx[0]}".length > 0
                if TAG.safe(tag).include?(mx[0])
                  if "#{mx[1]}".length > 0
                    if TAG.award(tag).include?(mx[1])
                      TAG[tag].award(@text, ee, mx[0], mx[1])
                    else
                      @o << %[Bad award: #{mx[1]}\nAcceptable awards are: #{TAG.award(tag).join(", ")}]
                    end
                  else
                    TAG[tag].win(@text, ee, mx[0])
                  end
                else
                  @o << %[Bad category: #{mx[0]}\nAcceptable awards are: #{TAG.safe(tag).join(", ")}]
                end
              else
                TAG[tag].mark(@text, ee)
              end
              if @amt > 0
                Z4.xfer from: h[:user], to: ee, amt: @amt, memo: "tag: #{tag}, category: #{mx[0] || 'none'} award: #{mx[1] || 'none'}, note: #{@text}"
              end
              TAG[tag].mark(@text, @user.id)
            end
            @o << %[TAG: #{m[1]}\nWHEN: #{Time.now.utc}\nWHAT: #{@text}\nPROOF:\n#{@attachments.join("\n")}]
          else
            @o << %[Bad tag: #{tag}\nAcceptable tags are: #{TAG.safe.join(", ")}]
          end    
        end
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

    if @user.attr[:DEBUG] == "true"
      [%[BOT: #{@cmd}],%[ok: #{@ok}],%[act: #{@act}],%[dm: #{@dm}],%[text: #{@text}],%[context: #{@context}]].each { |e| @e.respond(e) }
    end
    
    if @ok == true || @words[0] == "z4:"
      if @words[0] == "z4:"
        @words.shift
        @text = @words.join(" ")
      end
      oo = [%[Let me think about that...]]
      if @user.attr[:DEBUG] == "true"
        oo << %[cmd: #{@cmd}]
        oo << %[ok: #{@ok}]
        oo << %[act: #{@act}]
        oo << %[dm: #{@dm}]
        oo << %[text: #{@text}]
        oo << %[context: #{@context}]
      end
      @e.respond(oo.join("\n"))
      h = LLAMA[@chan.id] << %[#{@context.join("\n")} #{@text}]    
      h[:context].each_pair { |k,v| @o << %[If #{k} is #{v}.] }
      @o << %[#{h[:mood]} #{h[:output]}]
    end      
    
    @t_took = Time.now.to_f - @t_start

    if @user.attr[:DEBUG] == "true"
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
