Gem::Specification.new do |s|
  s.name          = 'tmc-client'
  s.version       = '0.0.4'
  s.platform      = Gem::Platform::RUBY
  s.summary       = 'TestMyCode Commandline client'
  s.authors       = ['Jarmo Isotalo', 'Tony Kovanen']
  s.homepage      = "https://github.com/TMCee/tmc-client/"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

#  s.add_dependency "json"
  s.add_dependency 'faraday', '~> 0.8.8'
  s.add_dependency 'mocha', '~> 0.14.0'
  s.add_dependency 'highline'
  s.add_dependency 'rake'
  s.add_dependency 'rubyzip', '= 1.0.0'

  s.add_development_dependency 'rspec', '~> 2.14.1'
  s.add_development_dependency 'haiti', '~> 0.0.3'
  s.add_development_dependency 'cucumber', '~> 1.3.8'

end