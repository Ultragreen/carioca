require'rubygems'
require'rspec'
require 'carioca'
require 'fileutils'

$debug = true

describe Carioca do

  before :all do 
    FileUtils.rm_rf("/tmp/log.file")
    File::unlink('/tmp/dorsal/ringserver.pid') if File::exist?('/tmp/dorsal/ringserver.pid')
    File::unlink('/tmp/dorsal/service-distdummy.pid') if File::exist?('/tmp/dorsal/service-distdummy.pid')
    pid = `ps aux|grep ruby|grep -v grep |grep 'Ultragreen Ring Server'|awk '{ print $2}'`
    unless pid.empty? then
      res = `kill -TERM #{pid.chomp}`
    end
    pid = `ps aux|grep ruby|grep -v grep |grep 'a dummy test service'|awk '{ print $2}'`
    unless pid.empty? then
      res = `kill -TERM #{pid.chomp}`
    end
    $carioca = Carioca::Services::Registry.init :file => 'spec/config/services.registry', :debug => $debug
  end  
  
  subject { Carioca }
  it { should be_an_instance_of Module}
  context "Carioca::Services" do
    subject { Carioca::Services }
    it { should be_an_instance_of Module }
  end
  
  context "Carioca::Services::Registry"  do
    subject { $carioca }
    context "#init" do 
      it "should be a Singleton" do 
        carioca1 = Carioca::Services::Registry.init
        carioca2 = Carioca::Services::Registry.init
        test = (carioca1.inspect == carioca2.inspect)
        test.should be true
      end
      

      it { should be_an_instance_of Carioca::Services::Registry }
      it { $carioca.list.keys.should include "logger" }
      it "should log Registry starting and logger init if debug mode", :if => $debug do
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Registry started, service logger preloaded/).size.should eq 1
      end
      it "should not log Registry starting and logger init if not debug mode", :unless => $debug do
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Registry started, service logger preloaded/).size.should eq 0
      end


      it "should be possible to log with this primary service" do
        $logger = subject.get_service :name => 'logger'
        $logger.info("test").should eq true 
        open('/tmp/log.file').grep(/INFO -- : test/).size.should eq 1
        $logger.warn("test").should eq true
        open('/tmp/log.file').grep(/WARN -- : test/).size.should eq 1
        $logger.error("test").should eq true
        open('/tmp/log.file').grep(/ERROR -- : test/).size.should eq 1
        $logger.fatal("test").should eq true
        open('/tmp/log.file').grep(/FATAL -- : test/).size.should eq 1
        $logger.info("Program") { "running" }
        open('/tmp/log.file').grep(/INFO -- Program: running/).size.should eq 1
      end
    end

    context "attributs" do
      context "#debug (RW)" do
        it { should respond_to :debug }
        it { should respond_to :debug= }
        it "should be true if debug mode", :if => $debug do 
          subject.debug.should eq true 
        end
        it "should be false if not debug mode", :unless => $debug do
          subject.debug.should eq false 
        end
      end

      context "#name (RW)" do
        it { should respond_to :name }
        it { should respond_to :name= }
        it { $carioca.name.should be_an_instance_of String }
        it  { $carioca.name.should eq 'Carioca'}
      end

      context "#list (RO)" do
        it { should respond_to :list }
        it { should_not respond_to :list= }
        it { subject.list.should be_an_instance_of Hash }
        it  { $carioca.list.keys.sort.should eq ["configuration", "debug", "distdummy","dorsal", "dummy", "logger", "uuid", "uuidbygemfile"] }
      end

      context "#loaded_services (RO)" do
        it { should respond_to :loaded_services }
        it { should_not respond_to :loaded_services= }
        it { subject.loaded_services.should be_an_instance_of Hash }
        it { $carioca.loaded_services.keys.should eq ["logger"] }
      end
      
      context "#registry_filename" do
        it { should respond_to :registry_filename }
        it { should respond_to :registry_filename= }
        it { subject.registry_filename.should be_an_instance_of String }
        it { $carioca.registry_filename.should eq "spec/config/services.registry" }
      end

    end

    context "#start_service" do 
      it { should respond_to :start_service }
      it { should respond_to :get_service }

      context "Builtin services" do
        context "Logger service" do
          it "should be possible to get the builtin logger service" do 
            $logger = subject.get_service :name => 'logger'
          end
          it "should log if debug mode", :if => $debug do 
            open('/tmp/log.file').grep(/DEBUG -- Carioca: getting service logger/).size.should >= 1
          end
          it "should not log if debug mode", :unless => $debug do 
            open('/tmp/log.file').grep(/DEBUG -- Carioca: getting service logger/).size.should eq 0
          end
        end
        

        context "Debug Proxy Service" do
          it "should start the builtin service debug" do 
            myservice = subject.start_service :name => 'debug' , :params => {:service => 'dummy'}
            myservice.test 'titi'            
          end
          it { subject.list.keys.should include "debug" }
          it "should log a proxy service log sequence", :if => $debug do 
            open('/tmp/log.file').grep(/DEBUG -- ProxyDebug: BEGIN CALL for mapped service dummy/).size.should eq 1 
            open('/tmp/log.file').grep(/DEBUG -- ProxyDebug: called: test/).size.should eq 1 
            open('/tmp/log.file').grep(/DEBUG -- ProxyDebug: args : titi/).size.should eq 1
            open('/tmp/log.file').grep(/DEBUG -- ProxyDebug: => returned: OK/).size.should eq 1 
            open('/tmp/log.file').grep(/DEBUG -- ProxyDebug: END CALL/).size.should eq 1
          end
        end
        
        context "Configuration Service" do
          it "should start the builtin configuration service" do
            $conf = subject.start_service :name => 'configuration' 
          end
          it "should access flat settings" do
            $conf.settings.context1.key0.should eq 'value'
            $conf.settings.context1.node.key1 eq 'value1'
            $conf.settings.context1.node.key2 eq 'value2'
            $conf.settings.context2.key0.should eq 'value'
            $conf.settings.context2.node.key1 eq 'value3'
            $conf.settings.context2.node.key2 eq 'value4'            
          end
          it "should access contextualized settings" do
            $conf = subject.restart_service :name => 'configuration', :params => { :context => 'context2' }
            $conf.settings.key0.should eq 'value'
            $conf.settings.node.key1 eq 'value3'
            $conf.settings.node.key2 eq 'value4'            
          end
          it "should access inherited settings from YAML" do
            $conf = subject.restart_service :name => 'configuration', :params => { :context => 'context3' }
            $conf.settings.key0.should eq 'value'
            $conf.settings.node.key1 eq 'value3'
            $conf.settings.node.key2 eq 'value4'            
          end
          it "should be possible to override a config value" do 
            $conf.settings.node.key2 = 'value8'
            $conf.settings.node.key2.should eq 'value8'
            $conf.settings[:node][:key2] = 'value6'
            $conf.settings[:node][:key2].should eq 'value6'
          end
          it { $conf.should respond_to :config_file }
          it { $conf.should respond_to :config_file= }
          it { $conf.should respond_to :save! }
          
          it "should be saved in other file" do 
            $conf.config_file = '/tmp/.config'
            $conf.save!.should be true
            
          end
          it "should stop the configuration service" do
            subject.stop_service({:name => 'configuration'}).should eq true
          end
        end
        
      end

      context "External services" do
        
        it "should start a dummy service precised in registry YAML configuration" do 
          
          $dummy = subject.start_service :name => 'dummy'
          $dummy.should be_an_instance_of ExternalServices::Dummy
        end
        it { subject.list.keys.should include "dummy" }
        it "should be possible to use test method of the dummy service, and return 'OK'" do
          $dummy.test.should eq 'OK'
        end
        it "should start a gem service precised in registry YAML configuration" do
          $uuid = subject.start_service :name => 'uuid'
          $uuid.should be_an_instance_of UUID
        end
        it { subject.list.keys.should include "uuid" }
        it "should be possible to execute a method with the gem service" do
          $uuid.generate.should be_a_kind_of String
        end
        it "should start a file in gem service precised by gem_file in registry YAML configuration" do
          $uuidgemfile = subject.start_service :name => 'uuidbygemfile'
          $uuidgemfile.should be_an_instance_of UUID
        end
        it { subject.list.keys.should include "uuidbygemfile" }
        it { subject.loaded_services.keys.should include "uuidbygemfile" }
        it "should be possible to execute a method with the gem_file service" do
          $uuidgemfile.generate.should be_a_kind_of String
          subject.stop_service :name => "uuidbygemfile"
        end


        context "Distributed service" do
          it "should be possible to execute a distributed service" do 
            $dummy_dist = subject.start_service :name => 'distdummy'        
          end
          it "should exist a processus Ring server" do 
            File::exist?('/tmp/dorsal/ringserver.pid').should be_true
            pid = `ps aux|grep ruby|grep -v grep |grep 'Ultragreen Ring Server'|awk '{ print $2}'`
            pid.should_not be_empty
          end
          it "should log if debug mode", :if => $debug do
            open('/tmp/log.file').grep(/DEBUG -- Carioca: Starting new Ring Server/).size.should >= 1
          end
          it "should not log if debug mode", :unless => $debug do
            open('/tmp/log.file').grep(/DEBUG -- Carioca: Starting new Ring Server/).size.should eq 0
          end
          it "should include 'distdummy' in @loaded_services.keys" do
            subject.loaded_services.should include "distdummy"
          end
          it "should distdummy be a DRbObject" do 
            $dummy_dist.should be_a_kind_of DRb::DRbObject
          end
          it "should be possible to use test method of the distributed dummy service, and return 'OK'" do
            $dummy_dist.test.should eq 'OK'
          end 
        end

      end
    end


    context "#stop_service" do
      it { should respond_to :stop_service }
      it "should raise ArgumentError if the option hash argument passed not include :name" do
        lambda { subject.stop_service }.should raise_error ArgumentError
        lambda { subject.stop_service(:notname => 'debug') }.should raise_error ArgumentError
      end
      it "should return true if service really stop" do
        subject.stop_service({:name => 'dummy'}).should eq true
      end
      it "should log if debug mode", :if => $debug do 
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Service dummy stopped/).size.should >= 1
      end
      it "should not log if debug mode", :unless => $debug do 
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Service dummy stopped/).size.should eq 0
      end
      it "should return false if service not already running" do
        subject.stop_service({:name => 'dum'}).should eq false
      end
      it "should log if debug mode and service not loaded", :if => $debug do 
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Service dum not loaded/).size.should >= 1
      end
      it "should not log if debug mode and service not loaded", :unless => $debug do 
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Service dum not loaded/).size.should eq 0
      end
      it "should return false if service :name is logger" do
        subject.stop_service({:name => 'logger'}).should eq false
      end
      it "should log if debug mode and service :name is logger", :if => $debug do
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Service logger can't be unloaded/).size.should >= 1
      end
      it "should not log if debug mode and service :name is logger", :unless => $debug do
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Service logger can't be unloaded/).size.should eq 0
      end

      context "Distributed Service" do
        it "should be possible to stop a distributed service" do
          $dummy_dist = subject.start_service :name => 'distdummy'        
          subject.stop_service({:name => 'distdummy'}).should be_true        
        end
        it "should not exist forked daemon instance for this stopped service" do
          pid = `ps aux|grep ruby|grep -v grep |grep 'a dummy test service'|awk '{ print $2}'`
          pid.should be_empty
        end
        it "should not exist the pid file of this stopped services" do
          File::exist?('/tmp/dorsal/service-distdummy.pid').should be_false
          $dummy_dist = subject.start_service :name => 'distdummy'
        end
      end
      
    end

    context "#restart_service" do
      it { should respond_to :start_service }
      it "should start an instance of a service like dummy_one" do 
        $dummy = subject.restart_service :name => 'dummy_one'
        $dummy = subject.restart_service :name => 'dummy'
        $dummy.should be_an_instance_of ExternalServices::Dummy
        $carioca.loaded_services.keys.should include 'dummy' 
        $carioca.loaded_services.keys.should include 'dummy_one'
      end
      it "should restart a service already loaded and log it" do
        $dummy = subject.restart_service :name => 'dummy'
      end

      context "Distributed service" do
        it "should ne possible to restart a distributed service" do
          $dummy_dist = subject.restart_service :name => 'distdummy'
        end
        it "should log it if debug mode", :if => $debug do
          open('/tmp/log.file').grep(/DEBUG -- Carioca: Restarting distributed service distdummy/).size.should eq 1
        end
      end

      it "should log it if debug mode", :if => $debug do
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Restarting service dummy/).size.should eq 1
      end
      it "should not log it if not debug mode", :if => $debug do
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Restarting service dummy/).size.should eq 1
      end

    end


    context "#unregister_service" do
      it { should respond_to :unregister_service }
      it "should be possible te unregistered the configuration service" do 
        subject.list.keys.should include "configuration"
        subject.unregister_service :name => "configuration"
        subject.list.keys.should_not include "configuration"
      end
      it "should raise RegistryError if trying to unregister logger" do
        lambda { subject.unregister_service :name => "logger"}.should raise_error RegistryError
      end
      it "should raise RegistryError if trying to unregister a loaded service" do
        lambda { subject.unregister_service :name => "dummy"}.should raise_error RegistryError
      end
      
    end

    context "#discover_builtins" do
      it { should respond_to :discover_builtins }
      it "should rebuild builtin service in @list" do 
        subject.discover_builtins
        subject.list.keys.should include "configuration" 
      end
    end

    context "#register_service" do
      it { should respond_to :register_service }
      it "should add a new service" do 
        subject.register_service :name => 'otherdummy', 
                                 :type => :file, 
                                 :resource => './spec/samples/otherdummy.rb', 
                                 :service =>'ExternalServices::OtherDummy',
                                 :description => 'An other Dummy Service',
                                 :requires => ['requireddummy']
      end
      it "should raised RegistryError if started without a registered required service" do
        lambda { subject.start_service :name => 'otherdummy' }.should raise_error RegistryError
      end
      it "should follow requires when started" do
        subject.register_service :name => 'requireddummy',
                                 :type => :file,
                                 :resource => './spec/samples/requireddummy.rb',
                                 :service =>'ExternalServices::RequiredDummy',
                                 :description => 'An other Dummy Service'
        subject.start_service :name => 'otherdummy'
        open('/tmp/log.file').grep(/DEBUG -- Carioca: Registry dependancy found and not loaded : requireddummy/).size.should eq 1 if $debug
        subject.loaded_services.keys.should include 'requireddummy'
        subject.loaded_services.keys.should include 'otherdummy'
      end
      it "should raise Argument error if :type is not :gem, :file, :gem_file or :builtin" do 
        lambda { subject.register_service :name => 'otherdummy', 
                                 :type => :error, 
                                 :resource => 'spec/samples/otherdummy.rb', 
                                 :service =>'ExternalServices::OtherDummy',
                                 :description => 'An other Dummy Service'}.should raise_error ArgumentError

      end
    end



    
    
    context "#save!" do
      it { should respond_to :save! }
      it "should save the config to an other file @registry_filename" do 
        File::unlink('/tmp/test.reg') if File::exist?('/tmp/test.reg')
        prev = subject.registry_filename
        subject.registry_filename = '/tmp/test.reg'
        subject.save!
        File::exist?('/tmp/test.reg').should be_true
        subject.registry_filename = prev
        subject.registry_filename.should eq "spec/config/services.registry"
      end

    end
    
    
    
    context "#close" do    
      context "Closing the Carioca registry" do
        it { should respond_to :close }
        it "should close" do
          subject.close.should eq true    
        end
        it "should log a registry closing notification if debug mode", :if => $debug do
          open('/tmp/log.file').grep(/DEBUG -- Carioca: closing Registry .../).size.should eq 1
        end
        it "should not log a registry closing notification if not debug mode", :unless => $debug do
          open('/tmp/log.file').grep(/DEBUG -- Carioca: closing Registry .../).size.should eq 0
        end
        it "should log a distributed service killing notification if debug mode", :if => $debug do
          open('/tmp/log.file').grep(/DEBUG -- Carioca: Killing distributed Service distdummy./).size.should >= 1
        end
        it "should not log a distributed service killing notification if not debug mode", :unless => $debug do
          open('/tmp/log.file').grep(/DEBUG -- Carioca: Killing distributed Service distdummy./).size.should eq 0
        end
        it "should log a stopping notification for each services if debug mode", :if => $debug do
          ['debug','uuid','dorsal','dummy','dummy_one','requireddummy','otherdummy'].each do |service|
            open('/tmp/log.file').grep(/DEBUG -- Carioca: Service #{service} stopped/).size.should >= 1
          end
        end
        it "should not log a stopping notification for each services if not debug mode", :unless => $debug do
          ['debug','uuid','dorsal','dummy','dummy_one','requireddummy','otherdummy'].each do |service|
            open('/tmp/log.file').grep(/DEBUG -- Carioca: Service #{service} stopped/).size.should eq 0
          end
        end
        it "should log a registry closing confirmation if debug mode", :if => $debug do
          open('/tmp/log.file').grep(/DEBUG -- Carioca: Registry services closed, logger will be closed asynchronously/).size.should eq 1
        end
        it "should not log a registry closing confirmation if not debug mode", :unless => $debug do
          open('/tmp/log.file').grep(/DEBUG -- Carioca: Registry services closed, logger will be closed asynchronously/).size.should eq 0
        end
        it "should loaded services empty" do
          subject.loaded_services.empty?.should eq true
        end  
        context "Distributed service" do
        end
      end
    end
  end
end







