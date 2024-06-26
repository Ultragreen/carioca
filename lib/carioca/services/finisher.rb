# frozen_string_literal: true

# base Carioca namespace
module Carioca
  module Services
    class SpecificError < StandardError
      attr_reader :error_case

      def initialize(*arg, error_case: :status_ko)
        super(*arg)
        @error_case = error_case
      end
    end

    class AlternativeCatcher < StandardError
      attr_reader :return_case, :data

      def initialize(*arg, return_case: :status_ko, data: nil)
        super(*arg)
        @return_case = return_case
        @data = data
      end
    end

    # Exiter namespace
    class Finisher
      DEFAULT_FINISHERS_SPECS = {
        # global
        not_root: { code: 40, key: 'finisher.messages.not_root' },
        options_incompatibility: { code: 410, key: 'finisher.messages.options_incompatibility' },
        missing_service_dependency: { code: 430, key: 'finisher.messages.missing_service_dependency' },
        config_required: { code: 420, key: 'finisher.messages.config_required' },
        setup_error: { code: 520, key: 'finisher.messages.setup_error' },
        setup_success: { code: 0, key: 'finisher.messages.setup_success' },
        sanitycheck_error: { code: 510, key: 'finisher.messages.sanitycheck_error' },
        sanitycheck_success: { code: 0, key: 'finisher.messages.sanitycheck_success' },
        configuration_error: { code: 501, key: 'finisher.messages.configuration_error' },
        success_exit: { code: 0, key: 'finisher.messages.success_exit' },
        quiet_exit: { code: 0 },
        error_exit: { code: 50, key: 'finisher.messages.error_exit' },
        # events
        interrupt: { code: 330, key: 'finisher.messages.interrupt' },
        # request & API
        not_found: { code: 404, key: 'finisher.messages.not_found' },
        already_exist: { code: 408, key: 'finisher.messages.already_exist' },
        # daemon & API
        status_ok: { code: 200, key: 'finisher.messages.status_ok' },
        created: { code: 201, key: 'finisher.messages.created' },
        accepted: { code: 202, key: 'finisher.messages.accepted' },
        bad_request: { code: 400, key: 'finisher.messages.bad_request' },
        status_ko: { code: 500, key: 'finisher.messages.status_ko' },
        no_content: { code: 204, key: 'finisher.messages.no_content' },
        not_implemented: { code: 210, key: 'finisher.messages.not_implemented' },
      }.freeze

      def initialize
        registry = Carioca::Registry.get
        @output = registry.get_service name: :output
        @i18n = registry.get_service name: :i18n
        @configuration = registry.get_service name: :configuration
        @exit_map = {}.merge DEFAULT_FINISHERS_SPECS
        @exit_map.merge! @configuration.settings.exit_cases if @configuration.settings.exit_cases
      end

      def terminate(return_case: nil, exit_case: nil, more: nil)
        raise 'Case must be a return or an exit' if return_case && exit_case

        do_exit!(exit_case:, more:) if exit_case
        do_return(return_case:, more:) if return_case
      end

      # exiter
      # @option [Symbol] :case an exit case
      # @option [String] :more a complementary string to display
      def do_exit!(exit_case: :quiet_exit, more: nil)
        mess = ''
        mess = @i18n.t(@exit_map[exit_case][:key]) if @exit_map[exit_case].include? :key
        mess << ' : ' unless mess.empty? || !more
        mess << more.to_s if more
        if (@exit_map[exit_case][:code]).zero?
          @output.success mess unless mess.empty?
          exit 0
        else
          @output.fatal mess unless mess.empty?
          exit @exit_map[exit_case][:code]
        end
      end

      def do_return(return_case: :status_ok, more: nil)
        data = @exit_map[return_case].clone
        if data.include? :key
          data[:message] = @i18n.t(data[:key])
          data.delete :key
        end
        data[:more] = more if more
        data
      end

      def secure_raise(message: 'unknown error', error_case: :status_ko)
        raise SpecificError.new(message, error_case:)
      end

      def secure_api_return(data: nil, return_case: nil, structured: false, json: true, status: true)
        result = {}
        begin
          data = yield if block_given?
          result = structured ? do_return(return_case:).merge({ data: }) : data
        rescue StandardError => e
          result = if e.respond_to?(:error_case)
                     do_return(return_case: e.error_case, more: e.message)
                   elsif e.respond_to?(:return_case)
                     structured ? do_return(return_case: e.return_case, more: e.message).merge({ data: e.data }) : e.data
                   else
                     do_return(return_case: :status_ko, more: "#{e.class} : #{e.message}")
                   end
        end
        if status && structured && json
          { status: result[:code], data: JSON.pretty_generate(JSON.parse(result.to_json)) }
        elsif json
          JSON.pretty_generate(JSON.parse(result.to_json)) if json
        else
          result
        end
      end

      def secure_alternative(message:, data:, return_case: :accepted)
        raise AlternativeCatcher.new(message, return_case:, data:)
      end

      def secure_execute!(exit_case: :success_exit)
        begin
          more = yield
          key = exit_case
        rescue StandardError => e
          key = e.respond_to?(:error_case) ? e.error_case : :error_exit
          more = e.respond_to?(:error_case) ? e.message : "#{e.class} : #{e.message}"
        end
        do_exit! exit_case: key, more:
      end
    end
  end
end
