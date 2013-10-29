require 'rubygems'
require 'dorsal'

titi = Dorsal::Controller::new 
toto = titi.bind_to_ring
if toto.nil? then
  titi.start_ring_server
  toto = titi.bind_to_ring
end

p toto
  
