require 'eventmachine'
require 'faye/websocket'

require 'common/model'

require 'ws/ws_wrapper'
require 'ws/dummy_ws'

Faye::WebSocket.load_adapter('thin')

module Ldash
  class WS
    # WS protocol version
    VERSION = 3

    def initialize(app)
      @app = app
      $session = Session.new
      $session = nil
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

          packet = JSON.parse(event.data)
          d = packet['d']

          case packet['op']
          when 2  # WS initialization, reply with READY
            # Check whether we have the token
            unless $session.token? d['token']
              puts "Invalid token sent! #{d['token']}"
              ws.close 4004, 'authentication failed'  # reply as Discord would
              break
            end

            # Check the version
            unless d['version'] == VERSION
              puts "Invalid WS version! #{d['version']} != #{VERSION}"
              ws.close 4998, '[l-] discontinued version'  # we don't know how Discord would reply to this so make a custom one
              break
            end

            # Set the large_threshold, make it 250 at most (if none is specified Discord will assume 250)
            if d['large_threshold']
              $session.large_threshold = d['large_threshold'] > 250 ? 250 : d['large_threshold']
            else
              puts "No large_threshold specified, assuming 250 - it's recommended that you specify one!"
              $session.large_threshold = 250
            end

            # Throw an error if the user attempts to use compress
            if d['compress']
              ws.close 4999, "[l-] WS `compress` is not implemented yet - don't use it!"
              break
            end

            # Everything worked! Reply with READY
            $session.ws.ready!
          end
        end

        ws.on :close do |event|
          puts "Closing WS connection from #{event.object_id} (code: #{event.code}, reason: '#{event.reason}')"
          $session.ws = DummyWS.new
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