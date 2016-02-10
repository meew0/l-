$LOAD_PATH.unshift File.dirname(__FILE__)
require 'rest/rest_server'
require 'ws/ws_server'

Ldash::RestServer.run!
