module GIT
  
  def self.pwd
    @@DIR = Dir.pwd
  end

  def self.ls &b
    h = {}
    Dir["*"].each { |e|
      if block_given?
        h[e] = b.call(File.stat(e))
      else
        h[e] = File.stat(e)
      end
    }
    return h
  end

  def self.cd d
    Dir.chdir d
    GIT.pwd
  end
  
  class Repo
    def initialize k
      @git = Git.open(k, :log => Logger.new(STDOUT))
    end
    def git
      @git
    end
    def push!
      @git.push('origin', all: true)
    end
    def add!
      @git.add(:all=>true)
    end
  end
  @@DIR = Dir.pwd
  @@REPO = Repo.new(@@DIR)  
end
