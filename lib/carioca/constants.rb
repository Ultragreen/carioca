module Carioca
    module Constants

        VERSION = '2.0.1'
        DEFAULT_REGISTRY_FILE  = './config/carioca.registry'
        DEFAULT_CONFIG_FILE = './config/settings.yml'
        DEFAULT_ENVIRONMENT = :development
        DEFAULT_CONFIG_ROOT = :carioca
        DEFAULT_LOCALE = :en
        

        # service definitions specs
        SERVICES_MANDATORY_SPECS = {type: Symbol, service: String}
        SERVICES_FULL_LIST_SPECS = SERVICES_MANDATORY_SPECS.merge({depends: Array, description: String, resource: String })
        SERVICES_SPECS_DETAIL = {type: [:gem, :stdlib, :file, :internal]} 

        DEFAULT_ENVIRONMENTS_LIST = [:production, :staging, :test, :development]

        BUILTINS = {
          configuration: { 
            type: :internal,
            depends: [:logger],
            description: "The configuration service of Carioca",
            service: "Carioca::Services::Config::Factory::new(
                                 config_filename: Carioca::Registry.config.config_file, 
                                 stage: Carioca::Registry.config.environment, 
                                 root: Carioca::Registry.config.config_root)" },
          logger: {
            type: :stdlib,
            resource: "logger",
            description: "The Logger service of Carioca",
            depends: [:i18n]
          },
          i18n:{
            type: :internal,
            description: "The Internalisation service of Carocia",
            service: "Carioca::Services::I18n.get(
                                default_locale: Carioca::Registry.config.default_locale,
                                load_path: Carioca::Registry.config.locales_load_path,
                                locales_availables: Carioca::Registry.config.locales_availables)"
          }
        }

    end
end
