module Carioca
    class Configuration
        include Carioca::Constants
        attr_accessor :filename, :name, :builtins, :log_target
        attr_accessor :config_file, :config_root, :environment, :supported_environment
        attr_writer :debug, :init_from_file
        attr_reader :log_file
        def initialize
            @init_from_file = true
            @filename = DEFAULT_REGISTRY_FILE.dup
            @debug = false
            @name = 'Carioca' 
            @builtins = BUILTINS
            @log_file = ''
            @config_file = DEFAULT_CONFIG_FILE.dup
            @environment = DEFAULT_ENVIRONMENT.dup
            @config_root = DEFAULT_CONFIG_ROOT.dup
            @log_target = '::Logger::new(STDOUT)'
            @supported_environment = DEFAULT_ENVIRONMENTS_LIST.dup
        end

        def debug? 
            return @debug
        end

        def init_from_file? 
            return @init_from_file
        end

        def log_file?
            return !@log_file.empty?
        end

        def log_file=(name)
            @log_file = name
            @log_target = "::Logger::new('#{name}')"
        end
    end
end