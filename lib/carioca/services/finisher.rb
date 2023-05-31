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
            not_root: { message: "This operation need to be run as root (use sudo or rvmsudo)", code: 40},
            options_incompatibility: { message: "Options incompatibility", code: 410},
            service_dependence_missing: { message: "Appifier Service dependence missing", code: 430},
            config_required: { message: "Specific configuration required", code: 420},
            setup_error: { message: "Setup terminated unsuccessfully", code: 520},
            setup_success: { message: "Setup terminated successfully", code: 0},
            sanitycheck_error: { message: "Sanitycheck terminated unsuccessfully", code: 510},
            sanitycheck_success: { message: "Sanitycheck terminated successfully", code: 0},
            configuration_error: { message: "Configuration Error", code: 501},
            success_exit: { code: 0 , message: "Operation sucessfull" },
            quiet_exit: { code: 0 },
            error_exit: { code: 50, message: "Operation failure" },
            # events
            interrupt: { message: "User operation interrupted", code: 330 },
            # request
            not_found: { message: "Object not found", code: 404 },
            already_exist: { message: "Object already exist", code: 408 },
            # daemon
            status_ok: { message: "Status OK", code: 200 },
            status_ko: { message: "Status KO", code: 500 }
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
  
        # exiter wrapper
        # @param [Hash] options
        # @option options [Symbol] :case an exit case
        # @option options [String] :more a complementary string to display
        def do_exit!(exit_case: :quiet_exit, more: nil )
          mess = ""
          mess = @exit_map[exit_case][:message] if @exit_map[exit_case].include? :message
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