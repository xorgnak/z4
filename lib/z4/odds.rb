require 'fortune'

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
