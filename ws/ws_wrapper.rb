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
      data = {
        v: Ldash::WS::VERSION,
        # Libraries shouldn't care about settings so don't send them
        user: $session.bot_user.bot_user_format,
        session_id: $session.id,
        read_state: [], # send an empty read_state because libraries shouldn't care about it
        relationships: [], # same for relationships
        presences: [], # same for presences (these are unrelated to guilds - friends list stuff)
        private_channels: $session.channels.select(&:private?).map(&:private_channels_format),
        heartbeat_interval: $session.heartbeat_interval,
        guilds: $session.servers.map(&:guild_format)
      }

      packet(:READY, data)
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
