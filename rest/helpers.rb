require 'json'

module Ldash
  module RestHelpers
    def fail_invalid(ldash_message, status = 400, discord_message = '')
      halt status, %Q({"message": "#{discord_message}", "l-": "#{ldash_message}"})
    end

    def json!
      request.body.rewind
      JSON.parse(request.body.read)
    rescue
      # Invalid JSON
      fail_invalid 'invalid JSON'
    end
  end
end