class ChefSoloWrapper

  def initialize(facility_log_level)
    @facility_log_level = facility_log_level
    puts "[#{`date`.strip}] Log level: #{facility_log_level.upcase}"
  end
  
end