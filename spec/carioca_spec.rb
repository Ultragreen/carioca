# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'uuid'
  gem 'carioca'
end

RSpec.describe Carioca do
  before :all do
    # Configuration of Carioca

    Carioca::Registry.configure do |spec|
      spec.filename = './spec/config/carioca.registry'
      spec.debug = false
      spec.init_from_file = true
      spec.log_file = '/tmp/test.rge'
      spec.config_file = './spec/config/settings.yml'
      spec.config_root = :myappli
      spec.environment = :development
      spec.default_locale = :fr
      spec.log_level = :debug
      spec.output_mode = :dual
      spec.output_emoji = true
      spec.output_colors = true
      spec.locales_load_path << Dir["#{File.expand_path('./spec/config/locales')}/*.yml"]
      spec.debugger_tracer = :output
    end

    require_relative 'sample_service'
    require_relative 'test_container'
  end

  it 'has a version number' do
    expect(Carioca::VERSION).not_to be nil
  end

  context 'Testing own Service, Logger & Output Service' do
    it 'must access to registry : adding a internal service MyService' do
      spec = {
        service: 'MyService::new',
        type: :internal
      }
      Carioca::Registry.init.add service: :myservice, definition: spec
    end

    it 'must be possible to list of avaible services : MyService include' do
      logger = Carioca::Registry.get.get_service name: :logger
      logger.info(to_s) { "Available services : #{Carioca::Registry.get.services.keys} " }
    end

    unless ENV['GITHUB_ACTIONS']
      it 'must be possible to use output service' do
        output = Carioca::Registry.get.get_service name: :output
        expect { output.info 'test' }.to output("ℹ \e[36mtest\e[0m\n").to_stdout
      end
    end

    unless ENV['GITHUB_ACTIONS']
      it 'must be possible to use  MyService' do
        myservice = Carioca::Registry.get.get_service name: :myservice
        expect { myservice.hello }.to output("ℹ \e[36mHello World\e[0m\n").to_stdout
      end
    end
  end

  context 'I18n Service' do
    it 'must be possible to use the I18n service with locales :es, :fr, :en via output service' do
      i18n = Carioca::Registry.get.get_service name: :i18n
      output = Carioca::Registry.get.get_service name: :output
      unless ENV['GITHUB_ACTIONS']
        { es: 'español', fr: 'français', en: 'english' }.each do |locale, result|
          i18n.locale = locale
          expect { output.item i18n.t(:test) }.to output(" 🔹 \e[37m#{result}\e[0m\n").to_stdout
        end
      end
    end

    unless ENV['GITHUB_ACTIONS']
      it 'must be possible to use the I18n service and test fallback :en on local :es for missing :es locale' do
        i18n = Carioca::Registry.get.get_service name: :i18n
        output = Carioca::Registry.get.get_service name: :output
        i18n.locale = :es
        expect { output.item i18n.t(:fallback) }.to output(" 🔹 \e[37menglish fallback\e[0m\n").to_stdout
        i18n.locale = :en
      end
    end
  end

  context 'Configuration Service' do
    it 'must be possible to use Configuration service retrieving all merged data for :development environnement ' do
      result_tree = { default_value: 'value',
                      treeA: { trunk1: { branch2: 'leaf2', branch1: 'leaf1' }, trunk2: { branch5: %w[value val1 val2 val3], branch3: 'leaf3', branch4: 'leaf4' } },
                      setup: { rules: [{ action: :install_file, source: 'samples/config/settings.yml', target: '/tmp/settings.yml' },
                                       { action: :install_file, source: 'samples/config/carioca.registry', target: '/tmp/carioca.registry', mode: '755' },
                                       { action: :make_folder, path: '/tmp/toto', mode: '755' },
                                       { action: :make_link, source: '/tmp/settings.yml', link: '/tmp/application.yml' }] },
                      sanitycheck: { rules: [{ test: :verify_file, name: '/tmp/carioca.registry', mode: '755' }, { test: :verify_folder, name: '/tmp/toto', mode: '755' }, { test: :verify_link, name: '/tmp/application.yml' }] },
                      ondev: 'test' }
      config = Carioca::Registry.get.get_service name: :configuration
      expect(config.settings.to_h).to eq result_tree
    end

    it 'must be possible to add new data on runtime' do
      config = Carioca::Registry.get.get_service name: :configuration
      config.settings.newkey = 'value'
      expect(config.settings.newkey).to eq 'value'
    end

    it 'must be possible to override data on runtime' do
      config = Carioca::Registry.get.get_service name: :configuration
      config.settings.trunk1.branch2 = 'newleaf'
      expect(config.settings.trunk1.branch2).to eq 'newleaf'
    end
  end

  context 'Container test (Output, Self service, Debugger and registry config service type :gem)' do
    unless ENV['GITHUB_ACTIONS']
      it 'must be possible to use Carioca Container with Config file defined gem service in registry UUID (logging) see : /tmp/test.rge' do
        appli = MyAppli.new
        expect { appli.test }.to output("ℹ \e[36mHello World\e[0m\n").to_stdout
      end
    end

    unless ENV['GITHUB_ACTIONS']
      it 'must be possible to use Carioca Container with debbugger service for own service' do
        appli = MyAppli.new
        expect { appli.test2 }.to output("🐛 \e[35mBEGIN CALL for service MyService\e[0m\n🐛 \e[35mMethod called: method_test\e[0m\n🐛 \e[35margs : param\e[0m\n🐛 \e[35mkeywords : {:tutu=>\"keyword\"}\e[0m\n🐛 \e[35mblock given\e[0m\ntiti\n🐛 \e[35m=> method returned: result keyword\e[0m\n🐛 \e[35mEND CALL\e[0m\n").to_stdout
      end
    end
  end

  context 'Service Toolbox' do
    it 'muts be possible to get the Service Toolbox list of availables methodes' do
      toolbox = Carioca::Registry.get.get_service name: :toolbox
      expect(toolbox.describe).to eq({
                                       get_processes: 'Get the list of running processus',
                                       root?: 'Verify if active current processus is running as root',
                                       check_unicode_term: 'Check if terminal support unicode',
                                       user_root: 'Get the local system root username ',
                                       group_root: 'Get the local system root groupname ',
                                       search_file_in_gem: 'Retrieve absolute path of a file in a specific gem'
                                     })
    end

    it 'must be possible to use one of the method from Service toolbox : :user_root' do
      toolbox = Carioca::Registry.get.get_service name: :toolbox
      expect(toolbox.user_root).to eq 'root'
    end

    it 'must be possible to use one of the method from Service toolbox : :search_file_in_gem' do
      toolbox = Carioca::Registry.get.get_service name: :toolbox
      expect(Pathname.new(toolbox.search_file_in_gem(gem: 'carioca', file: 'config/locales/en.yml'))).to exist
    end
  end

  context 'Setup and Sanitycheck Service' do
    unless ENV['GITHUB_ACTIONS']
      it 'must be possible on Service setup to execute setup schema from configuration' do
        setup = Carioca::Registry.get.get_service name: :setup
        expect { setup.execute! }.to output("ℹ \e[36mBegining setup :\e[0m\n 🔹 \e[37mInstallation of file /tmp/settings.yml\e[0m\n 🔹 \e[37mInstallation of file /tmp/carioca.registry\e[0m\n 🔹 \e[37mCreation of folder /tmp/toto\e[0m\n 🔹 \e[37mCreation of symlink /tmp/application.yml -> /tmp/settings.yml\e[0m\n").to_stdout
      end
    end
    unless ENV['GITHUB_ACTIONS']
      it 'must be possible on Service sanitycheck to run checking schema from configuration' do
        sanitycheck = Carioca::Registry.get.get_service name: :sanitycheck
        expect { sanitycheck.run }.to output("ℹ \e[36mBegining sanitycheck :\e[0m\n👍 \e[32mTestcase verify_file on /tmp/carioca.registry is ok\e[0m\n👍 \e[32mTestcase verify_folder on /tmp/toto is ok\e[0m\n👍 \e[32mTestcase verify_link on /tmp/application.yml is ok\e[0m\n💪 \e[32mSanitycheck finish without errors\e[0m\n").to_stdout
      end
    end
  end

  context 'SecureStore Service' do
    it 'must be possible to use Service SecureStore init or access and store data in' do
      securestore = Carioca::Registry.get.get_service name: :securestore
      res = securestore.data.empty? ? { time: 'first time' } : securestore.data
      expect(res[:time]).to be_an_instance_of String
    end

    it 'must be possible to use Service SecureStore for setting new data' do
      securestore = Carioca::Registry.get.get_service name: :securestore
      securestore.data[:time] = Time.now.to_s
      securestore.save!
    end
  end

  context 'Finisher Service' do
    it 'must be possible to use Service finisher for flat api return, no-json, no-structured' do
      finisher = Carioca::Registry.get.get_service name: :finisher
      result = finisher.secure_api_return(return_case: :status_ok, structured: false, json: false) do
        'test'
      end
      expect(result).to eq 'test'
    end

    it 'must be possible to use Service finisher for api return, no-json, no-structured but with secure_raise' do
      finisher = Carioca::Registry.get.get_service name: :finisher
      result = finisher.secure_api_return(return_case: :status_ok, structured: false, json: false) do
        finisher.secure_raise message: 'error !', error_case: :status_ko
        'test'
      end
      expect(result).to eq({ code: 500, message: 'Status KO', more: 'error !' })
    end

    it 'must be possible to use Service finisher for api return, json, structured but with secure_raise' do
      finisher = Carioca::Registry.get.get_service name: :finisher
      result = finisher.secure_api_return(return_case: :status_ok, structured: true, json: true) do
        finisher.secure_raise message: 'error !', error_case: :status_ko
        'test'
      end
      expect(result[:status]).to eq 500
      expect(JSON.parse(result[:data], symbolize_names: true)).to eq({ code: 500, message: 'Status KO', more: 'error !' })
    end

    it 'must be possible to use Service finisher for api return, json, structured' do
      finisher = Carioca::Registry.get.get_service name: :finisher
      result = finisher.secure_api_return(return_case: :status_ok, structured: true, json: true) do
        'test'
      end
      expect(result[:status]).to eq 200
      expect(JSON.parse(result[:data], symbolize_names: true)).to eq({ code: 200, message: 'Status OK', data: 'test' })
    end

    it 'must be possible to use Service finisher for api return, json, structured with status=false' do
      finisher = Carioca::Registry.get.get_service name: :finisher
      result = finisher.secure_api_return(return_case: :status_ok, structured: true, json: true, status: false) do
        'test'
      end
      expect(JSON.parse(result, symbolize_names: true)).to eq({ code: 200, message: 'Status OK', data: 'test' })
    end

    it 'must be possible to use Service finisher for api return, json, structured but raising unknown case' do
      finisher = Carioca::Registry.get.get_service name: :finisher
      test = finisher.secure_api_return(return_case: :status_ok, structured: true, json: true) do
        raise 'Boom'
      end
      expect(test[:status]).to eq 500
      expect(JSON.parse(test[:data], symbolize_names: true)).to eq({ code: 500, message: 'Status KO', more: 'RuntimeError : Boom' })
    end

    it 'must be possible to use Service finisher for api return, json, structured with alternative' do
      finisher = Carioca::Registry.get.get_service name: :finisher
      i18n = Carioca::Registry.get.get_service name: :i18n
      i18n.locale = :en
      test = finisher.secure_api_return(return_case: :status_ok, structured: true, json: true) do
        data = { test: 'test' }
        finisher.secure_alternative(message: 'test alernative', return_case: :accepted, data:)
        data
      end
      expect(test[:status]).to eq 202
      expect(JSON.parse(test[:data], symbolize_names: true)).to eq({ code: 202, message: 'Request accepted', data: { test: 'test' }, more: 'test alernative' })
    end

    it 'must be possible to use Service finisher for api return, no json, not structured with alternative' do
      finisher = Carioca::Registry.get.get_service name: :finisher
      test = finisher.secure_api_return(return_case: :status_ok, structured: false, json: false) do
        data = { test: 'test' }
        finisher.secure_alternative(message: 'test alernative', return_case: :accepted, data:)
        data
      end
      expect(test).to eq({ test: 'test' })
    end
  end
end
