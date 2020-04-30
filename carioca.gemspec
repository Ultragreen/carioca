Gem::Specification.new do |s|
  s.name = %q{carioca}
  s.author = "Romain GEORGES"
  s.version = "1.4"
  s.license =  "BSD-2-Clause"
  s.summary = %q{Carioca : Configuration Agent and Registry with Inversion Of Control for your Applications}
  s.email = %q{romain@ultragreen.net}
  s.homepage = %q{https://github.com/Ultragreen/carioca}
  s.description = %q{Carioca : provide a full IoC light Container for designing your applications}
  s.files = `git ls-files`.split($/)


  s.add_development_dependency "rake", "~> 13.0.1"
  s.add_development_dependency 'rspec', '~> 3.9.0'
  s.add_development_dependency 'yard', '~> 0.9.24'
  s.add_development_dependency 'rdoc', '~> 6.2.1'
  s.add_development_dependency 'roodi', '~> 5.0.0'
  s.add_development_dependency 'code_statistics', '~> 0.2.13'
  s.add_development_dependency 'yard-rspec', '~> 0.1'


s.add_development_dependency 'uuid', '~> 2.3.9'



  s.add_dependency 'dorsal', "~> 1.3"
  s.add_dependency 'methodic', "~> 1.3", '>= 1.3'
  s.add_dependency 'xml-simple', "~> 1.1", '>= 1.1.5'
  s.add_dependency 'activesupport', "~> 6.0.2.2"
  s.required_ruby_version = '>= 1.8.1'

end
