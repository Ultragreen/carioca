module Carioca
  module Injector
    def inject(service: )              
        self.create_methods(service){return Carioca::Registry.get.get_service name: service }
    end

    def register(service: , definition:)
      Carioca::Registry.get.add service: service, definition: definition 
    end

    def services
      Carioca::Registry.get.services
    end

    def active_services
      Carioca::Registry.get.active_services
     end

    def create_methods(name, &block)
      self.define_method name, &block
      self.class.send(:define_method, name, &block)
    end

    def self.extended(base)
      base.include self
     end
    
     

  end
  
end