module Ldash
  # Class that wraps around Faye's ws object so we can send events more easily
  class WSWrapper
    def initialize(ws)
      @ws = ws
    end

    def send_ready(session)
      # ...
    end
  end
end