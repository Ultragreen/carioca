# frozen_string_literal: true

module Carioca
  class Container
    extend Carioca::Injector

    inject service: :logger
    inject service: :configuration

    def initialize(name: 'Carioca')
      @name = name
    end
  end
end
