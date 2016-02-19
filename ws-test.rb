require 'faye/websocket'
require 'eventmachine'

EM.run do
  ws = Faye::WebSocket::Client.new('ws://127.0.0.1:6601/')

  ws.on :open do |_|
    p [:open]
    Thread.new do
      loop { ws.send(gets.chomp) }
    end
  end

  ws.on :message do |event|
    p [:message, event.data]
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
end