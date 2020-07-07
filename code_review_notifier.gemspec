Gem::Specification.new do |s|
  s.name        = 'code_review_notifier'
  s.version     = '0.1.2'
  s.licenses    = ['MIT']
  s.summary     = "Get notifications when updates happen to patch sets/pull requests!"
  s.authors     = ["Kyle Grinstead"]
  s.email       = 'kyleag@hey.com'
  s.files       = Dir.glob("{lib}/**/*") + ["Brewfile", "Gemfile"]
  s.homepage    = 'https://rubygems.org/gems/code_review_notifier'
  s.metadata    = { "source_code_uri" => "https://github.com/MrGrinst/code_review_notifier" }
  s.require_path = 'lib'
  s.platform    = Gem::Platform::RUBY
  s.executables = ['code_review_notifier']
end
