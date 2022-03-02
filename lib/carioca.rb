# frozen_string_literal: true

require_relative "carioca/dependencies"

module Carioca
  class Error < StandardError; end
  
  class Config
    include Carioca::Constants
    attr_accessor :filename, :debug, :name, :builtins
    def initialize
      @filename = DEFAULT_REGISTRY_FILE
      @debug = false
      @name = 'Carioca' 
      @builtins = {configuration: { type: :builtin,
                                    resource: "configuration",
                                    description: "The configuration service of Carioca",
                                    service: "Carioca::Services::Configuration::new config_file: './.config' }" }}

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


    def Registry.init()
      @@inst ||= new    
      return @@inst
    end

    class << self
      alias_method :get, :init
    end

    attr_accessor :services
    attr_accessor :active_services

    def get_service(name: )
      raise 'Service not found' unless @services.include? name
      service = @services[name]
      require  service[:resource] if [:gem, :file, :stdlib].include? service[:type]
      @active_services[name] ||= eval("lambda { #{service[:service]} }").call
      return @active_services[name] 
    end


    def add(service: , definition: )
      raise "Service #{service} already exist." if @services.include? service
      checker = Carioca::Services::Validator::new service: service , definition: definition
      checker.validate!
      @services[service] = checker.definition
    end

    private 
    def initialize
      @services = Hash::new
      @active_services = Hash::new
      @@config.builtins.each do |service, spec|
        add service: service, definition: spec
      end
      open_registry_file if File::exist? @@config.filename
    end

    def open_registry_file
      @services = YAML.load_file(@@config.filename)
      
    end 


  end


end
