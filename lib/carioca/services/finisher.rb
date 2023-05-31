# coding: utf-8

# base Carioca namespace
module Carioca

    module Services
      # Exiter namespace
      class Finisher
        include Carioca::Constants
        extend Carioca::Injector
        inject service: :configuration
        inject service: :logger
        
        EXIT_MAP= DEFAULT_FINISHERS_SPECS.merge 
        EXIT_MAP.merge! configuration.settings.exit_cases if configuration.settings.exit_cases
  
          def self.terminate(return_case: nil, exit_case: nil, more: nil )
              raise "Case must a return or an exit" if return_case and exit_case
              do_exit( exit_case: exit_case, more: more) if exit_case
              do_return(return_case: return_case, more: more) if return_case
          end
  
        # exiter wrapper
        # @param [Hash] options
        # @option options [Symbol] :case an exit case
        # @option options [String] :more a complementary string to display
        def self.do_exit(exit_case: :quiet_exit, more: nil )
          mess = ""
          mess = EXIT_MAP[exit_case][:message] if EXIT_MAP[exit_case].include? :message
          mess << " : " unless mess.empty? or not more
          mess << "#{more}" if more
          if  EXIT_MAP[exit_case][:code] == 0 then
            logger.success mess unless mess.empty?
            exit 0
          else
            logger.fatal mess unless mess.empty?
            exit EXIT_MAP[exit_case][:code]
          end
        end
    
        def self.do_return(return_case: :status_ok, more: nil )
          data = EXIT_MAP[return_case].clone
          data[:status] = (data[:code]>0)? :failure : :success
          data[:more] = more if more
          return data
        end
    
      end
    end
  end