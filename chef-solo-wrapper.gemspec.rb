Gem::Specification.new do |s|
  s.name        = 'chef-solo-wrapper'
  s.version     = '0.0.3'
  s.date        = '2012-06-02'
  s.summary     = "chef-solo-wrapper"
  s.description = "A basic wrapper for chef-solo with RightScale integration."
  s.authors     = ["Chris Fordham"]
  s.email       = 'chris@xhost.com.au'
  s.executables << 'cs'
  s.homepage    = 'https://github.com/flaccid/chef-solo-wrapper'
  s.add_dependency 'json'
end