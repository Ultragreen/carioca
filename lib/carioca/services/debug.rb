# coding: utf-8
# $BUILTIN
# $NAME debug
# $SERVICE Carioca::Services::ProxyDebug
# $RESOURCE debug
# $DESCRIPTION Proxy class debugger Service for Carioca
# Copyright Ultragreen (c) 2012
#---
# Author : Romain GEORGES
# type : class definition Ruby
# obj : Generic Debugs tools library
#---


require 'rubygems'
require 'methodic'


module Carioca
  module Services


    # Service Debug of Carioca
    # Proxy Class Debug for devs
    class ProxyDebug

      # ProxyDebug service constructor (has a class proxy => so a service proxy)
      # @param [Hash] _options the params
      # @option _options [String] :service the name of the service you want to proxyfying
      # @option _options [Hash] :params the params of the proxyfied service
      def initialize(_options)
        options = Methodic.get_options(_options)
        options.specify_classes_of :service => String
        options.specify_presence_of([:service])
        options.validate!
        if options[:params] then
          @obj = Registry.init.start_service :name  => options[:service], :params => options[:params]
        else
          @obj = Registry.init.start_service :name  => options[:service]
        end
        @log  = Registry.init.get_service :name => 'logger'
        @mapped_service = options[:service]
      end

      # method_missing overload to make the class proxy efficient
      def method_missing(methodname, *args,&block)
        @log.debug("ProxyDebug") { "BEGIN CALL for mapped service #{@mapped_service} "}
        @log.debug("ProxyDebug") { "called: #{methodname} " }
        @log.debug("ProxyDebug") { "args : #{args.join " "}" }
        if block_given? then
          @log.debug("ProxyDebug") { "block given" }
          a = @obj.send(methodname, *args,&block)
        else
          a = @obj.send(methodname, *args)
        end
        @log.debug("ProxyDebug") { "=> returned: #{a} " }
        @log.debug("ProxyDebug") { 'END CALL' }
        return a
      end


    end
  end
end

# protection for loading libs
if $0 == __FILE__ then
  puts "#{File::basename(__FILE__)}:"
  puts 'this is a RUBY library file'
  puts "Copyright (c) Ultragreen"
end
