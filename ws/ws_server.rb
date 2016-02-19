require 'eventmachine'
require 'faye/websocket'

require 'ws/ws_wrapper'

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

          if defined? $session
            if $session.ws?
              puts "Already connected! Closing WS connection for #{event.object_id}"
              ws.close(4002, 'l-: Already connected')
            else
              $session.ws = WSWrapper.new(ws)
              puts "WS connection for #{event.object_id} succeeded"
            end
          else
            puts "No session! Closing WS connection for #{event.object_id}"
            ws.close(4001, 'l-: No session defined')
          end
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