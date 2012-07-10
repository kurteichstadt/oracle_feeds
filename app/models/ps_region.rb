class PsRegion
  def self.translate_region(ps_region)
    @@regions ||= init_regions
    result = @@regions[ps_region]
    result ||= ps_region
    result
  end
  
  def self.init_regions
    @@regions = {
      "CGL" => "GL",
      "CGN" => "NW",
      "CMIDA" => "MA",
      "CMIDS" => "MS",
      "CMNCO" => "NC",
      "CNE" => "NE",
      "CPS" => "SW",
      "CRR" => "RR",
      "CSE" => "SE",
      "CUPM" => "UM",
      "CWC" => "GP",
      "CGP" => "GP"
    }
    @@regions
  end
end