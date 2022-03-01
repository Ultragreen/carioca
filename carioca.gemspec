# frozen_string_literal: true

require_relative "lib/carioca/constants"

Gem::Specification.new do |spec|
  spec.name          = "carioca"
  spec.version       = Carioca::Constants::VERSION
  spec.authors       = ["Romain GEORGES"]
  spec.email         = ["romain@ultragreen.net"]




  spec.license =  "BSD-3-Clause"

  spec.summary = %q{Carioca : Configuration Agent and Registry with Inversion Of Control for your Applications}
  spec.homepage = %q{https://github.com/Ultragreen/carioca}
  spec.description = %q{Carioca : provide a full IoC light Container for designing your applications}

  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemse"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage


  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

end
