# frozen_string_literal: true

Dir["#{File.dirname(__FILE__)}/*.rb"].each { |file| require file unless File.basename(file) == 'init.rb' }
