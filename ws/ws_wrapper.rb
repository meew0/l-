require 'json'

module Ldash
  # Class that wraps around Faye's ws object so we can send events more easily
  class WSWrapper
    def initialize(ws)
      @ws = ws
      @sequence = 0
    end

    def dummy?
      false
    end

    def ready!
      # ...
    end

    def packet(type, data)
      packet = {
          t: type,
          s: (@sequence += 1),
          op: 0,
          d: data
      }

      @ws.send(packet.to_json)
    end
  end
end