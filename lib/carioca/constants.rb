# frozen_string_literal: true

module Carioca
  module Constants
    DEFAULT_REGISTRY_FILE = './config/carioca.registry'
    DEFAULT_CONFIG_FILE = './config/settings.yml'
    DEFAULT_ENVIRONMENT = :development
    DEFAULT_CONFIG_ROOT = :carioca
    DEFAULT_LOCALE = :en

    DEFAULT_OUTPUT_TARGET = STDOUT
    DEFAULT_OUTPUT_MODE = :mono
    DEFAULT_EMOJI_STATUS = true
    DEFAULT_COLORS_STATUS = true
    DEFAULT_LOG_LEVEL = :info

    DEFAULT_USER_CONFIG_PATH = "~/.carioca"

    DEFAULT_MASTER_KEY_FILE = "#{DEFAULT_USER_CONFIG_PATH}/master.key"
    DEFAULT_SECURE_STORE_FILE = "#{DEFAULT_USER_CONFIG_PATH}/secure.Store"

    DEFAULT_DEBUGGER_TRACER = :output

    # service definitions specs
    SERVICES_MANDATORY_SPECS = { type: Symbol, service: String }.freeze
    SERVICES_FULL_LIST_SPECS = SERVICES_MANDATORY_SPECS.merge({ depends: Array, description: String,
                                                                resource: String })
    SERVICES_SPECS_DETAIL = { type: %i[gem stdlib file internal] }.freeze

    DEFAULT_ENVIRONMENTS_LIST = %i[production staging test development].freeze


    

    BUILTINS = {
      configuration: {
        type: :internal,
        depends: [:logger],
        description: 'The configuration service of Carioca',
        service: "Carioca::Services::Config::Factory::new(
                                 config_filename: Carioca::Registry.config.config_file,
                                 stage: Carioca::Registry.config.environment,
                                 root: Carioca::Registry.config.config_root)"
      },
      logger: {
        type: :stdlib,
        resource: 'logger',
        description: 'The Logger service of Carioca',
        depends: [:i18n]
      },
      i18n: {
        type: :internal,
        description: 'The Internalisation service of Carocia',
        service: "Carioca::Services::I18n.get(
                                default_locale: Carioca::Registry.config.default_locale,
                                load_path: Carioca::Registry.config.locales_load_path,
                                locales_availables: Carioca::Registry.config.locales_availables)"
      },
      output: {
        type: :internal,
        description: 'The Output service of Carioca',
        service: "Carioca::Services::Output::Provider::new(
                                mode: Carioca::Registry.config.output_mode,
                                emoji: Carioca::Registry.config.output_emoji?,
                                colors: Carioca::Registry.config.output_colors?,
                                level: Carioca::Registry.config.log_level,
                                target: Carioca::Registry.config.output_target
            )"
      },
      finisher: {
        type: :internal,
        service: 'Carioca::Services::Finisher::new',
        description: 'The Finisher service of Carioca',
        depends: [:i18n,:logger, :configuration]
      },
      toolbox: {
        type: :internal,
        service: 'Carioca::Services::Toolbox',
        description: 'The Misceleanous Toolbox service of Carioca',
      },
      setup: {
        type: :internal,
        service: 'Carioca::Services::Setup::new',
        description: 'The Setup service of Carioca',
        depends: [:i18n,:logger, :configuration ]
      },
      sanitycheck: {
        type: :internal,
        service: 'Carioca::Services::Sanitycheck::new',
        description: 'The Sanitycheck service of Carioca',
        depends: [:i18n,:logger, :configuration ]
      },
      securestore: {
        type: :internal,
        service: 'Carioca::Services::SecureStore::new',
        description: 'The SecureStore service of Carioca',
        depends: [:i18n,:logger, :configuration ]
      },
      debugger: {
        type: :internal,
        description: 'The Debugger Service of Carioca',
        service: 'Carioca::Services::Debugger'
      }
    }.freeze
  end
end
