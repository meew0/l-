require 'sinatra/base'
require 'json'

require 'rest/helpers'

require 'ws/ws_server'

require 'common/model'
require 'common/patches'
require 'common/util'


module Ldash
  class RestServer < Sinatra::Base
    set :port, 6601

    helpers RestHelpers

    post '/l-/session' do
      data = json!

      $session = Session.new
      $session.users = data['users'].map { |e| User.new(e) } if data['users']
      {}.to_json
    end

    post '/api/auth/login' do
      data = json!
      session = session!

      user = session.users.find_property :email, data['email']
      halt 400, '{"email": ["Email does not exist."]}' unless user
      halt 400, '{"password": ["Password does not match."]}' unless user.password == data['password']

      token = session.create_token(user)

      {
          token: token
      }.to_json
    end

    get '/api/gateway' do
      session!

      {
          url: 'ws://127.0.0.1:6601/'
      }.to_json
    end
  end
end

