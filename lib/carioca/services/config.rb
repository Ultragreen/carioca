module Carioca
    module Services
        class Configuration
            def initialize(**keywords)
                puts 'got config'
                puts keywords
            end
        end 
    end

end