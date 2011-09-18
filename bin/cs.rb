#!/usr/bin/ruby

# chef-solo-wrapper (cs)
puts 'chef-solo-wrapper 0.0.1.'

require 'rubygems'
require 'trollop'

require 'json'
#require 'xmlsimple'

server = false
attributes = Hash.new

chef_config =  "#{File.expand_path('~')}/solo.rb"
chef_json = "#{File.expand_path('~')}/node.json"

opts = Trollop::options do
	version "chef-solo-wrapper (c) 2011 Chris Fordham"
	banner <<-EOS
A CLI wrapper for Chef Solo w/ RightScale integration.

Usage:
       cs [options]
where [options] are:
EOS
  opt :server,    "Use attribute data from a RightScale server by nickname or ID.",       :short => "-s", :type => String   # flag --server, default false
  opt :config,    "Use alternate Chef Solo configuration (default used, ~/solo.rb.)",     :short => "-c"                    # flag --config, default false
  opt :json,      "Use alternate Chef Solo JSON data (default used, ~/node.json.)",       :short => "-j"                    # flag --json, default false
  opt :dry,       "Dry run only, don't run chef-solo.",                                   :short => "-d"                    # flag --dry, default false
  opt :run,       "Use alernative run_list for chef-solo run.",                           :short => "-r", :type => String   # flag --run_list, default false
  opt :verbose,   "Verbose mode.",                                                        :short => "-v"                    # flag --verbose, default false
  opt :debug,     "Debug mode."                                                                                             # flag --debug, default faulse
end
p opts unless !opts.verbose

# when a rs server is specified
if opts.server
  # import rest_connection
  puts 'Importing RestConnection RubyGem.' unless !opts.verbose
  require 'rest_connection'
  if opts.server.to_i > 0
    server = Server.find(opts.server)
  else
    puts "Finding server: '%#{opts.server}%'"
    server = Server.find(:first) { |s| s.nickname =~ /#{opts.server}/ }
  end
  puts "Found server, '#{server.nickname}'."
  puts server.to_yaml unless !opts.verbose
  server.reload_current
  puts JSON.pretty_generate(server.settings) unless !opts.debug
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
else
  puts 'No server found.'
  exit 1
end

# append runlist
attributes['run_list'] = "#{opts.run}"

#p attributes unless !opts.verbose

# prettify/json
node_json = JSON.pretty_generate(attributes)
puts node_json unless !opts.verbose

# write attributes to node.json
node_file = File.new(chef_json, "w")
node_file.write(node_json)
node_file.close

# import chef
puts 'Importing Chef RubyGem.' unless !opts.verbose
require 'chef'

# finally, run chef-solo
puts 'Starting Chef Solo.' unless !opts.verbose or opts.dry
system("chef-solo -c #{chef_config} -j #{chef_json} || ( echo 'Chef run failed!'; cat /var/chef-solo/chef-stacktrace.out; exit 1 )") unless opts.dry