require 'rubygems'
require 'carioca'


Carioca::Registry.configure do |spec|
    spec.filename = '/tmp/carioca.registry'
end

registry = Carioca::Registry.init
registry.add service: :logger, definition: {
    type: :stdlib,
    resource: 'logger',
    description: "A logger",
    service: 'Logger'
}
p Carioca::Registry.config



class Application
    using Carioca::Injector

    inject service: :configuration
    inject service: :logger

    p configuration.class

    logger.info 'test'

end