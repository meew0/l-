require 'sinatra/base'
require 'rest/helpers'

module Ldash
  class RestServer < Sinatra::Base
    set :port, 6601

    helpers RestHelpers

    post '/l-/session' do
      json!
    end
  end
end

