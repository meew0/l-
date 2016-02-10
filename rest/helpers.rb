require 'json'

module Ldash
  module RestHelpers
    def json!
      request.body.rewind
      JSON.parse(request.body.read)
    rescue
      # Invalid JSON
      halt 400, '{"message": ""}'
    end
  end
end