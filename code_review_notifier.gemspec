Gem::Specification.new do |s|
  s.name        = "code_review_notifier"
  s.version     = File.read("VERSION").strip
  s.licenses    = ["MIT"]
  s.summary     = "Get notifications when updates happen to patch sets/pull requests!"
  s.authors     = ["Kyle Grinstead"]
  s.email       = "kyleag@hey.com"
  s.files       = Dir.glob("{lib}/**/*") + ["Gemfile", "migrations.rb"]
  s.homepage    = "https://rubygems.org/gems/code_review_notifier"
  s.metadata    = { "source_code_uri" => "https://github.com/MrGrinst/code_review_notifier" }
  s.require_path = "lib"
  s.platform    = Gem::Platform::RUBY
  s.executables = ["code_review_notifier"]
  s.post_install_message = <<MSG

\e[32mThanks for installing code_review_notifier!\e[0m
\e[32mSet it up by running `code_review_notifier --setup`\e[0m

MSG
end
