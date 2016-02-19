$LOAD_PATH.unshift File.dirname(__FILE__)
require 'eventmachine'
require 'rest/rest_server'
require 'ws/ws_server'

Ldash::RestServer.use Ldash::WS
Ldash::RestServer.run!

