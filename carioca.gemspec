Gem::Specification.new do |s|
  s.name = %q{carioca}
  s.author = "Romain GEORGES"
  s.version = "1.2"
  s.license =  "BSD-2"
  s.date = %q{2013-02-18}
  s.summary = %q{Carioca : Configuration Agent and Registry with Inversion Of Control for your Applications}
  s.email = %q{romain@ultragreen.net}
  s.homepage = %q{http://www.ultragreen.net}
  s.description = %q{Carioca : provide a full IoC light Container for designing your applications}
  s.has_rdoc = true
  s.files = Dir['*/*/*/*'] + Dir['*/*/*'] + Dir['*/*'] + Dir['*']

  s.add_development_dependency "bundler", "~> 1.5"
  s.add_development_dependency "rake", "~> 10.5"
  s.add_development_dependency 'rspec', '~> 2.14', '>= 2.14.1'
  s.add_development_dependency 'yard', '~> 0.8', '>= 0.8.7.2'
  s.add_development_dependency 'rdoc', '~> 4.0', '>= 4.0.1'
  s.add_development_dependency 'roodi', '~> 3.1', '>= 3.1.1'
  s.add_development_dependency 'code_statistics', '~> 0.2', '>= 0.2.13'
  s.add_development_dependency 'yard-rspec', '~> 0.1'

  

  s.add_dependency 'dorsal', "~> 1.0"
  s.add_dependency 'methodic' "~> 1.2", '>= 1.2'
  s.add_dependency('xml-simple')	

  s.required_ruby_version = '>= 1.8.1'
  s.rdoc_options << '--title' << 'Carioca : Gem documentation' << '--main' << 'doc/manual.rdoc' << '--line-numbers' 
  # << '--diagram'
  s.rubyforge_project = "nowarning"
end
