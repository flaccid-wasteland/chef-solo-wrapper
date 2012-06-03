class EasyLogger

  def initialize(facility_log_level='info')
    @facility_log_level = facility_log_level
    #puts "Facility Log level: #{facility_log_level.to_s.upcase}"
  end
  
  def log_level
    puts @facility_log_level
  end
  
  def log(message, level='info')
    render = false
    #puts "msg: #{message}"
    #puts "-log start-"
    #puts "@facility_log_level=#{@facility_log_level}"
    if level.kind_of?(Array)
      #puts "level, #{level} is an array."
      level = 'error' if level.include?('error')      
      level = 'verbose' if ( level.include?('verbose') && ! level.include?('debug') )
      level = 'info' if level.include?('info')
      level = 'debug' if level.include?('debug')
    elsif level.kind_of?(String)
      #puts 'level is a string.'
    end
    #puts "level asking to log is #{level}."
    render = true if level == 'error'
    render = true if (level == 'debug' and @facility_log_level == 'debug') 
    render = true if level == 'info'
    render = true if level == 'verbose' and ( @facility_log_level == 'verbose' || @facility_log_level == 'debug' )
    #puts "render: #{render}"
    if render
      puts "[#{`date`.strip}] #{level.upcase}: #{message}"
    else
      #puts "Discard log message: #{level.upcase}: #{message}" if @facility_log_level == 'debug'
    end
    #puts "-log finish-"
  end
  
end