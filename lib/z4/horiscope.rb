class Astro
  def initialize
    @info = Astronomy::Information.new
  end

  def id; :horiscopes; end

  def info
    @info
  end

  def categories
    @info.categories
  end

  def search s
    @info.search(s)
  end

  def topics
    h = {}
    @info.categories.each { |e| h[e] = @info.topics(e) }
    return h
  end
  
  def random
    c = categories.sample
    x = @info.topics(c)
    y = x.length
    d = x[rand(0..y)]['description']
    return [d.split(/\n/)].flatten
  end
end

module Z4
  @@ASTRONOMY = Astro.new
  def self.astronomy
    @@ASTRONOMY
  end
end

class Horiscope
  def initialize u
    @user = OBJ[u]
  end
  def to_s
    [
      %[Your #{Z4.movements.sample} #{Z4.signs.sample} is #{Z4.orbits.sample}.],
      %[#{Z4.planets.sample} is #{Z4.orbits.sample}.],
      %[Currently, your #{Z4.zodiac.sample} is in your #{Z4.signs.sample} house. And #{Z4.planets.sample} is in your #{Z4.alignments.sample} #{Z4.zodiac.sample} house.],
      %[As a #{@user.attr[:sign]}, your life is greatly effected by #{Z4.planets.sample} right now.],
      %[When #{Z4.planets.sample} is #{Z4.alignments.sample} to #{Z4.planets.sample} #{Z4.orbits.sample}, your #{Z4.signs.sample} is #{Z4.movements.sample}.]
    ].shuffle.join("\n")
  end
end


module Z4
  @@HORISCOPE = Hash.new { |h,k| h[k] = Horiscope.new(k) }
  def self.horiscope
    @@HORISCOPE
  end
  def self.zodiac
    [ :cancer,:leo,:capricorn,:gemini,:aquarius,:libra,:taurus,:aries,:pisces ]
  end
  def self.movements
    [ :rising, :falling, 'at rest' ]
  end
  def self.signs
    [ :sun, :moon ]
  end
  def self.orbits
    [ "in retrograde", "in procession", "at equinox", "at perogy", "at apogy" ]
  end
  def self.alignments
    [:parallel,:tangential,:perpendicular]
  end
  def self.planets
    [:mercury,:venus,:mars,:vesta,:ceres,:jupiter,:saturn,:uranus,:neptune,:pluto]
  end
end


module TAROT
  def self.trumps
    [
      "The Fool",
      "The Magician",
      "The High Priestess",
      "The Emperess",
      "The Emperor",
      "The Hierophant",
      "The Lovers",
      "The Chariot",
      "Justice",
      "The Hermit",
      "Wheel of Fortune",
      "Strength",
      "The Hanged Man",
      "Death",
      "Temperance",
      "The Devil",
      "The Tower",
      "The Star",
      "The Moon",
      "The Sun",
      "Judgement",
      "The World"
    ]
  end
  def self.faces
    [
      "Valet",
      "Knight",
      "Queen",
      "King"
    ]
  end
  def self.suits
    [
      "Cups",
      "Coins",
      "Clubs",
      "Swords"
    ]
  end
end

class Tarot
  def initialize n
    @name = n
    @size = 1
    @deck, @hand, @burn = [], [], []
    deck!
    shuffle!
    hand!
  end

  def shuffle!
    @deck.shuffle!
  end
  def size
    @size
  end
  def size= s
    @size = s
  end
  def deck
    @deck
  end
  def hand
    @hand
  end
  def burn
    @burn
  end
  
  def deck!
    TAROT.trumps.each_with_index { |e,i| @deck << %[#{i}: #{e}] }
    TAROT.suits.each do |suit|
      (1..10).each do |card|
        @deck << %[#{card} of #{suit}]
      end      
      TAROT.faces.each do |card|
        @deck << %[#{card} of #{suit}]
      end
    end
  end

  def hand!
    @burn << @hand
    @burn.flatten!
    @hand = []
    @size.times { @hand << @deck.shift }
    return @hand
  end
  
end

module Z4
  @@TAROT = Hash.new { |h,k| h[k] = Tarot.new(k) }
  def self.tarot
    @@TAROT
  end
end

class Die
  def initialize sides
    @sides = sides
    @result = {}
    (1..sides).each { |e| @result[e] = 0 }
    @rolls = []
    @tot = 0
    @roll = 0
    roll!
  end
  def total
    @tot
  end
  def results
    @result
  end
  def rolls
    @rolls.length
  end
  def roll
    @roll
  end
  def roll!
    @rolls << @roll
    @roll = rand(1..@sides)
    @tot += @roll
    return @roll
  end
end

class Dice
  def initialize number, sides
    @die = Die.new(sides)
    @number = number
    @rolls = []
    @tot = 0
    @roll = Array.new(@number, 0)
    roll!
  end
  def roll
    @roll
  end
  def rolls
    @rolls
  end
  def total
    @tot
  end
  def roll!
    @rolls << @roll
    @roll = []
    tot = 0
    @number.times { x = @die.roll!; tot += x; @roll << x; }
    @tot += tot
    return @roll
  end
end

module Z4
  def self.dice n,s
    Dice.new(n,s)
  end
end


module Z4
  def self.fortune
    `fortune /usr/share/games/fortunes/fortunes`.gsub(/\s/," ").gsub(/\s+/," ").split(". ")
  end
end


module Z4
  
  def self.odds h={}
    Fortune::Odds.new(:win => h[:wins].to_i, :lose => (h[:games].to_i - h[:wins].to_i).to_i).to_human(:k => 5, :fractions => true).p * 100
  end
  
  def self.tier h={}
    p = Z4.odds(h)
    x = (p / 10).to_i
    if x > 9
      return 9
    else
      return (p / 10).to_i
    end
  end

end
