#!/usr/bin/ruby

# chef-solo-wrapper (cs)
#
# Copyright 2011, Chris Fordham
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CHEF_SOLO_WRAPPER_VERSION = '0.0.1'

require 'rubygems'
require 'trollop'
require 'json'

opts = Trollop::options do
	version 'chef-solo-wrapper '+CHEF_SOLO_WRAPPER_VERSION+' (c) 2011 Chris Fordham'
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
  opt :help, 	  "Print usage info and exit.",                                       	  :short => "-h"
end
puts "options: #{opts.to_json}" unless !(opts.verbose || opts.debug and !opts.help)
puts 'chef-solo-wrapper '+CHEF_SOLO_WRAPPER_VERSION

solo = false
server = false

# ensure a solo.rb exists for run
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
  if File.zero?(solo) then
    puts "FATAL: #{solo} is empty, exiting."
    exit 1
  end 
  puts File.new(solo, 'r').read unless !opts.debug
end

# get json if available
if opts.json
  attributes = File.new(opts.json, "r").read
else
  if File.file?('/etc/chef/node.json')
    node_file = '/etc/chef/node.json'
    attributes = JSON.parse(File.new(node_file, "r").read)
  elsif File.file?("#{File.expand_path('~')}/node.json")
    node_file = "#{File.expand_path('~')}/node.json"
    attributes = JSON.parse(File.new("#{File.expand_path('~')}/node.json", "r").read)
  else
    node_file = "#{File.expand_path('~')}/node.json"
    attributes = JSON.parse("{\n}\n")
  end
  chef_json = " -j #{node_file}"
end

# when a rs server is specified
if opts.server

  # import rest_connection
  puts 'Importing RestConnection RubyGem.' unless !opts.verbose
  require 'rest_connection'

  # fetch server via rest_connection
  if opts.server.to_i > 0
    puts "Finding server: #{opts.server}."
    server = Server.find(opts.server)
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
  server_attributes = Hash.new
  inputs.each { |input,v|
    if inputs.to_s =~ /^[A-Z]+$/
      puts "    DEBUG: right_script input #{k} discarded." unless !opts.debug
    else
      puts "    DEBUG: #{input} => #{v}" unless !opts.debug
      keys = input.split("/")
      if keys.count == 2
        type = v.split(':')[0] 
        value = v.split(':')[1]
        value = '' unless value != "$ignore"
        if keys[0] != 'rightscale'
          puts "    DEBUG: node attribute #{keys[1]} detected for cookbook, #{keys[0]}." unless !opts.debug
          puts "    DEBUG: attribute:#{keys[0]}[\"#{keys[1]}\"] type:#{type} value:#{value}" unless !opts.debug
          puts "    DEBUG: [#{keys[0]}][#{keys[1]}] => type: #{type}" unless !opts.debug 
          puts "    DEBUG: [#{keys[0]}][#{keys[1]}] => value: #{value}" unless !opts.debug
          server_attributes["#{keys[0]}"] = {} unless server_attributes["#{keys[0]}"]
          server_attributes["#{keys[0]}"]["#{keys[1]}"] = "#{value}"
        end
      end
    end
  }
  puts "    DEBUG:\n#{p server_attributes}" unless !opts.debug

end

if server_attributes
  puts server_attributes.to_json
  puts '    DEBUG: Merging attributes.' unless !opts.debug
  attributes = server_attributes.merge(attributes)
else
  puts '    DEBUG: No server attributes to merge.' unless !opts.debug
end

if opts.run
  # override runlist
  attributes['run_list'] = "#{opts.run}"
end

# write attributes back to local node.json
if opts.write and server_attributes
	node_json = JSON.pretty_generate(attributes)
	puts "Node Attributes: \n #{node_json}" unless !opts.debug
	# open file for write back
	fh = File.new(node_file, "w")
	fh.write(node_json)
	fh.close
end

# prepare options
chef_config = " -c #{opts.config}" unless !opts.config
chef_json = " -j #{opts.json}" unless !opts.json

# depict if sandbox chef-solo binary is used
if opts.sandbox
  cs = '/opt/rightscale/sandbox/bin/chef-solo'
else
  cs = 'chef-solo'
end

# build chef solo command
cmd = "#{cs}#{chef_config}#{chef_json} --log_level #{opts.loglevel} || ( echo 'Chef run failed!'; cat /var/chef-solo/chef-stacktrace.out; exit 1 )"
puts "    DEBUG: running #{cmd}" unless !opts.debug

# import chef
puts 'Importing Chef RubyGem.' unless !opts.verbose
require 'chef'

# prepend sudo if not run as root
if Process.uid != 0 
	cmd.insert(0, 'sudo ') 
	puts "    DEBUG: Non-root user, appending sudo (#{cmd})." unless !opts.debug
end

# finally, run chef-solo
puts 'Starting Chef Solo.' unless !(opts.verbose || opts.debug)
unless opts.dry
  system(cmd)
else
  puts 'Dry run only, exiting.'
  exit
end
