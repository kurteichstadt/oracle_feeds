class PsStrategy
  def self.translate_strategy(ps_strategy)
    @@strategies ||= init_strategies
    result = @@strategies[ps_strategy]
    result ||= ps_strategy
    result
  end
  
  def self.init_strategies
    @@strategies = {
      "CMP" => "CFM",
      "CAT" => "CFM",
      "OPS" => "Operations",
      "FDV" => "Fund Dev",
      "ND" => "National Director",
      "HR" => "LD",
      "FLD" => "CFM"
    }
    @@strategies
  end
end