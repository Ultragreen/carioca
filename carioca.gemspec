Gem::Specification.new do |s|
  s.name = %q{carioca}
  s.author = "Romain GEORGES"
  s.version = "1.0"
  s.date = %q{2013-02-18}
  s.summary = %q{Carioca : Configuration Agent and Registry with Inversion Of Control for your Applications}
  s.email = %q{romain@ultragreen.net}
  s.homepage = %q{http://www.ultragreen.net}
  s.description = %q{Carioca : provide a full IoC light Container for designing your applications}
  s.has_rdoc = true
  s.files = Dir['*/*/*/*'] + Dir['*/*/*'] + Dir['*/*'] + Dir['*']
  s.add_development_dependency('rspec')
  s.add_development_dependency('yard')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('roodi')
  s.add_development_dependency('uuid')
  s.add_development_dependency('code_statistics')
  s.add_development_dependency('yard-rspec')
  s.add_dependency('dorsal')
  s.add_dependency('methodic')
  s.required_ruby_version = '>= 1.8.1'
  s.rdoc_options << '--title' << 'Carioca : Gem documentation' << '--main' << 'doc/manual.rdoc' << '--line-numbers' 
  # << '--diagram'
  s.rubyforge_project = "nowarning"
end