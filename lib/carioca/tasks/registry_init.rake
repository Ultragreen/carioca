# coding: utf-8
require 'carioca'
namespace :carioca  do
  desc "initialize Carioca Registry"
  task :init_registry do
    mkdir 'services'
    carioca = Carioca::Services::Registry.init :name => 'services/registry.yml', :debug => true
    carioca.discover_builtins
    carioca.save!
    puts "Carioca : Registry initialize in services/registry.yml (see /tmp/log.file for details)"
  end
end
