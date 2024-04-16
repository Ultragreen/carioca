# frozen_string_literal: true

require_relative 'lib/carioca/constants'

Gem::Specification.new do |spec|
  spec.name          = 'carioca'
  spec.version       = `cat VERSION`.chomp
  spec.authors       = ['Romain GEORGES']
  spec.email         = ['romain@ultragreen.net']

  spec.license = 'BSD-3-Clause'

  spec.summary = 'Carioca : Container And Registry with Inversion Of Control for your Applications'
  spec.homepage = 'https://github.com/Ultragreen/carioca'
  spec.description = 'Carioca 2: is a complete rewrite who provide a full IoC/DI light Container and a services registry, build with logs, config and Internationalization facilities for designing your applications'

  spec.required_ruby_version = Gem::Requirement.new('>= 3.2.3')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'deep_merge', '~> 1.2'
  spec.add_dependency 'i18n', '~> 1.10'
  spec.add_dependency 'locale', '~> 2.1'
  spec.add_dependency 'pastel', '~>0.8.0'
  spec.add_dependency 'tty-prompt', '~>0.23.1'
  spec.add_development_dependency 'bundle-audit', '~> 0.1.0'
  spec.add_development_dependency 'code_statistics', '~> 0.2.13'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.32'
  spec.add_development_dependency 'yard', '~> 0.9.27'
  spec.add_development_dependency 'yard-rspec', '~> 0.1'
  spec.add_development_dependency 'diff-lcs', '~> 1.5.1'
  spec.metadata['rubygems_mfa_required'] = 'false'
  spec.add_dependency 'version', '~> 1.1'
  spec.add_runtime_dependency 'ps-ruby', '~> 0.0.4'
  spec.add_development_dependency 'cyclonedx-ruby', '~> 1.1'
end
