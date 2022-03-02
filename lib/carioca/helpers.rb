module Carioca
    module Helpers

        def log
            return self.get_service name: :logger
        end

        def debug(message: )
            log.debug(self.config.name) { "#{message}" } 
        end
    end
end