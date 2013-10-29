#!/usr/bin/env ruby
# $BUILTIN
# $NAME logger
# $SERVICE Carioca::Services::InternalLogger
# $RESOURCE logger
# $DESCRIPTION The standard ruby Logger internal wrapper Service for Carioca
# $INIT_OPTIONS target => /tmp/log.file
# Copyright Ultragreen (c) 2005
#---
# Author : Romain GEORGES 
# type : class definition Ruby
# obj : Generic config library
#---
# $Id$

require 'rubygems'
require 'logger'
require 'methodic'

module Carioca
  module Services 

    # Service Logger (InternalLogger) of Carioca,
    # @note integrally based on Logger from logger Gem
    class InternalLogger < Logger
      
      private
      
      # logger service constructor (open log)
      # @param [Hash] _options the params 
      # @option _options [String] :target the filename where to log
      def initialize(_options = {})
        options = Methodic.get_options(_options)
        options.specify_default_value :target => STDOUT
        options.merge
        super(options[:target])
      end
      
      # garbage service hook
      # @note close the logger 
      def garbage
        self.close
      end
      
    end
  end
  
  
  
end


# interactive hacks 
if $0 == __FILE__ then
  puts "#{File::basename(__FILE__)}:"
  puts 'this is a RUBY library file'
  puts "Copyright (c) Ultragreen"
end
