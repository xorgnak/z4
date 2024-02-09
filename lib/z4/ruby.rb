
module RUBY
  @@RUBY = Hash.new { |h,k| h[k] = Ruby.new(k) }
  def self.[] k
    @@RUBY[k]
  end
  
  class R
    attr_accessor :output
    
    def initialize k
      @id = k
      clear!
    end
    def clear!
      @output = []
    end
    def << e
      self.instance_eval(e)
    end
    def puts i
      @output << i
    end
  end
  
  class Ruby
    def initialize k
      @id = k
      boot
    end
    def boot *i
      @ruby = R.new(@id)
      [i].flatten.each { |e| @ruby.instance_eval(e) }
    end
    def << i
      @ruby << i
    end
    def output
      @ruby.output
    end
    def clear!
      @ruby.clear!
    end
  end
end
