module Carioca
    module Constants

        VERSION = '2.0.0'
        DEFAULT_REGISTRY_FILE  = './carioca.registry'

        # service definitions specs
        SERVICES_MANDATORY_SPECS = {type: Symbol, service: String}
        SERVICES_FULL_LIST_SPECS = SERVICES_MANDATORY_SPECS.merge({depends: Array, description: String, resource: String })
        SERVICES_SPECS_DETAIL = {type: [:gem, :stdlib, :file, :internal]} 


        BUILTINS = {
          configuration: { 
            type: :internal,
            depends: [:logger],
            description: "The configuration service of Carioca",
            service: "Carioca::Services::Configuration::new config_file: './.config' }" },
          logger: {
            type: :stdlib,
            resource: "logger",
            description: "The Carioca Logger"
          }
        }

    end
end