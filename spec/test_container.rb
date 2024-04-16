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
      proxy = debugger.get service: :myservice
      proxy.method_test 'param', tutu: 'keyword' do
        puts 'titi'
      end
    end
  end