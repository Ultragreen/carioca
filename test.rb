require 'rubygems'
require 'carioca'


Carioca::Registry.configure do |spec|
    spec.filename = '/tmp/carioca.registry'
    spec.log_file = '/tmp/test.rge'
end



class MonAppli < Carioca::Container
    def test
        logger.warn uuid.generate
    end

    inject service: :uuid
    p 

end


class Test


    def initialize
        p 'a test'
    end
end

class Other
    extend Carioca::Injector
    p active_services
    inject service: :uuid
    inject service: :test
    inject service: :untest2
    p test
    p untest2
    uuid.generate
    def titi
        p services
        p 'yes'
    end
end

test = MonAppli::new.test


test2 = Other::new
test2.titi
