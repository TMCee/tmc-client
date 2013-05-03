Gem::Specification.new do |s|
  s.name          = 'tmc-client'
  s.version       = '0.0.1'
  s.platform      = Gem::Platform::RUBY
  s.summary       = 'TestMyCode Commandline client'
  s.authors       = ['Jarmo Isotalo', 'Tony Kovanen']
  s.homepage      = "https://github.com/TMCee/tmc-client/"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "json"
  s.add_dependency "faraday"
  s.add_dependency "fileutils"
  s.add_dependency "mocha"
  s.add_dependency "highline"
  s.add_dependency "rake"

  s.add_development_dependency "rspec"

end
