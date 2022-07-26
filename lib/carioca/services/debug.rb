# frozen_string_literal: false

module Carioca
  module Services
    class Debugger
      def self.get(service:, trace: Carioca::Registry.config.debugger_tracer)
        ProxyDebug.new service: service, trace: trace
      end
    end

    class ProxyDebug
      def initialize(service:, trace:)
        registry = Carioca::Registry.get
        @service = registry.get_service name: service
        @tracers = %i[output logger]
        raise "Debugger :trace is not valid : #{trace}, must be in : #{@tracers}" unless @tracers.include? trace

        @tracer = registry.get_service name: trace
        @tracer_type = trace
      end

      def method_missing(methodname, *args, **keywords, &block)
        trace message: "BEGIN CALL for service #{@service} "
        trace message: "Method called: #{methodname} "
        trace message: "args : #{args.join ' '}"
        trace message: "keywords : #{keywords}"
        if block_given?
          trace message: 'block given'
          a = @service.send(methodname, *args, **keywords, &block)
        else
          a = @service.send(methodname, *args, **keywords)
        end
        trace message: "=> method returned: #{a} "
        trace message: 'END CALL'

        a
      end

      def trace(message:)
        if @tracer_type == :output
          save = @tracer.mode
          @tracer.mode = :mono
          @tracer.debug message
          @tracer.mode = save
        else
          @tracer.debug('Carioca->ProxyDebug') { message }
        end
      end
    end
  end
end
