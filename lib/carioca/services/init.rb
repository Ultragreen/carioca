# frozen_string_literal: true

Dir["#{File.dirname(__FILE__)}/*.rb"].sort.each { |file| require file unless File.basename(file) == 'init.rb' }
