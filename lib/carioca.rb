# frozen_string_literal: true

require_relative "carioca/dependencies"

module Carioca
  class Error < StandardError; end
  
  class Config
    include Carioca::Constants
    attr_accessor :filename, :debug, :name
    def initialize
      @filename = DEFAULT_REGISTRY_FILE
      @debug = false
      @name = 'Carioca' 
      @builtins = {configuration: { type: :builtin,
                                    resource: "configuration",
                                    description: "The configuration service of Carioca",
                                    service: "Carioca::Services::Configuration",
                                    init_options: { config_file: "./.config" } }}
    end
  end

  class Registry 
    
    @@inst = nil
    @@config = Config::new

    def Registry.config
      return @@config
    end

    def Registry.configure(&block)
      yield(@@config)
    end


    def Registry.init(**keywords)
      @@inst ||= new(**keywords)      
      return @@inst
    end

    class << self
      alias_method :get, :init
    end

    attr_accessor :services
    attr_accessor :active_services

    def get_service(name: , options: nil)
      service = nil
      raise ':name keywords missing' unless name
      raise 'Service not found' unless @services.include? name
      require  @services[name][:resource] if [:gem, :file, :stdlib].include? @services[name][:type]
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


    def add(service: , definition: )
      raise ':service keyword is missing' unless service
      raise ':definition keyword is missing' unless definition
      [:type, :resource, :description, :service].each do |spec|
        p definition 
        raise "Key :#{spec} is mandatory in a service definition" unless definition.include? spec
      end
      @services[service] = definition
    end

    private 
    def initialize
      @active_services = Hash::new
      open_registry_file if File::exist? @@config.filename
    end

    def open_registry_file
      @services = YAML.load_file(@@config.filename)
      
    end 


  end


end
