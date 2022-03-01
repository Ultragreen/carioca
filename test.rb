require 'rubygems'
require 'carioca'

registry =  Carioca::Registry.init  filename: '/tmp/carioca.registry'



registry.get_service name: :configuration, options: {test: 'titi'}

uuid = registry.get_service name: :uuid

pp uuid.generate

pp registry.active_services.keys
pp registry.services.keys

5.times do p registry.get_service(name: :configuration).inspect end

registry.get_service(name: :test)