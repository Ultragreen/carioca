
module Carioca
    class Container

        using Carioca::Injector

        inject service: :logger
        inject service: :configuration

        def initialize(name: 'Carioca')
            @name = name
        end

    end

end
