module Z4
  def self.post request, params
    h = {}
    a = []
    op = false
    
    if params.has_key?(:lat) && params.has_key?(:lon)
      [:lat, :lon].each { |e| h[e] = params[e] }
      h[:grid] = Z4.to_grid(params[:lat],params[:log])
    end
    
    if params.has_key?(:user)
      u = OBJ[:user][params[:user]];
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
      c = OBJ[:chan][params[:chan]];
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
      hx = QUERY[params[:query]].items.members(with_scores: true).to_h.sort_by { |k,v| -v }
      hx.to_h.each_pair { |k,v| lvl = "#{v.to_i}".length - 1; a << %[<p class='c'><span class='material-icons' style='color: red;'>#{Z4.heart[lvl]}</span><span class='box'>#{k}</span></p>]; }
      h[:items] = a.flatten.join('')
    end
    
    if params.has_key?(:board)
      h[:board] = params[:board]
      TAG[params[:board]].to_h.each_pair { |k,v|
        puts %[post #{k} #{v}]
        aa = []
        u = OBJ[:user][k]
        v.each_pair { |k,v| aa << %[<span style='padding: 0 1% 0 1%; border: thin solid grey; border-radius: 20px;'><span class='material-icons' style='font-size: small;'>#{k}</span><span>#{v}</span></span>] }
        a << %[<p class='c'><span style='padding: 0 2% 0 0;'>#{aa.join("")}</span><span>#{u.attr[:nick]}</span></p>]
      }
      h[:items] = a.flatten.join('')
    end

    if params.has_key?(:area)
      h[:area] = params[:area]
      w = WIKI.gps[params[:area]]
      aa = [
        %[<p class='c'><a href='#{w.url.value}' class='material-icons'>book</a>#{params[:area]}<a href='#{w.map.value}' class='material-icons'>place</a></p>],
        %[<div style='width: 100%; text-align: center;'>#{w.text.value.gsub(/\n+/," ")}</div>]
      ].join("")
      a << %[<div style='width: 100%; text-align: center;'>#{aa}</div>]
      h[:items] = a.flatten.join('')
    end
    
    if params.has_key?(:input)
      hhh = { batch: 256, ext: 0.1, info: 'Respond like User is a child.', task: 'Be helpful.', input: params[:input] }
      Z4.handle(hhh).each { |x| a << %[<p class='i'>#{x.strip.gsub(con, '')}</p>] }
      h[:output]= a.flatten.join('')
    end
    
    return h
  end
end
