module Ldash
  module WS
    module_function

    def onopen(ws)

    end

    def onmessage(ws, msg)
      puts "Received WebSocket message: #{msg}"
    end

    def onclose(ws, msg)

    end
  end
end