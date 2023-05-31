# frozen_string_literal: true

# monkey patching of Hash
class Hash
  def deep_symbolize
    target = dup
    target.each_with_object({}) do |(key, value), memo|
      value = value.deep_symbolize if value.is_a?(Hash)
      memo[key.to_sym] = value
    end
  end

  def method_missing(name, *args)
    if name.to_s =~ /(.+)=$/
      self[Regexp.last_match(1).to_sym] = args.first
    else
      self[name.to_sym]
    end
  end
end

# the carioca Namespace
module Carioca
  # the service Namespace
  module Services
    # the Config Namespade
    module Config
      # config file manager
      class ConfigFile
        include Carioca::Constants
        attr_accessor :filename, :data
        attr_reader :error

        def initialize(filename:)
          @filename = filename
          @data = {}
          @error = ''
          open
        end

        def error?
          !@error.empty?
        end

        def create!(force: false)
          write_ok = true
          write_ok = force if File.exist? @filename
          File.write(@filename, @data.to_yaml) if write_ok
        end

        def open
          if File.exist?(@filename)
            begin
              @data = YAML.load_file(@filename)
            rescue StandardError => e
              @error = e.message
              @data = {}
            end
          end
          prepare!
        end

        private

        def prepare!
          config = Carioca::Registry.config
          @data = {} unless @data.instance_of?(Hash)
          @data.delete_if { |key, _value| config.config_root != key }
          @data[config.config_root] = {} unless @data.include? config.config_root
          config.supported_environments.each do |evt|
            @data[config.config_root][evt] = {} unless @data[config.config_root].include? evt
          end
          @data[config.config_root][:default] = {} unless @data[config.config_root].include? :default
          create!
        end
      end

      # A setting object
      class Settings < Hash
        attr_accessor :config_file, :stage

        include Carioca::Helpers

        def initialize(config_filename:, stage:, root:)
          super
          registry = Carioca::Registry.get
          @logger = registry.get_service name: :logger
          @i18n = registry.get_service name: :i18n
          @debug = Carioca::Registry.config.debug?
          @stage = stage
          @root = root
          @config_file = Carioca::Services::Config::ConfigFile.new filename: config_filename
          initconf
        end

        def refresh
          initconf
        end

        private

        def initconf
          if @config_file.error? && @debug
            @logger.debug('Carioca->Config') do
              @i18n.t('config.load.error', message: @config_file.error)
            end
          end
          @content = @config_file.data

          if @stage
            merge! @content[@root][:default]
            deep_merge! @content[@root][@stage]
          end
          if @debug
            @logger.debug('Carioca->Config') do
              @i18n.t('config.load.success', from: @config_file.filename)
            end
          end
        end
      end

      # the settings object factory
      class Factory
        extend Forwardable

        attr_accessor :settings

        def_delegators :@settings, :refresh

        def initialize(**keywords)
          @settings = Carioca::Services::Config::Settings.new(**keywords)
        end
      end
    end
  end
end
