Gem::Specification.new do |s|
  s.name        = 'taft'
  s.version     = '0.1.0'
  s.licenses    = ['MIT']
  s.summary     = "Test Automation Framework Template"
  s.description = "This gem will deploy/install a skeleton code framework for the automated testing of applications with APIs and/or web-UIs"
  s.authors     = ["Richard Morrisby"]
  s.email       = 'rmorrisby@gmail.com'
  s.files       = ["lib/taft.rb"]
  s.homepage    = 'https://rubygems.org/gems/taft'
  s.required_ruby_version = '>=1.9'
  s.files = Dir['**/**']
  s.test_files = Dir["test/test*.rb"]
end