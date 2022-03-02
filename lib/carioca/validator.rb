module Carioca
    module Services
        class Validator

            attr_reader :definition

            MANDATORY_SPECS = {type: Symbol, resource: String,  service: String}
            FULL_LIST_SPECS = MANDATORY_SPECS.merge({depends: Array, description: String })
            SPECS_DETAIL = {type: [:builtin, :gem, :stdlib, :file]} 
            def initialize(definition: , service: )
                @definition = definition
                @service = service.to_s
            end 

            def validate!
                validate_mandatories
                validate_full_and_type
                fill_content
            end

            private
            def validate_mandatories
                MANDATORY_SPECS.keys.each do |spec|
                    raise "Key : :#{spec} is mandatory in a service definition" unless @definition.include? spec
                end
            end

            def validate_full_and_type
                @definition.each do |spec,value|
                    raise "Key : :#{spec} is not allowed in a service definition" unless FULL_LIST_SPECS.include? spec
                    raise "key : #{spec} must be a : #{FULL_LIST_SPECS[spec].to_s}" unless value.class == FULL_LIST_SPECS[spec]
                    if SPECS_DETAIL.include? spec then
                        raise "key : #{spec} must be in : #{SPECS_DETAIL[spec].to_s}" unless SPECS_DETAIL[spec].include? value
                    end
                end
            end

            def fill_content
                @definition[:description] = @service unless @definition.include? :description
            end

        end
    end
end