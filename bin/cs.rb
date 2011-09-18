#!/usr/bin/ruby

# chef-solo-wrapper (cs)
puts 'chef-solo-wrapper 0.0.1.'

require 'rubygems'
require 'trollop'

require 'json'
#require 'xmlsimple'

server = false
attributes = Hash.new

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
  opt :json,      "Use alternate Chef Solo JSON data (default used, ~/node.json.)",       :short => "-j", :type => String   # flag --json, default false
  opt :dry,       "Dry run only, don't run chef-solo.",                                   :short => "-d"                    # flag --dry, default false
  opt :run,       "Use alernative run_list for chef-solo run.",                           :short => "-r", :type => String   # flag --run, default false
  opt :write,     "Write back to local JSON file.",                                       :short => "-w"                   # flag --write, default false
  opt :verbose,   "Verbose mode.",                                                        :short => "-v"                   # flag --verbose, default false
  opt :debug,     "Debug mode."                                                                                             # flag --debug, default faulse
end
p opts unless !opts.verbose

if File.file?('/etc/chef/solo.rb')
  puts File.new('/etc/chef/solo.rb', "r").read unless !opts.verbose
end

if opts.json
  attributes = File.new(opts.json, "r").read
else
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
p attributes

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
end

if opts.run
  # append runlist
  attributes['run_list'] = "#{opts.run}"
end

# write attributes to node.json
# prettify/json
node_json = JSON.pretty_generate(attributes)
puts node_json unless !opts.verbose
fh = File.new(node_file, "w")
fh.write(node_json)
fh.close

p attributes unless !opts.verbose

# import chef
puts 'Importing Chef RubyGem.' unless !opts.verbose
require 'chef'

# finally, run chef-solo
puts 'Starting Chef Solo.' unless !opts.verbose or opts.dry
chef_config = " -c #{opts.config}" unless !opts.config
chef_json = " -j #{opts.json}" unless !opts.json

cmd = "chef-solo#{chef_config}#{chef_json} || ( echo 'Chef run failed!'; cat /var/chef-solo/chef-stacktrace.out; exit 1 )"
puts "    DEBUG: #{cmd}" unless !opts.debug
system(cmd) unless opts.dry