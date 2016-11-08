# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grape_devise_auth/version'

Gem::Specification.new do |spec|
  spec.name          = "grape_devise_auth"
  spec.version       = GrapeDeviseAuth::VERSION
  spec.authors       = ["Anton Sokolskyi"]
  spec.email         = ["antonsokolskyi@gmail.com"]

  spec.summary       = %q{Allows to use Devise-based registration/authorization inside Grape API}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency 'grape', '> 0.9.0'
  spec.add_dependency 'devise', '>= 3.3'
end
