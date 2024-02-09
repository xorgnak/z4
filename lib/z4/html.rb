
module HTML
  class H
    attr_reader :body
    
    def initialize k, i
      @id = k
      self.instance_eval(i)
    end

    def html *b
      if b[0]
        @body = b[0]
      else
        return %[<div id="#{@id}" class="z4">#{@body}</div>]
      end
    end
    
    def tag t, p, h={}
      a = []; h.each_pair { |k,v| a << %[#{k}="#{v}"] }
      return %[<#{t} #{a.join(" ")}>#{p}</#{t}>]
    end

    def options *i
      a = []
      if i[0].class == Hash
        i[0].each_pair { |k,v| a << %[<option value="#{v}">#{k}</option>] }
      else
        [i].flatten.each { |e| a << %[<option value="#{e}">] }
      end
      return a.join("")
    end
    
    def item t, h={}
      return %[<#{t} #{arguments(h)}>]
    end

    def arguments h={}
      a = []; h.each_pair { |k,v| a << %[#{k}="#{v}"] }
      return a.join(" ")
    end
    
    def raw i
      return %[#{i}]
    end

    def input h={}
      item(:input,h)
    end

    def button h={}
      t = h[:text]
      tag(:button,t,h)
    end
  end 
  def self.build n, i, x
    @x = x
    H.new(n,i).html
  end
end


