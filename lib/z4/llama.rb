
module LLAMA
  @@POSITIVE = %[:smiley:]
  @@NEUTRAL = %[:neutral_face:]
  @@NEGATIVE = %[:face_with_raised_eyebrow:]
  def self.positive= p
    @@POSITIVE = p
  end
  def self.neutral= p
    @@NEUTRAL = p
  end
  def self.negative= p
    @@NEGATIVE = p
  end
  
  class Llama
    include LLAMA
    attr_accessor :prompt, :depth, :context, :batch
    def initialize k
      @id = k
      @i = []
      @o = []
      @context = 2048
      @batch = 128
      @depth = 1
    end

    def << i
      if /^.*\?$/.match(i)
        ask(i)
      else
        say(i)
      end
    end
    def [] i
      restate(i)
    end
    def ask q
      a = answer(q)
      { mood: mood(q), context: context(q), input: a[:i], output: a[:o] }
    end
    def say i
      a = respond(i)
      { mood: mood(i), context: context(i), input: a[:i], output: a[:o] }
    end
    def restate p
      a = summarize(p)
      { mood: mood(p), context: context(p), input: a[:i], output: a[:oOA] }
    end
    private
    def id; @id; end
    def args
      %[-c #{@context} -b #{@batch}]
    end
    def llama i
      `llama #{args} -p "#{i}" 2> /dev/null`.strip.gsub(i,"").strip
    end
    def trim i,o
      @i << i
      @o << o
      [@i,@o].each { |e| if e.length > @depth; e.shift; end; }
    end
    def respond p
      i = %[#{@prompt}\Respond with as few words as possible: #{p}\n]
      o = llama(i)
      if o != nil
        trim p, o
      end
      if "#{o}".length == 0
        o = "I can't respond to that."
      end      
      return { i: p, o: o }
    end
    def summarize p
      i = %[#{@prompt}\nSummarize with as few words as possible: #{p}\n].strip
      o = llama(i)
      if o != nil
        trim p, o
      end
      if "#{o}".length == 0
        o = "I need to know more to do that."
      end
      return { i: p, o: o }
    end
    def question c, q
      i = %[#{@prompt}\n#{c}\nAnswer: #{q}\n].strip
      o = llama(i)
      if o != nil
        trim p, o
      end
      if "#{o}".length == 0
        o = "I don't know."
      end
      return { i: q, o: o }
    end
    def lemma k, &b
      x = WordNet::Lemma.find_all(k)
      if block_given?
        x.map { |e| b.call(e) }
      else
        return x
      end
    end
    def context p
      words = Hash.new { |h,k| h[k] = 0 }
      con = Hash.new { |h,k| h[k] = [] }
      t = Tokenizer::WhitespaceTokenizer.new().tokenize(p)
      t.each do |word|
        ds, df = [], []
        lemma(word) { |e|
          ds << e.pos;
          df << e.synsets[0].gloss.gsub('"', "").gsub("--", " ").split("; ")[0]
        }
        if "#{word}".length > 2 && ds == ['n'] && !exclude.include?(word)
          words[word] += 1
          con[word] = df[0]
        end
      end
      hh = {}
      words.sort_by { |k,v| -v }.to_h.each_pair { |k,v| hh[k] = con[k] }
      return hh
    end
    def answer q
      c = []
      context(q).each_pair { |k,v| x = "If #{k} is #{v}."; puts x; c << x; }
      question(c.join("\n"), q)
    end
    def mood p
      x = TextMood.new(language: "en", ternary_output: true, start_ngram: 1, end_ngram: 4).analyze(p)
      if x > 0
        return @@NEGATIVE
      elsif x < 0
        return @@POSITIVE
      else
        return @@NEUTRAL
      end
    end
    def exclude
      [ 'are', 'who', 'may', 'why' ]
    end
  end
  @@LLAMA = Hash.new { |h,k| h[k] = Llama.new(k) }
  def self.[] k
    @@LLAMA[k]
  end
end
