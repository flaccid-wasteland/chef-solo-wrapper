class ConfigHelper < ChefSoloWrapper
  
  # constructor method
  def initialize(setup_defaults, debug, facility_log_level)
    
    @setup_defaults = setup_defaults
    @debug = debug
    @facility_log_level = facility_log_level
    
    super(facility_log_level)
    
    @l = EasyLogger.new(facility_log_level)
  end
  
  # accessor methods

  def command?(command)
    system("which #{ command} > /dev/null 2>&1")
  end
  
  def install_gem(gem)
    install_opts = '--no-rdoc --no-ri'
    system("gem install #{gem} #{install_opts}")
    Gem.clear_paths
  end
  
  def install_rubygem(gem)
    begin
       @l.log "[Gem] #{gem} already installed, version: #{Gem::Specification.find_by_name(gem).version}."
    rescue Gem::LoadError
      install_gem(gem)
    rescue
      install_gem(gem) unless Gem.available?(gem)
    rescue
      raise "Failed to install #{chef} Rubygem!"
    end
  end

  def show(solo_file, json_file)
    puts
    puts '* Chef Solo Setup *'
    puts 
    puts "#{solo_file}:"
    puts '--'
    puts File.open(solo_file, "r").read
    puts '--'
    puts
    puts "#{json_file}:"
    puts '--'
    puts File.open(json_file, "r").read
    puts '--'
    puts
  end

  def install_chef_opscode
    if ! system("dpkg -l | grep chef")
      system("DEBIAN_FRONTEND=noninteractive")
      system("sudo mkdir -p /etc/apt/trusted.gpg.d")
      system("gpg --keyserver keys.gnupg.net --recv-keys 83EF826A")
      system("gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null")
      system('echo "deb http://apt.opscode.com/ $(lsb_release -cs)-0.10 main" > /etc/apt/sources.list.d/opscode.list')
      system("sudo apt-get -y update")
      system("sudo apt-get -y upgrade")
      system("sudo apt-get -y install chef")
    else
      @l.log "[dpkg] Chef already installed, skipping."
    end
  end
  
  def install_chef
    @l.log "Setting up Chef Solo."
    if command?('lsb_release')
      lsb_release = `lsb_release -si`.strip
    else
      @l.log "lsb_release command not found, os detection skipped.", 'debug'
      lsb_release = 'none'
    end
    case "#{lsb_release}"
      when 'Ubuntu'
        @l.log 'Ubuntu detected; installing from opscode apt.', 'debug'
        install_chef_opscode_apt
        return
    else
      puts "    DEBUG: == RubyGems Sources ==\n#{`gem sources`}\n==\n" if @debug
      @l.log 'Installing Chef RubyGem...'
      install_rubygem('chef')
    end
  end

  def setup_solo_rb_sandbox(file, sandbox_version=5.8)
    raise "RightScale cookbooks cache, /var/cache/rightscale/cookbooks not found!" unless File.exists?('/var/cache/rightscale/cookbooks')
    @l.log "Setting up #{file}."
    if sandbox_version.to_s == '5.8'
      cookbooks_cache = '/var/cache/rightscale/cookbooks/default'
    else
      cookbooks_cache = '/var/cache/rightscale/cookbooks'
    end
    system('mkdir -p /etc/chef')
    cookbooks_path = Dir.glob("#{cookbooks_cache}/*").map {|element| "\"#{element}/cookbooks\"" }.join(', ')
    File.open(file, "w") {|f| f.write 'file_cache_path "/var/chef-solo"'+"\n"+'cookbook_path [ '+"#{cookbooks_path}"+' ]'+"\n"'json_attribs "/etc/chef/node.json"'+"\n"}
  end
  
  def setup_solo_rb(file, auto=@setup_defaults)
    @l.log "Setting up #{file}."
    if auto
      default_solo = 'y'
    else
      puts '  Use default solo.rb or edit existing [y/n/e] <enter> ?'
      default_solo = 'n'
      default_solo = gets.chomp
    end
    if default_solo == 'y'
      File.open(file, "w") {|f| f.write 'file_cache_path "/var/chef-solo"'+"\n"+'cookbook_path [ "/usr/src/chef-cookbooks/default" ]'+"\n"'json_attribs "/etc/chef/node.json"'+"\n"}
      system("mkdir -p /usr/src/chef-cookbooks/default")
      File.new('/usr/src/chef-cookbooks/default/chefignore', "w").close
      return
    elsif default_solo == 'e'
      editor = `which nano`.strip   # fallback
      editor = ENV['EDITOR'] if ENV['EDITOR']
      puts "    DEBUG: Using #{editor}"
      system("#{editor} /etc/chef/solo.rb")
      return
    end
    puts "  Type or paste your solo.rb (type EOF then press <enter> to finish):"
    $/ = "EOF"
    stdin = STDIN.gets
    File.open(file, "w") {|f| f.write stdin }
  end

  def setup_node_json(file, auto=@setup_defaults)
    @l.log "Setting up #{file}."
    if auto
      create_empty = 'y'
    else
      puts 'Create empty node.json [y/n] <enter> ?'
      create_empty = 'n'
      create_empty = gets.chomp
    end
    if create_empty.downcase == 'y'
      json = '{}'
    else
      puts "Type or paste your node.json (type EOF then press <enter> to finish):"
      $/ = "EOF"
      json = STDIN.gets
    end
    File.open(file, "w") {|f| f.write json.gsub('EOF', '')}
  end

  def install_rest_connection(auto=false)
    @l.log 'Setting up rest_connection.'
    begin
      if auto or @setup_defaults
        install_rc = 'y'
      else
        puts 'Install rest_connection [y/n] <enter> ?'
        install_rc = 'n'
        install_rc = gets.chomp
      end
      if install_rc.downcase == 'y'
        @l.log 'Installing rest_connection RubyGem...'
        install_rubygem('rest_connection')
      end
    end
  end

  def test_setup
    begin
      @l.log 'Testing require of chef.'
      require 'chef'
    rescue
      @l.log 'Failed to require Chef RubyGem!'
      exit 1
    end
    @l.log 'Test passed.'
    exit
  end
  
  def pre_checks
    # ensure a solo.rb exists for run
    if File.file?('/etc/chef/solo.rb')
      solo = '/etc/chef/solo.rb'
    else
      @l.log "/etc/chef/solo.rb: not found.", 'debug'
    end
    if File.file?("#{ENV['HOME']}/solo.rb")
      solo = "#{ENV['HOME']}/solo.rb"
      @l.log "Using #{ENV['HOME']}/solo.rb as preferred.", 'debug'     
    end
    unless solo
      raise 'FATAL: No solo.rb file found (see http://wiki.opscode.com/display/chef/Chef+Solo), exiting.'
      exit 1
    else
      @l.log "DEBUG: Using #{solo}.", 'debug'
      if File.zero?(solo) then
        raise "FATAL: #{solo} is empty, exiting."
        exit 1
      end 
      @l.log "== solo.rb ==\n#{File.new(solo, 'r').read.strip}\n==", 'debug'
    end
  end

end