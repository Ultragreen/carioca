# coding: utf-8
require 'rake'
require 'rubygems'
require 'carioca'

$VERBOSE = nil
if Gem::Specification.respond_to?(:find_by_name)
  begin
    spec = Gem::Specification.find_by_name('carioca')
    res = spec.lib_dirs_glob.split('/')
  rescue LoadError
    spec = nil
  end
else
  spec = Gem.searcher.find('carioca')
  res = Gem.searcher.lib_dirs_for(spec).split('/')
end

res.pop
tasks_path = res.join('/').concat('/lib/carioca/tasks/')


Dir["#{tasks_path}/*.rake"].each { |ext| load ext }
