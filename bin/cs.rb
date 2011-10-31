#!/usr/bin/ruby

# chef-solo-wrapper (cs)
puts 'chef-solo-wrapper 0.0.1.'

require 'rubygems'
require 'trollop'

opts = Trollop::options do
	version "chef-solo-wrapper (c) 2011 Chris Fordham"
	banner <<-EOS
A CLI wrapper for Chef Solo w/ RightScale integration.

Usage:
       cs [options]
where [options] are:
EOS
  opt :server,    "Use attribute data from a RightScale server by nickname or ID.",       :short => "-s", :type => String                       # flag --server, default false
  opt :sandbox,   "Use the Ruby environment in the local RightLink sandbox."                                                                    # flag --sandbox, default false
  opt :config,    "Use alternate Chef Solo configuration (default used, ~/solo.rb.)",     :short => "-c"                                        # flag --config, default false
  opt :json,      "Use alternate Chef Solo JSON data (default used, ~/node.json.)",       :short => "-j", :type => String                       # flag --json, default false
  opt :dry,       "Dry run only, don't run chef-solo.",                                   :short => "-d"                                        # flag --dry, default false
  opt :run,       "Use alernative run_list for chef-solo run.",                           :short => "-r", :type => String                       # flag --run, default false
  opt :write,     "Write back to local JSON file.",                                       :short => "-w"                                        # flag --write, default false
  opt :loglevel,  "The Chef log level to use: debug, info, warn, error, fatal",           :short => "-l", :default => "info", :type => String   # flag --loglevel, default info
  opt :verbose,   "Verbose mode.",                                                        :short => "-v"                                        # flag --verbose, default false
  opt :debug,     "Debug mode."                                                                                                                 # flag --debug, default faulse
end
puts "    DEBUG: #{opts.to_json}" unless !opts.debug

server = false
attributes = Hash.new

# ensure a solo.rb exists for run
solo = false
if File.file?('/etc/chef/solo.rb')
  solo = '/etc/chef/solo.rb'
else
  puts '    DEBUG: /etc/chef/solo.rb: not found.' unless !opts.debug
end
if File.file?("#{ENV['HOME']}/solo.rb")
  solo = "#{ENV['HOME']}/solo.rb"
else
  puts '    DEBUG: ~/solo.rb: not found.' unless !opts.debug
end
unless solo
  puts 'FATAL: No solo.rb file found (see http://wiki.opscode.com/display/chef/Chef+Solo), exiting.'
  exit 1
else
  puts "==> Using #{solo}." unless !opts.debug
  puts File.new(solo, 'r').read unless !opts.debug
end

# assign json
if opts.json
  attributes = File.new(opts.json, "r").read
else
  require 'json'
  if File.file?('/etc/chef/node.json')
    node_file = '/etc/chef/node.json'
    attributes = JSON.parse(File.new(node_file, "r").read)
    chef_json = " -j #{node_file}"
  elsif File.file?("#{File.expand_path('~')}/node.json")
    node_file = "#{File.expand_path('~')}/node.json"
    attributes = JSON.parse(File.new("#{File.expand_path('~')}/node.json", "r").read)
    chef_json = " -j #{node_file}"
  end
end
puts "    DEBUG:\n#{p attributes}" unless !opts.debug

# when a rs server is specified
if opts.server

  # import rest_connection
  puts 'Importing RestConnection RubyGem.' unless !opts.verbose
  require 'rest_connection'

  # fetch server via rest_connection
  if opts.server.to_i > 0
    puts "Finding server: #{opts.server}."
    server = Server.find("#{opts.server}")
  else
    puts "Finding server: '%#{opts.server}%'"
    server = Server.find(:first) { |s| s.nickname =~ /#{opts.server}/ }
  end
  puts "Found server, '#{server.nickname}'."
  puts server.to_yaml unless !opts.verbose
  
  # get current instance of server
  server.reload_current
  puts JSON.pretty_generate(server.settings) unless !opts.debug

  # assign inputs from server params
  inputs = server.parameters
  puts "    DEBUG: #{JSON.pretty_generate(inputs)}" unless !opts.debug
  inputs.each { |k,v|
    if k.to_s =~ /^[A-Z]+$/
      puts "    DEBUG: right_script input #{k} discarded." unless !opts.debug
    else
      puts "    DEBUG: #{k} => #{v}" unless !opts.debug
      keys = k.split("/")
      if keys.count == 2
        type = v.split(':')[0]
        value = v.split(':')[1]
        value = nil unless value != "$ignore"
        if keys[0] != 'rightscale'
          if !attributes.has_key?("#{keys[0]}")
            puts "    DEBUG: Attribute #{keys[1]} detected for cookbook, #{keys[0]}." unless !opts.debug
            attributes["#{keys[0]}"] = {}
          end
          puts "    DEBUG: [#{keys[0]}][#{keys[1]}] => type: #{type}" unless !opts.debug
          puts "    DEBUG: [#{keys[0]}][#{keys[1]}] => value: #{value}" unless !opts.debug
          #puts "[#{keys[0]}][#{keys[1]}] = #{value}"
          attributes["#{keys[0]}"]["#{keys[1]}"] = "#{value}"
        end
      end
    end
  }
end

if opts.run
  # append runlist
  attributes['run_list'] = "#{opts.run}"
end

# TODO: logic to check node.json

# write attributes to node.json
# prettify/json
node_json = JSON.pretty_generate(attributes)
puts "Node Attributes: \n #{node_json}" unless !opts.verbose
fh = File.new(node_file, "w")
fh.write(node_json)
fh.close

puts "    DEBUG:\n#{p attributes}" unless !opts.debug

# import chef
puts 'Importing Chef RubyGem.' unless !opts.verbose
require 'chef'

chef_config = " -c #{opts.config}" unless !opts.config
chef_json = " -j #{opts.json}" unless !opts.json

cs = 'chef-solo'
if opts.sandbox
  cs = '/opt/rightscale/sandbox/bin/chef-solo'
end

cmd = "#{cs}#{chef_config}#{chef_json} --log_level #{opts.loglevel} || ( echo 'Chef run failed!'; cat /var/chef-solo/chef-stacktrace.out; exit 1 )"
puts "    DEBUG: #{cmd}" unless !opts.debug

# finally, run chef-solo
puts 'Starting Chef Solo.' unless !opts.verbose
unless opts.dry
  system(cmd)
else
  puts 'Dry run only, exiting.'
  exit
end