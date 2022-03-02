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
    service: 'Logger::new(STDOUT)'
}



class MonAppli < Carioca::Container
    def test
        logger.warn 'toto'
    end

end


test = MonAppli::new.test


