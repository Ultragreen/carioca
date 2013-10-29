
#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#---
# Author : Romain GEORGES
# type : gem component library
# obj : Carioca Module
#---

require 'yaml'
require 'rubygems'
require 'methodic'
require 'carioca/services'
require 'carioca/private'



# module Carioca
# @author Romain GEORGES <romain@ultragreen.net>
# @see http://www.ultragreen.net/projects/carioca
# @version 1.0
# @note this module is a namespace Carioca
module Carioca


  
  # module Services
  # @note this module is a namespace Carioca::Services 
  module Services
    
    
    # class Registry
    #  This class provide the Registry manager for Carioca
    # @note this class is a Singleton Class to instanciate do not use new (initializer), but :
    #    Carioca::Services::Registry.init options 
    # @example Complete usage 
    #    require 'rubygems'
    #    require 'carioca'  
    #    registry = Carioca::Services::Registry.init 
    #    registry = Carioca::Services::Registry.init :file => 'myservices.registry'
    #    registry = Carioca::Services::Registry.init :file => 'myservices.registry', :debug => true
    class Registry

      include PrivateMethodsCariocaServicesRegistry
      
      # for singleton 
      private_class_method :new
      private :verify_requires_dependancies
      private :require_service
      private :instanciate_service
      private :kill_service
      private :scan_instance_suffix
      private :kill_distributed_service
      private :shutdown_ring_if_empty
      
      
      @@inst = nil
      
      # Singleton constructor for Registry
      # @param [Hash] _options the options, keys are symbols
      # @option _options [String] :file The path of your registry YAML definition (see YAML registry format)
      # @option _options [TrueClass,FalseClass] :debug Boolean activation/deactiviation of the carioca debug mode (log traces) 
      # @return [Carioca::Services::Registry] Singleton class instance of Registry
      # @example usage
      #    registry = Carioca::Services::Registry.init # or  
      #    registry = Carioca::Services::Registry.init :file => 'myservices.registry' # or
      #    registry = Carioca::Services::Registry.init :file => 'myservices.registry', :debug => true
      def Registry.init(_options = {})
        options = Methodic::get_options(_options)
        options.specify_defaults_values :file => './services.registry', :debug => false, :name => 'Carioca'
        options.merge
        @@inst = new(options) if @@inst.nil?
        return @@inst
      end
      
      # @example read
      #   registry = Carioca::Services::Registry.init
      #   p registry.registry_filename
      # @example write
      #   registry = Carioca::Services::Registry.init
      #   p registry.registry_filename = '/tmp/test.file'
      # @attr_reader [Hash] list a hash table of all structured registred services definition 
      # (come from file and explicitly registered services)
      attr_accessor :registry_filename
      
      # @example 
      #   registry = Carioca::Services::Registry.init
      #   p registry.list
      # @attr_reader [Hash] list a hash table of all structured registred services definition 
      # (come from file and explicitly registered services)
      attr_reader :list

      # @example 
      #   registry = Carioca::Services::Registry.init
      #   p registry.loaded_services # you should see the logger service Hash definition
      # @attr_reader [Hash] loaded_services a hash table of all structured loaded services 
      attr_reader :loaded_services

      # @example 
      #   registry = Carioca::Services::Registry.init
      #   p registry.debug
      # @attr_reader [TrueClass,FalseClass] debug a boolean of the current debug status
      attr_reader :debug

      # @example 
      #   registry = Carioca::Services::Registry.init
      #   p registry.name
      #   registry.name = 'Agent'
      # @attr_reader [String] the name of the Registry, used for distributed services
      # @note default value is 'Carioca'
      attr_accessor :name
      
      # writer accessor for debug (interaction with log service)
      # @example 
      #   registry = Carioca::Services::Registry.init
      #   p registry.debug = true
      # @param [TrueClass,FalseClass] _value true or false to activate/deactivate debug mode 
      # @note interaction with preloaded service logger
      def debug=(_value)
        @log.level =(_value)? Logger::DEBUG : Logger::INFO     
      end


      # stop a service, if loaded and different to logger
      # @param [Hash] _options the options, keys are symbols
      # @option _options [String] :name The name of the service to stop
      # @return [TruaClass,FalseClass] true if service effectivly stopped, false if not, or :name == 'logger'
      # @example usage
      #    registry = Carioca::Services::Registry.init 
      #    registry.start_service :name => 'configuration'
      #    registry.stop_service :name => 'configuration'
      #    #=> return true
      #    registry.stop_service :name => 'configuration'
      #    #=> return false
      #    registry.stop_service :name => 'logger'
      #    #=> return false
      # @note log if debug mode
      def stop_service(_options)
        options = Methodic.get_options(_options)
        options.specify_class_of :name => String
        options.specify_presence_of([:name])
        options.validate!
        @log.debug('Carioca') { "Service logger can't be unloaded" } if @log and options[:name] == 'logger'
        return false if options[:name] == 'logger'
        if @loaded_services.include?(options[:name]) then        
          options = scan_instance_suffix(options)
          return kill_distributed_service options if @list[options[:shortname]][:distributed]
          return kill_service options
        else
          @log.debug('Carioca') { "Service #{options[:name]} not loaded" } if @log
          return false          
        end
      end
      

      # register a new service in registry added to @list
      # @param [Hash] _options the options hash, key are :symbols
      # @option _options [String] :name the name of the service (required)
      # @option _options [String] :resource the resource, must be a gem name, a fullpath filename, a builtin service (required)
      # @option _options [Symbol] :type the resource type of the service, must be :gem, :builtin or :file (required)
      # @option _options [String] :service the realname of the service class with namespace (eg. ExternalServices::Dummy ) 
      # @option _options [String] :description the description of the service (required)
      # @option _options [Hash] :init_options the params of the service, keys are symbols
      # @option _options [Array] :requires the list of [String] services name required to load this service
      # @option _options [TruClass|FalseClass] :distributed if service must be load as a distributed service
      # @return [TrueClass,FalseClass] true if service is added
      # @raise ArgumentError when :type is not in [:gem,:file,:builtin]
      def register_service(_options)
        options = Methodic.get_options(_options)
        options.specify_classes_of({:name => String, :resource => String, :description => String, :type => Symbol, :service => String }) 
        options.specify_presences_of([:name,:type,:resource,:service])
        cond = Proc::new{|option| if [:gem,:gem_file,:file,:builtin].include? option then true else false end }
        options.specify_condition_for :type => cond
        options.validate!
        _name = _options.delete(:name)
        @list[_name] = _options
        return true
      end

      # unregister a service in registry removed from @list
      # @param [Hash] _options the options hash, key are :symbols
      # @option _options [String] :name the name of the service (required)
      # @raise [RegistryError] if try to unregister logger
      # @raise [registryerror] if try to unregister a loaded service
      # @return [TrueClass,FalseClass]
      def unregister_service(_options = {})
        options = Methodic.get_options(_options)
        options.specify_class_of :name => String
        options.specify_presence_of :name
        options.validate!
        raise RegistryError::new("FONDATION : Can't unregistered the logger service" ) if options[:name] == 'logger'
        raise RegistryError::new("Can't unregistered a loaded service" ) if @loaded_services.include?(options[:name])
        @list.delete(options[:name])
        return true
      end
      
      # overload @list (self.list) by adding/reloading the builtins services definition scanned from Carioca gem
      #  alterate @list
      # @example usage
      #    registry = Carioca::Services::Registry.init :name => '/tmp/empty.file'
      #    registry.discover_builtins
      #    registry.save!
      def discover_builtins
        @list.merge! Carioca::Services::discover_builtins
      end
      
      # save the registry file in self.registry_filename
      # @return [TruaClass,FalseClass] true if the file is saved
      # @example usage
      #    registry = Carioca::Services::Registry.init :file => './empty.file' 
      #    registry.discover_builtins
      #    registry.unregister_service :name => 'configuration'
      #    registry.save!
      def save!
        res = false
        File.open(@registry_filename, "w") do |f|
          res = true if f.write(@list.to_yaml)
        end
        return res
      end
      
      # start or get e previously started service in @list
      # @return [Object] the loaded service class instance
      # @param [Hash] _options the params, key are symbols
      # @option _options [String] :name the name of the service
      # @option _options [Hash] :params the params of the service
      # @raise [RegistryError] Config Failed, for unconsistant service definition in @list
      # @example usage 
      #    registry = Carioca::Services::Registry.init 
      #    config = registry.start_service :name => 'configuration'
      #    proxy = subject.start_service :name => 'debug' , :params => {:service => 'configuration'}
      def start_service(_options)
        options = Methodic.get_options(_options)
        options.specify_classes_of :name => String
        options.specify_presences_of([:name])
        options.validate!
        @log.debug('Carioca') { "getting service #{options[:name]}"} if @log
        self.restart_service(options) unless @loaded_services.include? options[:name] 
        return @loaded_services[options[:name]]
      end
      alias :get_service :start_service

      # start or restart (stop=>start) previously started service in @list
      # @return [Object] the loaded service class instance
      # @param [Hash] _options the params, key are symbols
      # @option _options [String] :name the name of the service
      # @option _options [Hash] :params the params of the service
      # @raise [RegistryError] Config Failed, for unconsistant service definition in @list
      # @example usage 
      #    registry = Carioca::Services::Registry.init 
      #    config = registry.restart_service :name => 'configuration'
      #    config = registry.restart_service :name => 'configuration' # stop and restart the previous services
      #    proxy = subject.restart_service :name => 'debug' , :params => {:service => 'configuration'}
      # @note Registry and services are Singleton
      def restart_service(_options)
        options = Methodic.get_options(_options)
        options.specify_classes_of :name => String
        options.specify_presences_of [:name]
        options.validate!
        options = scan_instance_suffix(options)
        dist = (@list[options[:shortname]][:distributed].nil?)? false : @list[options[:shortname]][:distributed]
        if dist and @loaded_services.include? options[:name] then
          @log.debug('Carioca') { "Restarting distributed service #{options[:name]}"} if @log
          kill_distributed_service options
        elsif @loaded_services.include? options[:name] then
          @log.debug('Carioca') { "Restarting service #{options[:name]}"} if @log
          kill_service options     
        end    
        verify_requires_dependancies(options)
        require_service(options)
        return instanciate_service(options)
      end
      
      # close the registry (finalizer)
      #  * stop all the services 
      #  * kill logger
      #  * call private kill_service for each 
      # @note the garbage method hook is call if defined, for each service
      # @return [TrueClass,FalseClass] true if registry closed successfully
      def close
        @log.debug('Carioca') { "closing Registry ..." }
        options = Hash::new
        @loaded_services.keys.each do |service|
          options[:name] = service
          options = scan_instance_suffix(options)
          next if options[:name] == 'logger' 
          kill_distributed_service :name => options[:name], :preserve => true if @list[options[:shortname]][:distributed]
          kill_service options unless @list[options[:shortname]][:distributed]
        end
        @log.debug('Carioca') { "Registry services closed, logger will be closed asynchronously" }
        kill_service :name => 'logger'
        return true
      end

      # load the registry file from self.registry_filename
      # @return [Hash] @list the list Structure of the loaded registry 
      # @example usage
      #    registry = Carioca::Services::Registry.init
      #    registry.registry_filename = "./an_other.file"
      #    registry.load #or
      #    registry.reload
      def load
        @list = YAML.load_file(@registry_filename)
      end
      alias :reload :load
      
    end # end of Carioca::Services::Registry
  end # end of Carioca:Services
end # end of Carioca

# Exception overload class for Carioca 
class RegistryError < Exception; end


Module.class_eval do
def init_registry _options={}
    options = Methodic.get_options(_options)
    options.specify_classes_of :with_file => String
    options.specify_default_value_of :with_file => './services.registry'
    options.merge
    options.validate!
    Carioca::Services::Registry.init options[:with_file]
  end
end
