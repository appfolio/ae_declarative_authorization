require File.expand_path(File.dirname(__FILE__) + '/mock_model')

class LoadMethod < PraxisDummy::Models::MockModel
  def self.name
    "LoadMethod"
  end
end
