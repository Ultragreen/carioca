#!/usr/bin/env ruby
#---
# Author : Romain GEORGES
# type : gem component library
# obj : Carioca Helpers definition Module
#---

class Class
  # Usage:
  #     prelaod_service :name => 'service', :params => { :arg => 'value'}
  def preload_service(_options = {})
    Carioca::Services::Registry.init.start_service _options
  end

  def use_configuration(_options = {})
    options = Methodic.get_options(_options)
    options.specify_classes_of :with_file => String
    options.specify_default_value_of :with_file => 'services/registry.yml'
    options.merge
    options.validate!
    Carioca::Services::Registry.init.start_service :name => 'configuration', :params => { :config_file => options[:with_file]}
  end
end


Module.class_eval do
  def init_registry _options={}
    options = Methodic.get_options(_options)
    options.specify_classes_of :with_file => String
    options.specify_default_value_of :with_file => 'services/registry.yml'
    options.merge
    options.validate!
    Carioca::Services::Registry.init :file => options[:with_file]
  end
end
