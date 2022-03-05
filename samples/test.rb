require 'rubygems'
require 'carioca'


Carioca::Registry.configure do |spec|
    spec.filename = './config/carioca.registry'
    spec.debug = false
    spec.init_from_file = true
    #    spec.log_file = '/tmp/test.rge'
    spec.config_file = './config/settings.yml'
    spec.config_root = :monappli
    spec.environment = :development
    spec.default_locale = :fr
    spec.log_level = :debug
    spec.output_mode = :mono

    spec.locales_load_path << Dir[File.expand_path('./config/locales') + "/*.yml"]
end


class MyService
    extend Carioca::Injector
    inject service: :logger

    def initialize
        logger.warn(self.class.to_s) {'Init service'}
    end

    def hello
        logger.info(self.class.to_s) {'Hello World'}
    end
end


spec = {
    service: 'MyService::new',
    type: :internal,
}

Carioca::Registry.init.add service: :myservice, definition: spec

logger = Carioca::Registry.get.get_service name: :logger

logger.info(self.to_s) { "avaible services : #{Carioca::Registry.get.services.keys} "} 
i18n = Carioca::Registry.get.get_service name: :i18n
i18n.locale = :es
p i18n.t(:test)

config = Carioca::Registry.get.get_service name: :configuration
config.settings.newkey = "value"

logger.info(self.to_s) { config.settings }

class MonAppli < Carioca::Container
    def test
        myservice.hello
        logger.warn(self.class.to_s) {uuid.generate}
    end

    inject service: :uuid
    inject service: :myservice
    logger.info(self.to_s) { uuid.generate }

    inject service: :output

    def test2
        cycle = [:unknown,:fatal,:error,:ko,:warn,:info,:item,:arrow,:scheduling,:trigger,:sending, :calling,:receive,:ok,:success,:debug,:flat]
        cycle.each do |verb| 
            output.send verb, verb.to_s
        end
        output.color = false
        cycle.each do |verb| 
            output.send verb, verb.to_s
        end
        output.emoji = false
        cycle.each do |verb| 
            output.send verb, verb.to_s
        end
        output.color = true
        cycle.each do |verb| 
            output.send verb, verb.to_s
        end

    end

end





appli = MonAppli::new
appli.test
appli.test2




