module PLAN
  @@PLAN = Hash.new { |h,k| h[k] = Plan.new(k) }
  @@P = Hash.new { |h,k| h[k] = P.new(k) }

  class P
    def initialize k
      @db = PStore.new("db/p-#{k}.pstore")
    end
    def [] k
      @db.transaction { |db| db[k] || 'needed' }
    end
    def []= k,v
      @db.transaction { |db| db[k] = v }
    end
  end

  def self.cast
    @@P
  end
  
  class Plan
    def initialize k
      @id = k
      @name = k.gsub("plan/","").gsub(".md","").gsub("_"," ")
      @md = File.read(k)
    end
    def cast k
      @cast = k
    end
    def with
      PLAN.cast
    end
    def name
      @name
    end
    def to_md
      ERB.new(@md).result(binding)
    end
    def to_html
      Kramdown::Document.new(ERB.new(@md).result(binding)).to_html
    end
  end
  
  def self.[] k
    @@PLAN[k]
  end
  def self.keys
    @@PLAN.keys
  end
  def self.each &b
    @@PLAN.each_pair { |k,v| b.call(v) }
  end
  def self.sample
    p = @@PLAN.keys.sample
    @@PLAN[p]
  end
  Dir["plan/*"].each { |e| @@PLAN[e] }
end
