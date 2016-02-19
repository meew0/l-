module Ldash
  # Class that overwrites the send method so a null WS implementation can be provided (in case no WS is connected yet
  # and API requests are being done)
  class DummyWS
    def dummy?
      true
    end

    def send(*args)
      puts "send attempted on dummy WS with arguments #{args}"
    end
  end
end