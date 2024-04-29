# frozen_string_literal: true

# test fo internal specific service
class MyService
  extend Carioca::Injector
  inject service: :logger
  inject service: :output

  def initialize
    logger.warn(self.class.to_s) { 'Init service' }
  end

  def hello
    output.info 'Hello World'
  end

  def method_test(_titi, tutu:)
    @tutu = tutu
    yield if block_given?
    "result #{@tutu}"
  end
end
