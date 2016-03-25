require 'base64'
require 'ws/dummy_ws'
require 'time'

module Ldash
  # The unix timestamp Discord IDs are based on
  DISCORD_EPOCH = 1_420_070_400_000

  # Format time to Discord's format
  def self.format_time(time)
    time.iso8601
  end

  # Generic data base class, so I don't have to write the same kind of initializer over and over again
  class DataObject
    def self.data_attribute(name, &proc)
      @data_attributes ||= []
      @data_attributes << { name: name, proc: proc }

      attr_accessor(name)
    end

    def initialize(data = {})
      @session = $session
      attrs = self.class.instance_variable_get('@data_attributes')
      attrs.each do |attr|
        val = data[attr[:name]]
        val = attr[:proc].call($session) if !val && attr[:proc]

        instance_variable_set("@#{attr[:name]}", val)
      end
    end
  end

  # Discord user
  class User < DataObject
    data_attribute :username
    data_attribute :id, &:generate_id
    data_attribute(:discriminator) { |s| s.generate_discrim(@username) }
    data_attribute :avatar

    data_attribute :email
    data_attribute :password

    data_attribute :verified
    data_attribute :bot

    def id_format
      {
        id: @id.to_s
      }
    end

    def compact
      result = {
        username: @username.to_s,
        id: @id.to_s,
        discriminator: @discriminator.to_s,
        avatar: @avatar.to_s
      }

      # Only add the bot tag if it's actually true
      result[:bot] = true if @bot

      result
    end

    # The email will only ever be defined on a possible bot user
    def bot_user?
      !@email.nil?
    end

    def bot_user_format
      compact.merge(verified: @verified, email: @email.to_s)
    end
  end

  # Users on servers
  class Member < DataObject
    data_attribute :user
    data_attribute :server

    # Server wide voice status
    data_attribute(:mute) { false }
    data_attribute(:deaf) { false }
    data_attribute :voice_channel

    data_attribute(:joined_at) { Time.now }

    data_attribute(:roles) { [] }

    data_attribute(:game) { nil }
    data_attribute(:status) { 'online' }

    def in_voice_channel?
      !@voice_channel.nil?
    end

    # Format used in the READY and GUILD_CREATE members list
    def guild_member_format
      {
        mute: @mute,
        deaf: @deaf,
        joined_at: Ldash.format_time(@joined_at),
        user: @user.compact,
        roles: @roles.map(&:id).map(&:to_s)
      }
    end

    # Format used in the READY and GUILD_CREATE presences list
    def presence_format
      {
        user: @user.id_format,
        status: @status,
        game: game_object
      }
    end

    # Format used in the READY and GUILD_CREATE voice state list
    def voice_state_format
      {
        user_id: @user.id.to_s,
        suppress: false, # TODO: voice states
        self_mute: false, # TODO: voice states
        self_deaf: false, # TODO: voice states
        mute: @mute,
        deaf: @deaf,
        session_id: @session.id,
        channel_id: @voice_channel ? @voice_channel.id : nil
      }
    end

    private

    def game_object
      return nil unless @game

      {
        name: @game
      }
    end
  end

  # Class for user avatars and server icons
  class Avatar < DataObject
    data_attribute :hash
    data_attribute :image_data

    # to_s should just be the hash
    alias_method :to_s, :hash
  end

  # Channels
  class Channel < DataObject
    data_attribute :id, &:generate_id

    data_attribute :name
    data_attribute :topic
    data_attribute :position
    data_attribute :permission_overwrites

    data_attribute :server
    data_attribute :type

    data_attribute :bitrate

    data_attribute :recipient

    def private?
      !@server.nil?
    end

    # Format used in READY and GUILD_CREATE
    def guild_channel_format
      {
        type: @type,
        topic: @topic,
        id: @id.to_s,
        name: @name,
        position: @position,
        permission_overwrites: permission_overwrites_format,
        bitrate: @bitrate
      }
    end

    # Format used in CHANNEL_CREATE (private or public), CHANNEL_DELETE (private or public) and CHANNEL_UPDATE
    def channel_create_format
      if private?
        {
          id: @id.to_s,
          is_private: true,
          recipient: @recipient.compact
        }
      else
        {
          guild_id: @server.id.to_s,
          id: @id.to_s,
          is_private: false,
          name: @name,
          permission_overwrites: permission_overwrites_format,
          position: @position,
          topic: @topic,
          type: @type,
          bitrate: @bitrate
        }
      end
    end

    # Format used in the READY private_channels array
    def private_channels_format
      {
        recipient: @recipient.compact,
        is_private: true,
        id: @id.to_s
      }
    end

    private

    def permission_overwrites_format
      [
        { # TODO: change this default overwrite format into actual data
          type: role,
          id: @server.id.to_s,
          deny: 0,
          allow: 0
        }
      ]
    end
  end

  # Roles
  class Role < DataObject
    data_attribute :id, &:generate_id

    DEFAULT_PERMISSIONS = 36_953_089
    data_attribute(:permissions) { DEFAULT_PERMISSIONS }
    data_attribute :server

    data_attribute :position
    data_attribute :name
    data_attribute :hoist
    data_attribute :colour

    # Format used if this role is embedded into guild data (e.g. in READY or GUILD_CREATE)
    def guild_role_format
      {
        position: @position,
        permissions: @permissions,
        managed: false, # TODO: investigate what this is (probably integration stuff)
        id: @id.to_s,
        name: @name,
        hoist: @hoist,
        color: @colour # damn American spelling
      }
    end
  end

  # Discord servers
  class Server < DataObject
    data_attribute :id, &:generate_id
    data_attribute :name

    data_attribute :icon
    data_attribute :owner_id

    data_attribute(:afk_timeout) { 300 }
    data_attribute :afk_channel

    data_attribute(:bot_joined_at) { Time.now }

    data_attribute :roles do |s|
      # @everyone role
      Role.new(s,
               id: @id, # role ID = server ID
               name: '@everyone',
               server: self,
               position: -1,
               hoist: false,
               colour: 0)
    end

    data_attribute :channels do |s|
      [
        # #general text channel
        Channel.new(s,
                    id: @id,
                    name: 'general',
                    server: self,
                    type: 'text',
                    position: 0),

        # General voice channel
        Channel.new(s,
                    id: @id + 1,
                    name: 'General',
                    server: self,
                    type: 'voice',
                    bitrate: 64_000)
      ]
    end

    data_attribute :members do |s|
      []
    end

    data_attribute(:region) { 'london' }

    def large?
      @session.large?(@members.length)
    end

    def member_count
      @members.length
    end

    # Format used in READY and GUILD_CREATE
    def guild_format
      channels = @channels.map(&:guild_channel_format)
      roles = @roles.map(&:guild_role_format)
      members = tiny_members.map(&:guild_member_format)
      presences = tiny_members.map(&:presence_format)
      voice_states = tiny_members.select(&:in_voice_channel?).map(&:voice_state_format)

      {
        afk_timeout: @afk_timeout,
        joined_at: Ldash.format_time(@bot_joined_at),
        afk_channel_id: @afk_channel.id,
        id: @id.to_s,
        icon: @icon,
        name: @name,
        large: large?,
        owner_id: @owner_id.to_s,
        region: @region,
        member_count: member_count,

        channels: channels,
        roles: roles,
        members: members,
        presences: presences,
        voice_states: voice_states
      }
    end

    # Format used when a guild is unavailable due to an outage
    def unavailable_format
      {
        id: @id.to_s,
        unavailable: true
      }
    end

    private

    # Get a list of members according to large_threshold
    def tiny_members
      return @members unless large?

      @members.select { |e| e.status != :offline }
    end
  end

  # The default user in case l- needs one but none exists
  DEFAULT_USER = User.new(id: 66237334693085184,
                          username: 'meew0',
                          avatar: 'd18a450706c3b6c379f7e2329f64c9e7',
                          discriminator: 3569,
                          email: 'meew0@example.com',
                          password: 'hunter2',
                          verified: true)

  # Mixin to generate discrims
  module DiscrimGenerator
    def generate_discrim(username)
      discrims = discrims_for_username(username)
      raise "Can't find a new discrim for username #{username} - too many users with the same username! Calm down with your presets" if discrims.length == 9999

      generated = nil
      loop do
        generated = rand(1..9999)
        break unless discrims.include? generated
      end

      generated
    end

    private

    def discrims_for_username(username)
      @users.select { |e| e.username == username }.map(&:discriminator)
    end
  end

  # L- session
  class Session
    attr_accessor :users, :private_channels, :servers, :messages, :tokens
    attr_accessor :ws
    attr_accessor :large_threshold, :heartbeat_interval

    attr_reader :id

    def initialize
      @users = []
      @private_channels = []
      @servers = []
      @messages = []
      @tokens = []

      @token_num = 0
      @large_threshold = 100 # TODO
      @heartbeat_interval = 41_250 # Discord doesn't always use this exact interval but it seems common enough to use it as the default

      @ws = DummyWS.new
      @id = object_id.to_s(16).rjust(32, '0')
    end

    def ws?
      !@ws.dummy?
    end

    def create_token(user)
      # The first part of a token is the bot user ID, base 64 encoded.
      first_part = Base64.encode64(user.id.to_s).strip

      # The second part is seconds since Jan 1 2011, base 64 encoded.
      second_part = Base64.encode64([@token_num].pack('Q>').sub(/^\x00+/, '')).strip

      # The third part is apparently a HMAC - we don't care about that so just generate a random string
      # WTF kind of library would rely on this anyway
      third_part = Base64.encode64([*0..17].map { rand(0..255) }.pack('C*')).strip

      token = "#{first_part}.#{second_part}.#{third_part}"
      @tokens << token
      token
    end

    # Generates an ID according to Discord's snowflake system
    def generate_id
      accurate_timestamp = (Time.now.to_f * 1000).round
      time_part = (accurate_timestamp - DISCORD_EPOCH) << 22
      random_part = rand(0...2**22)

      time_part & random_part
    end

    def large?(member_count)
      member_count >= @large_threshold
    end

    include DiscrimGenerator

    def token?(token)
      @tokens.include? token
    end

    def bot_user
      user = @users.find(&:bot_user_format)

      # If none exists, use the default user
      user || DEFAULT_USER
    end
  end
end
