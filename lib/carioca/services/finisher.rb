# coding: utf-8

# base Carioca namespace
module Carioca

    module Services

        class SpecificError < Exception
            attr_reader :error_case
            def initialize(*arg, error_case: :status_ko)
              super(*arg)
              @error_case = error_case
            end
          end

      # Exiter namespace
      class Finisher
       
        DEFAULT_FINISHERS_SPECS = {
            # global
            not_root: { code: 40, key: 'finisher.messages.not_root' },
            options_incompatibility: { code: 410, key: 'finisher.messages.options_incompatibility'},
            service_dependence_missing: { code: 430, key: 'finisher.messages.service_dependence_missing'},
            config_required: { code: 420, key: 'finisher.messages.config_required'},
            setup_error: { code: 520, key: 'finisher.messages.setup_error'},
            setup_success: { code: 0, key: 'finisher.messages.setup_success'},
            sanitycheck_error: { code: 510, key: 'finisher.messages.sanitycheck_error'},
            sanitycheck_success: { code: 0, key: 'finisher.messages.sanitycheck_success'},
            configuration_error: { code: 501, key: 'finisher.messages.configuration_error'},
            success_exit: { code: 0, key: 'finisher.messages.success_exit' },
            quiet_exit: { code: 0 },
            error_exit: { code: 50, key: 'finisher.messages.error_exit' },
            # events
            interrupt: { code: 330, key: 'finisher.messages.interrupt' },
            # request
            not_found: { code: 404, key: 'finisher.messages.not_found' },
            already_exist: { code: 408, key: 'finisher.messages.already_exist' },
            # daemon
            status_ok: { code: 200, key: 'finisher.messages.status_ok' },
            status_ko: { code: 500, key: 'finisher.messages.status_ko' }
          }

  
          def initialize
            registry = Carioca::Registry.get
            @output = registry.get_service name: :output
            @i18n = registry.get_service name: :i18n
            @configuration = registry.get_service name: :configuration
            @exit_map = DEFAULT_FINISHERS_SPECS
            @exit_map.merge! @configuration.settings.exit_cases if @configuration.settings.exit_cases
          end

          def terminate(return_case: nil, exit_case: nil, more: nil )
              raise "Case must be a return or an exit" if return_case and exit_case
              do_exit!( exit_case: exit_case, more: more) if exit_case
              do_return(return_case: return_case, more: more) if return_case
          end
  
        # exiter 
        # @option [Symbol] :case an exit case
        # @option [String] :more a complementary string to display
        def do_exit!(exit_case: :quiet_exit, more: nil )
          mess = ""
          mess = @i18n.t(@exit_map[exit_case][:key]) if @exit_map[exit_case].include? :key
          mess << " : " unless mess.empty? or not more
          mess << "#{more}" if more
          if  @exit_map[exit_case][:code] == 0 then
            @output.success mess unless mess.empty?
            exit 0
          else
            @output.fatal mess unless mess.empty?
            exit @exit_map[exit_case][:code]
          end
        end
    
        def do_return(return_case: :status_ok, more: nil )
          data = @exit_map[return_case].clone
          if data.include? :key then
            data[:message] = @i18n.t(data[:key])
            data.delete :key
          end
          data[:more] = more if more
          return data
        end

        def secure_raise(message: "unknown error", error_case: :status_ko)
            raise SpecificError::new message, error_case: error_case 
        end


        def secure_api_return(data: nil, return_case: nil, structured: false, json: true)
            result = {}
            begin
              data = yield if block_given?
              result = (structured)? do_return(return_case: return_case).merge({data: data }) : data
            rescue Exception => e
              key = (e.respond_to? :error_case)? e.error_case : :status_ko
              more  = (e.respond_to? :error_case)? e.message : "#{e.class.to_s} : #{e.message}"
              result = do_return return_case: key, more: more
            end
            result = JSON.pretty_generate(JSON.parse(result.to_json)) if json
            return result
          end


          def secure_execute!( exit_case: :success_exit )
            result = {}
            begin
              more = yield 
              
            rescue Exception => e
              key = (e.respond_to? :error_case)? e.error_case : :error_exit
              more  = (e.respond_to? :error_case)? e.message : "#{e.class.to_s} : #{e.message}"
              exit_case = key
            end
            do_exit! exit_case: exit_case, more: more
          end
    
      end
    end
  end