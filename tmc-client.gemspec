Gem::Specification.new do |s|
	s.name = 'tmc-client'
	s.version = '0.0.2'
  s.platform    = Gem::Platform::RUBY
	s.summary = 'TestMyCode Commandline client'
	s.authors = ['Jarmo Isotalo', 'Tony Kovanen']
	s.homepage = "https://github.com/TMCee/tmc-client/"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "hashr", "~> 0.0.22"
  s.add_dependency "safe_yaml", '~> 0.9.0'

  s.add_dependency "json"
  s.add_dependency "faraday"
  s.add_dependency "pry"
  s.add_dependency "fileutils"
  s.add_dependency "mocha"
  s.add_dependency "highline"
  s.add_dependency "rake"
  s.add_dependency "rspec"

  s.add_development_dependency "rspec", "~> 2.8"

end