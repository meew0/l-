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

    def initialize(data)
      @username = data['username'].to_s
      @id = data['id'].to_i

      # optional properties
      @discriminator = data['discriminator'].to_i if data['discriminator']
      @avatar = data['avatar'].to_s if data['avatar']
      @email = data['email'].to_s if data['email']
      @password = data['password'].to_s if data['password']
    end

    def compact
      {
        username: @username.to_s,
        id: @id.to_s,
        discriminator: @discriminator.to_s,
        avatar: @avatar.to_s
      }
    end
  end

  # L- session
  class Session
    attr_accessor :users, :channels, :servers, :messages, :roles, :tokens
    attr_accessor :ws

    def initialize
      @users = []
      @channels = []
      @servers = []
      @messages = []
      @roles = []
      @tokens = []

      @token_num = 0

      @ws = DummyWS.new
    end

    def ws?
      @ws.dummy?
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
  end
end