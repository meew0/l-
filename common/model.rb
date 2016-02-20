require 'base64'
require 'ws/dummy_ws'

module Ldash
  # Discord user
  class User
    attr_accessor :username, :id, :discriminator, :avatar

    # server ID => [role IDs]
    attr_accessor :roles

    attr_accessor :game, :status

    attr_accessor :email, :password

    attr_accessor :verified

    def initialize(data)
      @username = data['username'].to_s
      @id = data['id'].to_i

      # optional properties
      @discriminator = data['discriminator'].to_i if data['discriminator']
      @avatar = data['avatar'].to_s if data['avatar']
      @email = data['email'].to_s if data['email']
      @password = data['password'].to_s if data['password']

      @verified = data['verified'].nil? ? true : data['verified']
    end

    def compact
      {
          username: @username.to_s,
          id: @id.to_s,
          discriminator: @discriminator.to_s,
          avatar: @avatar.to_s
      }
    end

    # The email will only ever be defined on a possible bot user
    def bot_user?
      !@email.nil?
    end

    def bot_user
      compact.merge({
          verified: @verified,
          email: @email.to_s
                    })
    end
  end

  # The default user in case l- needs one but none exists
  DEFAULT_USER = User.new({
      id: 66237334693085184,
      username: 'meew0',
      avatar: 'd18a450706c3b6c379f7e2329f64c9e7',
      discriminator: 3569,
      email: 'meew0@example.com',
      password: 'hunter2',
      verified: true
                          })

  # L- session
  class Session
    attr_accessor :users, :channels, :servers, :messages, :roles, :tokens
    attr_accessor :ws
    attr_accessor :large_threshold

    attr_reader :id

    def initialize
      @users = []
      @channels = []
      @servers = []
      @messages = []
      @roles = []
      @tokens = []

      @token_num = 0

      @ws = DummyWS.new
      @id = self.object_id.to_s(16).rjust(32, '0')
    end

    def ws?
      !@ws.dummy?
    end

    def create_token(user)
      # The first part of a token is the bot user ID, base 64 encoded.
      first_part = Base64.encode64(user.id.to_s).strip

      # Then comes a string that's counted up globally.
      @token_num += 1
      second_part = Base64.encode64([@token_num].pack('Q>').sub(/^\x00+/, '')).strip

      # The third part is probably randomly generated
      third_part = Base64.encode64([*0..17].map { rand(0..255) }.pack('C*')).strip

      token = "#{first_part}.#{second_part}.#{third_part}"
      @tokens << token
      token
    end

    def token?(token)
      @tokens.include? token
    end

    def bot_user
      user = @users.find(&:bot_user)

      # If none exists, use the default user
      user || DEFAULT_USER
    end
  end
end