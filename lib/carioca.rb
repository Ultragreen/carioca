# frozen_string_literal: true

require_relative "carioca/dependencies"

module Carioca
  class Error < StandardError; end
  

  class Registry 

    include Carioca::Constants
    @@inst = nil


    def Registry.init(**keywords)
      @@inst ||= new(**keywords)      
      return @@inst
    end

    attr_accessor :services
    attr_accessor :active_services

    def get_service(name: , options: nil)
      service = nil
      raise ':name keywords missing' unless name
      raise 'Service not found' unless @services.include? name
      require  @services[name][:resource] if [:gem, :file].include? @services[name][:type]
      unless @services[name][:init_options].nil? and options.nil? then 
        params = (@services[name][:init_options])? @services[name][:init_options] : {}
        options ||= { }
        params.merge! options
        @active_services[name] ||= Kernel.const_get(@services[name][:service])::new **params
      else
        @active_services[name] ||= Kernel.const_get(@services[name][:service])::new 
      end
      return active_services[name] 
    end

    private 
    def initialize(filename: , debug: false, name: 'Carioca')
      raise ":filename keyword missing" unless filename
      @filename =(filename)? filename :  DEFAULT_REGISTRY_FILE
      @debug = debug
      @name = name
      @active_services = Hash::new
      open_registry_file
    end

    def open_registry_file
      @services = YAML.load_file(@filename)
      
    end 


  end


end
