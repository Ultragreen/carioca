# frozen_string_literal: true

module Carioca
  module Services
    class Validator
      attr_reader :definition

      include Carioca::Constants

      def initialize(definition:, service:)
        @definition = definition
        @service = service
      end

      def validate!
        validate_mandatories
        validate_full_and_type
        validate_not_builtins
        fill_content
      end

      private

      def validate_not_builtins
        raise "Builtins reserved name #{@service}" if BUILTINS.keys.include? @service
      end

      def validate_mandatories
        SERVICES_MANDATORY_SPECS.each_key do |spec|
          raise "Key : :#{spec} is mandatory in a service definition" unless @definition.include? spec
        end
      end

      def validate_full_and_type
        @definition.each do |spec, value|
          raise "Key : :#{spec} is not allowed in a service definition" unless SERVICES_FULL_LIST_SPECS.include? spec
          raise "key : #{spec} must be a : #{SERVICES_FULL_LIST_SPECS[spec]}" unless value.instance_of?(SERVICES_FULL_LIST_SPECS[spec])

          raise "key : #{spec} must be in : #{SERVICES_SPECS_DETAIL[spec]}" if SERVICES_SPECS_DETAIL.include?(spec) && !(SERVICES_SPECS_DETAIL[spec].include? value)
        end
      end

      def fill_content
        @definition[:description] = @service.to_s unless @definition.include? :description
      end
    end
  end
end
