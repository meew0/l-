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
    attr_accessor :users, :channels, :servers, :messages, :roles

    def initialize
      @users = []
      @channels = []
      @servers = []
      @messages = []
      @roles = []
    end
  end
end