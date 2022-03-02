module Carioca
    class Registry 
        include Carioca::Helpers
        include Singleton
        @@config = Config::new
    
        def Registry.config
          return @@config
        end
    
        def Registry.configure(&block)
          yield(@@config)
        end
    
        class << self
          alias_method :get, :instance
          alias_method :init, :instance

        end
    
        attr_accessor :services
        attr_accessor :active_services
    
        def get_service(name: )
          raise 'Service not found' unless @services.include? name
          if @active_services.include? name then 
            debug message: "Getting service #{name}" if @active_services.include? :logger and name != :logger
          else
            service = @services[name]
            service[:depends].each do|dep|
              debug  message: "Dependencie service #{dep}" if @active_services.include? :logger and dep != :logger
              get_service(name: dep) unless @active_services.include? dep
            end if service.include? :depends
            debug  message: "Starting service #{name}" if @active_services.include? :logger and name != :logger
            require  service[:resource] if [:gem, :file, :stdlib].include? service[:type]
            @active_services[name] ||= eval("lambda { #{service[:service]} }").call
          end
          return @active_services[name] 
        end
    
        def config
          return @@config
        end

        def add(service: , definition: )
          raise "Service #{service} already exist." if @services.include? service
          debug message: "Adding service #{service}" if @active_services.include? :logger
          checker = Carioca::Services::Validator::new service: service , definition: definition
          checker.validate!
          @services[service] = checker.definition
        end
    
        private 
        def prepare_logger
          conf_logger = @@config.builtins[:logger]
          conf_logger[:service] = @@config.log_target
          add service: :logger, definition: @@config.builtins[:logger]
          get_service name: :logger
        end

        def initialize
          @services = Hash::new
          @active_services = Hash::new
          prepare_logger
          
          debug message: "Initializing Carioca registry"
          @@config.builtins.each do |service, spec|
            add service: service, definition: spec unless service == :logger
          end
          open_registry_file if File::exist? @@config.filename
        end
    
        def open_registry_file
          candidates = YAML.load_file(@@config.filename)
          candidates.each do |service,spec|
            add service: service, definition: spec
          end
        end 
    
    
    end
end