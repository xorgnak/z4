module Z4
  LEVELS = [:visitor, :promotor, :influencer, :ambassador, :manager, :agent, :operator]
  def self.levels *x
    if x[0]
      if x[0].class == String || x[0].class == Symbol
        LEVELS.index(x[0].to_sym)
      else
        LEVELS[x[0]]
      end
    else
      return LEVELS
    end
  end
end
