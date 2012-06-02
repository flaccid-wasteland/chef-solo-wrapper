class ConfigHelper
  # constructor method
  def initialize(setup_defaults, debug)
    @setup_defaults, @debug = setup_defaults, debug
  end
  
  # accessor methods
  def install_gem(gem)
    install_opts = '--no-rdoc --no-ri'
    system("gem install #{gem} #{install_opts}")
    Gem.clear_paths
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
      
  def install_chef
    puts
    puts '=> Setting up Chef Solo.'
    puts 'Installing Chef RubyGem...'
    gem = 'chef'
    begin
       puts  "#{gem} already installed, version: #{Gem::Specification.find_by_name(gem).version}."
    rescue Gem::LoadError
      install_gem(gem)
    rescue
      install_gem(gem) unless Gem.available?(gem)
    rescue
      raise 'Failed to install Chef Rubygem!'
    end
    puts
  end
  
  def setup_solo_rb(file, auto=@setup_defaults)
    puts "=> Setting up #{file}."
    if auto
      default_solo = true
    else
      puts '  Use default solo.rb [y/n] <enter> ?'
      default_solo = false
      default_solo = gets.chomp
    end
    if default_solo
      File.open(file, "w") {|f| f.write 'file_cache_path "/var/chef-solo"'+"\n"+'cookbook_path [ "/usr/src/chef-cookbooks/default" ]'+"\n"'json_attribs "/etc/chef/node.json"'+"\n"}
      system("mkdir -p /usr/src/chef-cookbooks/default")
      File.new('/usr/src/chef-cookbooks/default/chefignore', "w").close
      return
    end
    puts "  Type or paste your solo.rb (type EOF then press <enter> to finish):"
    $/ = "EOF"
    stdin = STDIN.gets
    File.open(file, "w") {|f| f.write stdin }
  end

  def setup_node_json(file, auto=@setup_defaults)
    puts "=> Setting up #{file}."
    if auto
      create_empty = 'y'
    else
      puts '  Create empty node.json [y/n] <enter> ?'
      create_empty = 'n'
      create_empty = gets.chomp
    end
    if create_empty.downcase == 'y'
      json = '{}'
    else
      puts "  Type or paste your node.json (type EOF then press <enter> to finish):"
      $/ = "EOF"
      json = STDIN.gets
    end
    File.open(file, "w") {|f| f.write json.gsub('EOF', '')}
  end

  def install_rest_connection(auto=false)
    puts '=> Setting up rest_connection.'
    begin
      if auto or @setup_defaults
        install_rc = 'y'
      else
        puts '  Install rest_connection [y/n] <enter> ?'
        install_rc = 'n'
        install_rc = gets.chomp
      end
      if install_rc.downcase == 'y'
        puts 'Installing rest_connection RubyGem...'
        gem = 'rest_connection'
        begin
           puts "#{gem} already installed, version: #{Gem::Specification.find_by_name(gem).version}."
        rescue Gem::LoadError
          install_gem(gem)
        rescue
          install_gem(gem) unless Gem.available?(gem)
        rescue
          raise 'Failed to install rest_connection!'
        end
      end
    end
    puts
  end

  def test_setup
    begin
      puts 'Testing require of chef.'
      require 'chef'
    rescue
      puts 'Failed to require Chef RubyGem!'
      exit 1
    end
    puts 'Test passed.'
    exit
  end
  
  def pre_checks
    # ensure a solo.rb exists for run
    if File.file?('/etc/chef/solo.rb')
      solo = '/etc/chef/solo.rb'
    else
      puts '    DEBUG: /etc/chef/solo.rb: not found.' if @debug
    end
    if File.file?("#{ENV['HOME']}/solo.rb")
      solo = "#{ENV['HOME']}/solo.rb"
    else
      puts '    DEBUG: ~/solo.rb: not found.' if @debug
    end
    unless solo
      puts 'FATAL: No solo.rb file found (see http://wiki.opscode.com/display/chef/Chef+Solo), exiting.'
      exit 1
    else
      puts "==> Using #{solo}." if @debug
      if File.zero?(solo) then
        puts "FATAL: #{solo} is empty, exiting."
        exit 1
      end 
      puts File.new(solo, 'r').read if @debug
    end
  end

end