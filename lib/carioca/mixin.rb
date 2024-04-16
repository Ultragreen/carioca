# frozen_string_literal: true

module Carioca
  module Injector
    def inject(service:)
      create_methods(service) { return Carioca::Registry.get.get_service name: service }
    end

    def add(service:, definition:)
      Carioca::Registry.get.add service:, definition:
    end

    def services
      Carioca::Registry.get.services
    end

    def active_services
      Carioca::Registry.get.active_services
    end

    def create_methods(name, &)
      define_method(name, &)
      self.class.send(:define_method, name, &)
    end

    def self.extended(base)
      base.include self
    end
  end
end
