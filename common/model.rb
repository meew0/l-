module Ldash
  # Discord user
  class User
    attr_accessor :username, :id, :discriminator, :avatar

    # server ID => [role IDs]
    attr_accessor :roles

    attr_accessor :game, :status

    def initialize(data)
      @username = data['username'].to_s
      @id = data['id'].to_i
      @discriminator = data['discriminator'].to_i
      @avatar = data['avatar'].to_s
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
end