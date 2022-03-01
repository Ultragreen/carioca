# encoding: UTF-8
Dir[File.dirname(__FILE__) + '/*.rb'].sort.each {|file| require file  unless File.basename(file) == 'init.rb'}