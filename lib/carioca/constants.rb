module Carioca
    module Constants

        VERSION = '2.0.0'
        DEFAULT_REGISTRY_FILE  = './config/carioca.registry'
        DEFAULT_CONFIG_FILE = './config/settings.yml'
        DEFAULT_ENVIRONMENT = :development
        DEFAULT_CONFIG_ROOT = :carioca

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
            description: "The Carioca Logger"
          }
        }

    end
end