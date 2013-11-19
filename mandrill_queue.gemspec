# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mandrill_queue/version'

Gem::Specification.new do |spec|
  spec.name          = "mandrill_queue"
  spec.version       = MandrillQueue::VERSION
  spec.authors       = ["Stan Bondi"]
  spec.email         = ["stan@fixate.it"]
  spec.description   = %q{Use MailChimps Mandrill to send mailers through a background worker queue.}
  spec.summary       = %q{Use MailChimps Mandrill to send mailers through a background worker queue.}
  spec.homepage      = "https://github.com/fixate/mandrill_queue/"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*', '[A-Z]*'] - ['Gemfile.lock']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  if RUBY_VERSION >= "1.9.3"
    spec.add_dependency "activesupport", "~> 4.0.0"
  else
    spec.add_dependency "activesupport", "~> 3"
  end
  spec.add_dependency "mandrill-api", "1.0.49"
  spec.add_dependency "mime-types", "1.25"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'factory_girl'
  spec.add_development_dependency 'faker'
end
