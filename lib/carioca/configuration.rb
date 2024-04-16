# frozen_string_literal: true

module Carioca
  class Configuration
    include Carioca::Constants
    include Carioca::Helpers
    attr_accessor :filename, :name, :builtins, :log_target, :default_locale, :locales_load_path, :debugger_tracer,
                  :config_file, :config_root, :environment, :supported_environments, :output_mode, :log_level, :output_target, :user_config_path,
                  :master_key_file, :secure_store_file
    attr_writer :init_from_file, :output_colors, :output_emoji
    attr_reader :log_file, :locales_availables, :debug

    def initialize
      @init_from_file = true
      @filename = DEFAULT_REGISTRY_FILE.dup
      @debug = false
      @name = 'Carioca'
      @builtins = BUILTINS
      @log_file = ''
      @log_level = DEFAULT_LOG_LEVEL.dup
      @config_file = DEFAULT_CONFIG_FILE.dup
      @environment = DEFAULT_ENVIRONMENT.dup
      @config_root = DEFAULT_CONFIG_ROOT.dup
      @log_target = '::Logger::new(STDOUT)'
      @supported_environments = DEFAULT_ENVIRONMENTS_LIST.dup
      @default_locale = DEFAULT_LOCALE
      @locales_availables = []
      @output_mode = DEFAULT_OUTPUT_MODE.dup
      @output_colors = DEFAULT_COLORS_STATUS.dup
      @output_emoji = DEFAULT_EMOJI_STATUS.dup
      @output_target = DEFAULT_OUTPUT_TARGET.dup
      @user_config_path = DEFAULT_USER_CONFIG_PATH.dup
      @master_key_file = DEFAULT_MASTER_KEY_FILE.dup
      @secure_store_file = DEFAULT_SECURE_STORE_FILE.dup
      path = search_file_in_gem('carioca', 'config/locales')
      @locales_load_path = Dir["#{File.expand_path(path)}/*.yml"]
      Dir["#{path}/*.yml"].each do |file|
        @locales_availables.push File.basename(file, '.yml').to_sym
      end
      @debugger_tracer = DEFAULT_DEBUGGER_TRACER.dup
    end

    def debug=(state)
      @debug = state
      @log_level = :info if (@debug == false) && (@log_level == :debug)
      @log_level = :debug if @debug == true
    end

    def debug?
      @debug
    end

    def output_colors?
      @output_colors
    end

    def output_emoji?
      @output_emoji
    end

    def init_from_file?
      @init_from_file
    end

    def log_file?
      !@log_file.empty?
    end

    def log_file=(name)
      @log_file = name
      @log_target = "::Logger::new('#{name}')"
    end
  end
end
