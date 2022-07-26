# frozen_string_literal: true

module Carioca
  class Registry
    include Carioca::Helpers
    include Singleton
    @@config = Configuration.new

    def self.config
      @@config
    end

    def self.configure
      yield(@@config)
    end

    class << self
      alias get instance
      alias init instance
    end

    attr_accessor :services, :active_services

    def get_service(name:)
      raise "Service not found: #{name}" unless @services.include? name

      if @active_services.include? name
        debug message: i18n.t('service.getting', name: name) if @active_services.include?(:logger) && !%i[logger
                                                                                                          i18n output].include?(name) && @@config.debug?
      else
        service = @services[name]
        if service.include? :depends
          service[:depends].each do |dep|
            debug message: i18n.t('service.depends', name: dep) if @active_services.include?(:logger) && !%i[logger
                                                                                                             i18n].include?(dep) && @@config.debug?
            get_service(name: dep) unless @active_services.include? dep
          end
        end
        debug message: i18n.t('service.starting', name: name) if @active_services.include?(:logger) && !%i[logger
                                                                                                           i18n].include?(name) && @@config.debug?
        require  service[:resource] if %i[gem file stdlib].include? service[:type]
        @active_services[name] ||= eval("lambda { #{service[:service]} }").call # lambda { Aservice::new }
      end
      @active_services[name]
    end

    def config
      @@config
    end

    def add(service:, definition:, skip_validation: false)
      raise "Service #{service} already exist." if @services.include?(service) && (skip_validation == false)

      if @active_services.include?(:logger) && @@config.debug?
        debug message: i18n.t('service.adding',
                              name: service)
      end
      checker = Carioca::Services::Validator.new service: service, definition: definition
      checker.validate! unless skip_validation
      @services[service] = checker.definition
    end

    private

    def prepare_logger
      add service: :i18n, definition: @@config.builtins[:i18n], skip_validation: true
      conf_logger = @@config.builtins[:logger]
      conf_logger[:service] = @@config.log_target
      add service: :logger, definition: @@config.builtins[:logger], skip_validation: true
      log = get_service name: :logger
      log.level = @@config.log_level
    end

    def initialize
      @services = {}
      @active_services = {}
      prepare_logger
      locale = @@config.default_locale
      target = @@config.log_file? ? @@config.log_file : 'STDOUT'
      debug message: i18n.t('notify.locale', loc: locale) if @@config.debug?
      debug message:  i18n.t('notify.logger', target: target) if @@config.debug?
      debug message:  i18n.t('init.carioca') if @@config.debug?
      debug message: i18n.t('init.builtins') if @@config.debug?
      @@config.builtins.each do |service, spec|
        add service: service, definition: spec, skip_validation: true unless service == :logger
      end
      open_registry_file if File.exist?(@@config.filename) && @@config.init_from_file?
    end

    def open_registry_file
      debug message: i18n.t('init.registry.processing', filename: @@config.filename) if @@config.debug?
      registry_file = Carioca::RegistryFile.new filename: @@config.filename
      if registry_file.altered? && @@config.debug?
        debug message: i18n.t('notify.useless_entry', altered: registry_file.altered.to_s,
                                                      file_name: @@config.filename)
      end
      registry_file.validated.each do |service, spec|
        add service: service, definition: spec
      end
      debug message: i18n.t('init.registry.success') if @@config.debug?
    end
  end
end
