#!/usr/bin/env ruby
# $BUILTIN
# $NAME configuration
# $SERVICE Carioca::Services::Configuration 
# $RESOURCE configuration
# $DESCRIPTION The Carioca Configuration Service
# $INIT_OPTIONS config_file => ./.config

# Copyright Ultragreen (c) 2005
#---
# Author : Romain GEORGES 
# type : class definition Ruby
# obj : Generic config library
#---
# $Id$


require 'rubygems'
require 'methodic'
require_relative '../services'
require 'yaml'
require 'drb/drb'
require 'xmlsimple'
require 'active_support/all'

# overwriting Hash class 
# @private
class Hash

  # recursively transform Hash keys form String to Symbols 
  # come from Rails code
  # exist in Ruby 2.0
  def deep_symbolize
    target = dup
    target.inject({}) do |memo, (key, value)|
      value = value.deep_symbolize if value.is_a?(Hash)
      memo[key.to_sym] = value
      memo
    end
  end

  # pretty accessor for hash record
  # like ahash[:key] => ahash.key
  # r/w accessor 
  def method_missing(name, *args, &block)
    if name.to_s =~ /(.+)=$/
      self[$1.to_sym] = args.first
    else
      self[name.to_sym]
    end
  end
end
    




module Carioca

  module Services 

    # settings Hash record utilities class
    # @note please do not use Standalone ( dependancy of Configuration class )
    # @private
    class Settings < Hash


      # the name of the config file in YAML format
      attr_accessor :config_file
      
      # constructor  (pre-open the config file in default:YAML)
      # @param [Hash] options the options records
      # @option options [String] :config_file (REQUIRED) the name of the config file
      # @option options [String] :context a context (root) name to bind in YAML Structure
      # @option options [String] :content a string (xml or yaml) content for configuration
      # @option options [String] :xml_input a boolean if you want load and save in XML
      def initialize(options = {})
        @config_file = options[:config_file]
        @xml_input = options[:xml_input]
        @content  = options[:content]
        @force_array =  options[:force_array]
        newsets = {}
        if @config_file then
          @content = File::readlines(@config_file).join if File::exist?(@config_file)
        end
        if options[:xml_input] then
          newsets = XmlSimple.xml_in( @content, {
                                        'ForceArray' => @force_array,
                                        'KeepRoot' => true,
                                      }).deep_symbolize_keys
        else
          newsets = YAML::load(@content).deep_symbolize_keys
        end
        newsets = newsets[options[:context].to_sym] if options[:context] && newsets[options[:context].to_sym]
        deep_merge!(self, newsets)
      end
      
      # save the Hash(self) in the file named by @config_file
      # @return [TrueClass,FalseClass] true if save! successfull
      # @note TODO save in XML format
      def save!
        res = false
        File.open(@config_file, "w") do |f|
          res = true if f.write(self.to_yaml)
        end
        return res
      end


      private
      # full recursive merger for hash 
      def deep_merge!(target, data)
        merger = proc{|key, v1, v2|
          Settings === v1 && Settings === v2 ? v1.merge(v2, &merger) : v2 }
        target.merge! data, &merger
      end


    end

    
    
    
    # Service Configuration of Carioca
    class Configuration 
      
      include DRb::DRbUndumped
      
      # @example 
      #   config = Carioca::Services::Configuration::new :config_file => 'afilename', :context => 'production'
      #   p config.config_file
      #   config_file = 'newfilename'
      # @attr_reader [String] the filename of the YAML struct
      attr_accessor :settings

      
      # Configuration service constructor (open config)
      # @param [Hash] _options the params
      # @option _options [String] :config_file the filename of the config
      def initialize(_opts = {})


        options = Methodic.get_options(_opts)
        options.specify_default_value :config_file => "./.config"
        options.merge
        @settings = Carioca::Services::Settings.new(options)
      end
      
      # Proxy to @settings.save! 
      #  save the Hash(self) in the file named by @config_file
      # @return [TrueClass,FalseClass] true if save! successfull
      # @example usage
      #   config = Carioca::Services::Configuration::new :config_file => 'afilename', :context => 'production'
      #   config.config_file = 'newfile'   
      #   config.save!
      def save!
        @settings.save!
      end

      
      # reading wrapper to @settings.config_file accessor
      # @return [String] @config_file the file name  
      # @example usage
      #   config = Carioca::Services::Configuration::new :config_file => 'afilename', :context => 'production'
      #   p config.config_file 
      def config_file
        @settings.config_file
      end
      
      # writting wrapper to @settings.config_file accessor
      # @param [String] name the file name
      # @example usage
      #   config = Carioca::Services::Configuration::new :config_file => 'afilename', :context => 'production'
      #   config.config_file = 'newfile'
      def config_file=(name)
        @settings.config_file = name
      end


      # garbage service hook
      # @note close the logger
      # @note call by Carioca::Services::Registry#close
      def garbage
        @settings = nil
        return true
      end
      
    end
  end
end





# interactive hacks 
if $0 == __FILE__ then
  conf =Carioca::Services::Configuration::new :config_file => 'spec/config/.config'
  p conf
  puts "#{File::basename(__FILE__)}:"
  puts 'this is a RUBY library file'
  puts "Copyright (c) Ultragreen"
end
