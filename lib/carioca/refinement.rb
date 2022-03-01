module Carioca

    module Injector
       refine Module do
            private
  
            def inject(service: )               
                self.create_method(service){return Carioca::Registry.get.get_service name: service }
            end

            def create_method(name, &block)
                self.class.send(:define_method, name, &block)
              end


            

    end
  end
end