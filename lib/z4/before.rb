
module Z4

  # required singleton attributes
  @@UREQ = {}
  def self.user
    @@UREQ
  end
  @@CREQ = {}
  def self.chan
    @@CREQ
  end
  
  ###
  ### SUBSTITUTIONS
  ###
  ##
  # "input I can parse" => "input I can handle."
  # used to return a value into a prompt from input.
  # Z4.substitution "string I got.", "String I give w/<%= Time.now.utc %>."
  # Z4.substitution "String to be substituted."
  # Z4.substitution
  @@INJECT = {}
  def self.injection *i
    if i[0] != nil && i[1] != nil
      @@INJECT[i[0]] = i[1]
    elsif i[0] != nil && i[1] == nil
      return ERB.new(@@INJECT[i[0]]).result(binding)
    elsif i[0] == nil && i[1] == nil
      return @@INJECT.keys
    end
  end
  
  
  
  ###
  ### CANNED
  ###
  ##
  # "known input mask." => "known output."
  
  @@CANNED = {}
  def self.canned *i
    if i[0] != nil && i[1] != nil
      @@CANNED[i[0]] = i[1]
    elsif i[0] != nil && i[1] == nil
      return ERB.new(@@CANNED[i[0]]).result(binding)
    elsif i[0] == nil && i[1] == nil
      return @@CANNED.keys
    end
  end

end
