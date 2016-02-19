require 'eventmachine'
require 'faye/websocket'

Faye::WebSocket.load_adapter('thin')

module Ldash
  class WS
    def initialize(app)
      @app = app
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env)

        ws.on :open do |event|
          puts "Incoming WS connection - object ID: #{event.object_id}"
        end

        ws.on :message do |event|
          puts "Received message: #{event.data}"
        end

        ws.on :close do |event|
          puts "Closing WS connection from #{event.object_id} (code: #{event.code}, reason: '#{event.reason}')"
          ws = nil
        end

        # Return async Rack response
        ws.rack_response
      else
        @app.call(env)
      end
    end
  end
end