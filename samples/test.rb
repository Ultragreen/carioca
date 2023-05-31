# frozen_string_literal: false

require 'rubygems'
require 'carioca'

Carioca::Registry.configure do |spec|
  spec.filename = './config/carioca.registry'
  spec.debug = false
  spec.init_from_file = true
  spec.log_file = '/tmp/test.rge'
  spec.config_file = './config/settings.yml'
  spec.config_root = :myappli
  spec.environment = :development
  spec.default_locale = :fr
  spec.log_level = :debug
  spec.output_mode = :dual
  spec.output_emoji = true
  spec.output_colors = true
  spec.locales_load_path << Dir["#{File.expand_path('./config/locales')}/*.yml"]
  spec.debugger_tracer = :output
end

class MyService
  extend Carioca::Injector
  inject service: :logger

  def initialize
    logger.warn(self.class.to_s) { 'Init service' }
  end

  def hello
    logger.info(self.class.to_s) { 'Hello World' }
  end

  def method_test(_titi, tutu:)
    @tutu = tutu
    yield if block_given?
    "result #{@tutu}"
  end
end

spec = {
  service: 'MyService::new',
  type: :internal
}

Carioca::Registry.init.add service: :myservice, definition: spec

logger = Carioca::Registry.get.get_service name: :logger

logger.info(to_s) { "Available services : #{Carioca::Registry.get.services.keys} " }
i18n = Carioca::Registry.get.get_service name: :i18n
i18n.locale = :es
p i18n.t(:test)

config = Carioca::Registry.get.get_service name: :configuration

puts config.settings.to_h.to_yaml
config.settings.newkey = 'value'

logger.info(to_s) { config.settings }

class MonAppli < Carioca::Container
  def test
    myservice.hello
    logger.warn(self.class.to_s) { uuid.generate }
  end

  inject service: :uuid
  inject service: :myservice
  logger.info(to_s) { uuid.generate }

  inject service: :output
  inject service: :debugger

  def test2
    cycle = %i[unknown fatal error ko warn info item arrow scheduling trigger sending calling receive
               ok success debug flat]
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

  def test3
    proxy = debugger.get service: :myservice
    proxy.method_test 'param', tutu: 'keyword' do
      puts 'titi'
    end
  end
end

appli = MonAppli.new
appli.test
appli.test2
appli.test3



toolbox = Carioca::Registry.get.get_service name: :toolbox
p toolbox.methods(false)

setup = Carioca::Registry.get.get_service name: :setup
setup.execute!

finisher = Carioca::Registry.get.get_service name: :finisher



test = finisher.secure_api_return(return_case: :status_ok, structured: false, json: false) do 
 "test"
end
puts test
test = finisher.secure_api_return(return_case: :status_ok, structured: false, json: false) do 
  finisher.secure_raise message: "error !", error_case: :status_ko
  "test"
 end
 puts test

test = finisher.secure_api_return(return_case: :status_ok, structured: true, json: true) do 
  finisher.secure_raise message: "error !", error_case: :status_ko
 "test"
end
puts test

test = finisher.secure_api_return(return_case: :status_ok, structured: true, json: true) do 
   "test"
end
puts test

i18n.locale = :fr
finisher.secure_execute! exit_case: :success_exit do 
  puts 'finishing action'
  #finisher.secure_raise message: "error !", error_case: :status_ko
  'message'
end