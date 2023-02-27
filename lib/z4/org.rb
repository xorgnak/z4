module Z4Org

  HEAD = %[#+TITLE: <%= @opts[:title] %>           
#+TODO: <%= @opts[:todo].join(" ") %> | <%= @opts[:done].join(" ") %>
#+OPTIONS: stat:t html-postamble:nil H:0 num:t toc:t \\n:t LaTeX:t skip:t d:t 
#+OPTIONS: todo:t pri:t tags:nil @::t ::t |:t ^:t -:t f:t *:t <:t
#+LANGUAGE: en
#+INFOJS_OPT: view:t toc:t ltoc:t mouse:underline buttons:0 path:https://orgmode.org/org-info.js
#+EXPORT_SELECT_TAGS: export
#+EXPORT_EXCLUDE_TAGS: noexport
#+STARTUP: inlineimages
]

  class Html
    def initialize t
      @f = File.read("org/#{t}.html")
      @style = /<style>([\w|\W]*)<\/style>/m.match(@f),
      @script = /<script type="text\/javascript">([\w|\W]*)<\/script>/m.match(@f),
      @body = /<body>([\w|\W]*)<\/body>/m.match(@f)
    end
    def style
      @style[1]
    end
    def script
      @script[1]
    end
    def body
      @body[1]
    end
  end
  def self.html t
    Html.new(t)
  end
  ##
  # @opts
  # templates: []
  # level: 1
  # 
  def self.generate t, h={}
    @opts = {
      title: "generated document",
      templates: [],
      todo: [ 'TODO(T!\@)' ],
      done: [ 'DONE(D!\@)' ],
      keywords: [],
      tags: [],
      level: 1,
      text: "created at #{Time.now.utc}"
    }.merge(h)
    @app = @opts[:app] || 'localhost'
    @brand = @opts[:brand] || 'localhost'
    @team = @opts[:team] || 'localhost'
    @campaign = @opts[:campaign] || 'localhost'
    @role = @opts[:role] || '@everyone'
    @user = @opts[:user] || 'noone'
    @a = []
    if @opts[:bare] != true
      @a << HEAD
    end
    @opts[:templates].each {|e| @a << File.read("templates/#{e}.org.erb") }
    @a << Heading.new(@opts).org
    File.open("org/#{t}.org", 'w') { |f| f.write(ERB.new([@a.join("\n"), "\n"].join("")).result(binding)) }
  end

  def self.append t, h={}
    @a = []
    @a << Heading.new(h).org
    File.open("org/#{t}.org", 'a') { |f| f.write(ERB.new([@a.join("\n"), "\n"].join("")).result(binding)) }
  end
  
  class Heading
    def initialize h={}
      @head = h
    end
    def headline
      a = [%[#{Array.new(@head[:level].to_i, '*').join('')}]]
      
      if @head.has_key? :state
        a << %[#{@head[:state].upcase}]
      end
      if @head.has_key? :priority
        a << %[[#{@head[:priority]}]]
      end
      
      a << %[#{@head[:text]}]
      
      if @head[:tags].length > 0
        a << %[#{Array.new(8, " ").join("")}]
        a << %[:#{@head[:tags].join(":")}:]
      end
      return a.join(" ")
    end
    def org
      a = [headline]

      if @head.has_key?(:timestamps)
        @head[:timestamps].each {|e| a << a }
        a << %[\n]
      end

      [:settings, :clock].each { |x|
        if @head.has_key?(x)
          a << ":#{x.upcase}:"
          @head[x].each { |e| a << ":#{e[0]}: #{e[1]}" }
          a << ":END:"
          a << %[\n]
        end
      }
        
      if @head.has_key?(:ul)
        @head[:ul].each {|e| a << "  - #{e}"}
        a << %[\n]
      end

      if @head.has_key?(:ol)
        @head[:ol].each_with_index {|e,i| a << "  #{i}. #{e}"}
        a << %[\n]
      end

      if @head.has_key?(:body)
        @head[:body].each {|e| a << e }
      end
      
      return a.join("\n")
    end
  end
end

