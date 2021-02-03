Gem::Specification.new do |s|
  s.name        = 'taft'
  s.version     = '0.2.4'
  s.licenses    = ['MIT']
  s.summary     = "Test Automation Framework Template (TAFT)"
  s.description = "TAFT will deploy/install a skeleton code framework for the automated testing of applications with APIs and/or web-UIs"
  s.authors     = ["Richard Morrisby"]
  s.email       = 'rmorrisby@gmail.com'
  s.files       = ["lib/taft.rb"]
  s.homepage    = 'https://github.com/RMorrisby/class_from_son'
  s.required_ruby_version = '>=2.6'
  s.files = Dir['**/**']
  s.test_files = Dir["test/test*.rb"]
end