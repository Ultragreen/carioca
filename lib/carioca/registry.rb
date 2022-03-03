module Carioca
    class Registry 
        include Carioca::Helpers
        include Singleton
        @@config = Configuration::new
    
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
          raise "Service not found: #{name}" unless @services.include? name
          if @active_services.include? name then 
            debug message: "Getting service #{name}" if @active_services.include? :logger and name != :logger and @@config.debug?
          else
            service = @services[name]
            service[:depends].each do|dep|
              debug  message: "Dependencie service #{dep}" if @active_services.include? :logger and dep != :logger and @@config.debug?
              get_service(name: dep) unless @active_services.include? dep
            end if service.include? :depends
            debug  message: "Starting service #{name}" if @active_services.include? :logger and name != :logger and @@config.debug?
            require  service[:resource] if [:gem, :file, :stdlib].include? service[:type]
            @active_services[name] ||= eval("lambda { #{service[:service]} }").call
          end
          return @active_services[name] 
        end
    
        def config
          return @@config
        end

        def add(service: , definition:, skip_validation: false )
          raise "Service #{service} already exist." if @services.include? service
          debug message: "Adding service #{service}" if @active_services.include? :logger and @@config.debug?
          checker = Carioca::Services::Validator::new service: service , definition: definition
          checker.validate! unless skip_validation
          @services[service] = checker.definition
        end
    
        private 
        def prepare_logger
          conf_logger = @@config.builtins[:logger]
          conf_logger[:service] = @@config.log_target
          add service: :logger, definition: @@config.builtins[:logger], skip_validation: true
          get_service name: :logger
        end

        def initialize
          @services = Hash::new
          @active_services = Hash::new
          prepare_logger
          target = (@@config.log_file?)? @@config.log_file : "STDOUT"
          debug message: "Preloaded service :logger ready on #{target}" if @@config.debug?
          debug message: "Initializing Carioca registry" if @@config.debug?
          debug message: "Preparing builtins" if @@config.debug?
          @@config.builtins.each do |service, spec|
            add service: service, definition: spec, skip_validation: true unless service == :logger
          end
          open_registry_file if File::exist? @@config.filename and @@config.init_from_file?
        end
    
        def open_registry_file
          debug message: "Initialize registry from file : #{@@config.filename}" if @@config.debug?
          registry_file = Carioca::RegistryFile::new filename: @@config.filename
          debug message: "Entry useless (builtin) #{registry_file.altered.to_s} in #{@@config.filename}" if registry_file.altered? and @@config.debug?
          registry_file.validated.each do |service,spec|
            add service: service, definition: spec
          end
          debug message: "Registry initialized" if @@config.debug?
        end 
    
    
    end
end