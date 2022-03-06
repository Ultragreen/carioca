module Carioca
    class Configuration
        include Carioca::Constants
        include Carioca::Helpers
        attr_accessor :filename, :name, :builtins, :log_target, :default_locale, :locales_load_path, :debugger_tracer
        attr_accessor :config_file, :config_root, :environment, :supported_environment, :output_mode, :log_level
        attr_writer :debug, :init_from_file,  :output_colors, :output_emoji
        attr_reader :log_file, :locales_availables
        def initialize
            @init_from_file = true
            @filename = DEFAULT_REGISTRY_FILE.dup
            @debug = false
            @name = 'Carioca' 
            @builtins = BUILTINS
            @log_file = ''
            @log_level = DEFAULT_LOG_LEVEL.dup
            @log_level = :info if @debug == false and @log_level == :debug
            @config_file = DEFAULT_CONFIG_FILE.dup
            @environment = DEFAULT_ENVIRONMENT.dup
            @config_root = DEFAULT_CONFIG_ROOT.dup
            @log_target = '::Logger::new(STDOUT)'
            @supported_environment = DEFAULT_ENVIRONMENTS_LIST.dup
            @default_locale = DEFAULT_LOCALE
            @locales_availables = []
            @output_mode = DEFAULT_OUTPUT_MODE.dup
            @output_colors  = DEFAULT_COLORS_STATUS.dup
            @output_emoji = DEFAULT_EMOJI_STATUS.dup
            path = search_file_in_gem('carioca',"config/locales")
            @locales_load_path = Dir[File.expand_path(path) + "/*.yml"]
            Dir[path + '/*.yml'].sort.each do |file|
                @locales_availables.push File::basename(file,'.yml').to_sym
            end
            @debugger_tracer = DEFAULT_DEBUGGER_TRACER.dup
        end

        def debug? 
            return @debug
        end

        def output_colors? 
            return @output_colors
        end

        def output_emoji? 
            return @output_emoji
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