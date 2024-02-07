module IWW
  @@DIV = {
    "110" => "Agricultural",
    "120" => "Lumber",
    "130" => "Fishery",
    "140" => "Greenhouse",
    "210" => "Mining",
    "220" => "Energy",
    "310" => "Civil Construction",
    "330" => "Ship and Boat Builders",
    "340" => "Building Maintenance and Landscaping",
    "410" => "Textile and Leather",
    "420" => "Wood Processing and Furniture",
    "430" => "Chemical",
    "450" => "Printing and Publishing",
    "460" => "Food Product",
    "470" => "Electronics and Instrument",
    "480" => "Glass, Pottery, and Mineral",
    "490" => "Pulp and Paper Mill",
    "510" => "Marine",
    "520" => "Railroad",
    "530" => "Ground Transportation and Transit",
    "540" => "Postal Express and Message Delivery",
    "550" => "Air Transport",
    "560" => "General Distribution",
    "570" => "Communications and Internet Technology",
    "580" => "Information Service",
    "590" => "Video, Audio, and Film Production",
    "610" => "Health Services",
    "613" => "Incarcerated",
    "620" => "Education and Research",
    "630" => "Performing arts, Recreation, and Tourism",
    "631" => "Freelance and Temporary",
    "650" => "Financial Office",
    "651" => "Government",
    "660" => "Retail",
    "670" => "Utility and Sanitation",
    "690" => "Sex Industry"
  }
  @@MAP = {
    "driver" => ["530","540","631"],
    "pedicabber" => ["530"],
    "dancer" => ["630","690"],
    "entertainer" => ["630","690"],
    "onlyfans" => ["630","690"],
    "farmer" => ["110"],
  }
  def self.assign k, j
    if !@@MAP.has_key? k
      @@MAP[k] = []
    end
    @@MAP[k] << j
  end
  def self.map
    @@MAP
  end
  def self.[] x
    if @@MAP.has_key? x
      o = {}
      @@MAP[x].each { |e| o[e] = @@DIV[e] }
      return o
    else
      return false
    end
  end
  
end
