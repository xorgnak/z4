module Z4
  def self.handle h={}
    w = h[:input].split(" ")
    c = w[0]
    cmd = false
    puts %[handle h: #{h}]
    r = []
    @user = OBJ[:user][h[:user]]
    @chan = OBJ[:chan][h[:chan]]
    if m = /^#(.+)!$/.match(c)
      cmd = true
      w.shift
      
      mx = m[1].split("-")
      tag = mx[0]
      mx.shift
      if TAG.safe.include? tag
        i = %[#{@chan.attr[:name].gsub(" ","_")}-#{@user.attr[:nick].gsub(" ","_")}-#{m[1]}]
        s = %[#{m[1]}: #{w.join(" ")} per #{@user.attr[:nick]} at #{Time.now.utc.strftime("%F %T")}]
        
        TAG[tag].tag(:user,h[:user])
        QUERY[tag].items.incr(w.join(" "))
        TAG["local"].tag(:user, h[:user], tag, "best")
        
        ["best", tag].each { |e| QUERY[e].items.incr(w.join(" ")) }
        
        if "#{mx[0]}".length > 0
          if TAG.safe(tag).include? mx[0]
            TAG[tag].tag(:user, h[:user],mx[0])
            QUERY[mx[0]].items.incr(w.join(" "))
            if "#{mx[1]}".length > 0
              if TAG.award(tag).include? mx[1]
                TAG[tag].tag(:user, h[:user], mx[0], mx[1])
                QUERY[mx[1]].items.incr(w.join(" "))
              else
                r << %[Bad award: #{mx[1]}\nAcceptable awards are: #{TAG.award(tag).join(", ")}]
              end
            end
          else
            r << %[Bad tag: #{mx[0]}\nAcceptable awards are: #{TAG.safe(tag).join(", ")}]
          end
        end
        
        h[:users].each do |ee|
          if "#{mx[0]}".length > 0
            if TAG.safe(tag).include? mx[0]
              TAG[tag].tag(:user, ee, mx[0])
              QUERY[mx[0]].items.incr(w.join(" "))
              if "#{mx[1]}".length > 0
                if TAG.award(tag).include? mx[1]
                  TAG[tag].tag(:user, ee, mx[0], mx[1])
                  QUERY[mx[1]].items.incr(w.join(" "))
                else
                  r << %[Bad mention award: #{mx[1]}\nAcceptable awards are: #{TAG.award(tag).join(", ")}]
                end
              else
                if TAG.safe.include? tag
                  TAG[tag].tag(:user, ee, mx[0])
                  QUERY[mx[0]].items.incr(w.join(" "))
                else
                  r << %[Bad mention tag: #{tag}\nAcceptable tags are: #{TAG.safe.join(", ")}]
                end
              end
            else
              TAG[tag].tag(:user, ee)
              QUERY[tag].items.incr(w.join(" "))
            end
          end
          if @amt > 0
            Z4.xfer from: h[:user], to: ee, amt: @amt, memo: "#{tag} #{mx[0]} #{mx[1]}"
          end
        end
        
        Z4.index id: i, text: s
        
        r << %[HEARD: #{m[1]}]
      else
        r << %[Bad collection tag: #{tag}\nAcceptable tags are: #{TAG.safe.join(", ")}]
      end
    elsif m = /^#(.+)\?$/.match(c)
      w.shift
      Z4.search(m[1]).each { |x| r << x }
    end
    
    if r.length == 0
      if cmd == false && w.length > 0
        hh = { batch: 256, ext: 0.1 }.merge(h)
        p = %[#{hh[:info]}\n#{hh[:task]}\nUser: #{w.join(" ")}\nBot: ]
        a = %[-b #{hh[:batch]} --rope-scaling yarn --yarn-ext-factor #{hh[:ext]}]  
        `llama #{a} -p "#{p}" 2> /dev/null`.gsub(p,"").strip.split("\n").each { |e| puts %[handle e: #{e}]; r << e }
      end
    end

    puts %[handle return #{r}]
    return r
  end

end
