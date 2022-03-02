module Carioca
    class Config
        include Carioca::Constants
        attr_accessor :filename, :debug, :name, :builtins, :log_target
        def initialize
            @filename = DEFAULT_REGISTRY_FILE
            @debug = false
            @name = 'Carioca' 
            @builtins = BUILTINS
            @log_target = '::Logger::new(STDOUT)'
        end

        def log_file=(name)
            @log_target = "::Logger::new('#{name}')"
        end
    end
end