module Ldash
  # Discord user
  class User
    attr_accessor :username, :id, :discriminator, :avatar

    # server ID => [role IDs]
    attr_accessor :roles

    attr_accessor :game, :status

    def initialize(username, id, discriminator, avatar)
      @username = username
      @id = id
      @discriminator = discriminator
      @avatar = avatar
    end

    def compact
      {
        username: @username,
        id: @id,
        discriminator: @discriminator,
        avatar: @avatar
      }
    end
  end
end