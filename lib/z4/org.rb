module Z4Org
  ORG = Hash.new {|h,k|
    h[k] = lambda { |head, *headings|
      File.open("org/#{k}.org", 'w') {|f| f.write([head.org, headings].flatten.join("\n")) }
      `emacs --batch --eval "(require 'org)" org/#{k}.org -f org-html-export-to-html`
    }
  }
  HEADING = Hash.new {|h,k| h[k] = Heading.new }
  HEAD = Hash.new {|h,k| h[k] = Head.new }

  class Head
    def initialize
      @doc = Hash.new {|h,k| h[k] = [] }
    end
    def doc
      @doc
    end
    def org
      t = @doc.delete(:todo)
      d = @doc.delete(:done)
      a = [ %[#+TODO: #{t.join(" ")} | #{d.join(" ")}] ]
      @doc.each_pair do |k, a|
        a << %[#+#{k}: #{a.join(" ")}]
      end
      a << "\n\n"
      return a.join("\n")
    end
  end
  
  class Heading
    def initialize
      @doc = Hash.new {|h,k| h[k] = []}
      @head = {}
      @tag = []
    end
    def doc
      @doc
    end
    def tag
      @tag
    end
    def head
      @head
    end
    def headline
      a = [%[#{@head[:level]}]]
      
      if @head.has_key? :state
        a << %[#{@head[:state].upcase}]
      end
      if @head.has_key? :state
        a << %[[#{@head[:priority]}]]
      end
      
      a << %[#{@head[:text]}]
      
      if @tag.length > 0
        a << %[#{Array.new(8, " ").join("")}]
        a << %[:#{@tag.join(":")}:]
      end
      return a.join(" ")
    end
    def org
      a = [headline]

      if @doc.has_key?(:timestamps)
        @doc[:timestamps].each {|e| a << a }
        a << %[\n]
      end

      [:settings, :clock].each { |x|
        if @doc.has_key?(x)
          a << ":#{x.upcase}:"
          @doc[:settings].each { |e| a << ":#{e[0]}: #{e[1]}" }
          a << ":END:"
          a << %[\n]
        end
      }
        
      if @doc.has_key?(:ul)
        @doc[:ul].each {|e| a << "  - #{e}"}
        a << %[\n]
      end

      if @doc.has_key?(:ol)
        @doc[:ol].each_with_index {|e,i| a << "  #{i}. #{e}"}
        a << %[\n]
      end

      if @doc.has_key?(:text)
        @doc[:text].each {|e| a << e }
      end
      return a.join("\n")
    end
  end
  
  def self.heading
    HEADING
  end
  
  def self.[] k
    { head: HEAD[k], org: ORG[k] }
  end

  def self.[]= k, v
    ORG[k].call(HEAD[k], v)
  end

  def self.read k
    File.read("org/#{k}.org")
  end
end

