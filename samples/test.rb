# frozen_string_literal: false

require 'rubygems'
require 'carioca'

# Configuration of Carioca
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

spec = {
  service: 'MyService::new',
  type: :internal
}


puts "\nTest 1 : access to registry : adding a internal service MyService"
Carioca::Registry.init.add service: :myservice, definition: spec

puts "\nTest 2 : list of avaible services : MyService include"
logger = Carioca::Registry.get.get_service name: :logger
logger.info(to_s) { "Available services : #{Carioca::Registry.get.services.keys} " }


puts "\nTest 3 : using MyService "
myservice = Carioca::Registry.get.get_service name: :myservice
myservice.hello



puts "\nTest 4 : Service I18n test :es, :fr, come back :en vi service output"
i18n = Carioca::Registry.get.get_service name: :i18n
output = Carioca::Registry.get.get_service name: :output
[:es,:fr,:en].each do |locale|
  i18n.locale = locale
  output.item i18n.t(:test)
end

puts "\nTest 5 : Service I18n test fallback :en on local :es for missing :es locale"
i18n.locale = :es
  output.item i18n.t(:fallback)
i18n.locale = :en

puts "\nTest 5 : Service Configuration test merge runtime form config file"
config = Carioca::Registry.get.get_service name: :configuration
pp config.settings.to_h
config.settings.newkey = 'value'


# template override sample
class MyAppli < Carioca::Container
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
    puts  "*** color and Emoji"
    cycle.each do |verb|
      output.send verb, verb.to_s
    end
    puts "*** no-color and Emoji"
    output.color = false
    cycle.each do |verb|
      output.send verb, verb.to_s
    end
    puts "*** no-color and no-Emoji"
    output.emoji = false
    cycle.each do |verb|
      output.send verb, verb.to_s
    end
    puts "*** color and no-Emoji"
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

appli = MyAppli.new
puts "\nTest 6 : Carioca::Container template and registry file service defined usage (UUID) from gem"
appli.test
puts "\nTest 7 : Service output display mode on STDOUT"
appli.test2
puts "\nTest 8 : Service debugger display mode on STDOUT"
appli.test3

output.emoji = true
output.color = true

puts "\nTest 9 : Service toolbox list of avaibles methodes"
toolbox = Carioca::Registry.get.get_service name: :toolbox
pp toolbox.describe

puts "\nTest 10 : Service toolbox test of simple methode : :user_root"
pp toolbox.user_root

puts "\nTest 11 : Service toolbox test of simple methode : :search_file_in_gem"
pp toolbox.search_file_in_gem('carioca','config/locales/en.yml')

puts "\nTest 12 : Service setup execute setup schema from configuration"
setup = Carioca::Registry.get.get_service name: :setup
setup.execute!

puts "\nTest 13 : Service finisher : test all cases"
output.item "flat api return, no-json, no-structured"
finisher = Carioca::Registry.get.get_service name: :finisher
test = finisher.secure_api_return(return_case: :status_ok, structured: false, json: false) do 
 "test"
end
puts test

output.item "api return, no-json, no-structured but with secure_raise"
test = finisher.secure_api_return(return_case: :status_ok, structured: false, json: false) do 
  finisher.secure_raise message: "error !", error_case: :status_ko
  "test"
 end
 puts test

 output.item "api return, json, structured but with secure_raise"
test = finisher.secure_api_return(return_case: :status_ok, structured: true, json: true) do 
  finisher.secure_raise message: "error !", error_case: :status_ko
 "test"
end
puts test

output.item "api return, json, structured"
test = finisher.secure_api_return(return_case: :status_ok, structured: true, json: true) do 
   "test"
end
puts test

puts "\nTest 14 : Service finisher : exit case in success"
i18n.locale = :fr
finisher.secure_execute! exit_case: :success_exit do 
  puts 'finishing action'
  #finisher.secure_raise message: "error !", error_case: :status_ko
  'message'
end