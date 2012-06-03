Gem::Specification.new do |s|
  s.name        = 'chef-solo-wrapper'
  s.version     = '0.0.11'
  s.date        = '2012-06-04'
  s.summary     = "chef-solo-wrapper"
  s.description = "A basic wrapper for chef-solo with RightScale integration."
  s.authors     = ["Chris Fordham"]
  s.email       = 'chris@xhost.com.au'
  s.files       = [ "lib/chef_solo_wrapper.rb", "lib/config_helper.rb", "lib/easy_logger.rb", "lib/cookbooks_fetcher.rb" ]
  s.executables << 'cs'
  s.homepage    = 'https://github.com/flaccid/chef-solo-wrapper'
  s.add_dependency "json", ">= 1.4.4", "<= 1.6.1"
  s.add_dependency 'trollop'
end