# This file is the default session that l- loads if no other session preset is specified

# Create the bot user with the specified arguments.
bot = Ldash::User.new(
  name: 'l- bot',
  email: 'abc@test.com',
  password: 'l- is awesome!',
  verified: true
)

# Here, we make sure the join time on the Member and on the Server is
# equal. It's not really necessary but it shows off what you can do
bot_join_time = Time.now

# Create the server
server = Ldash::Server.new(
  name: 'l- test server',
  owner_id: bot.id,
  bot_joined_at: bot_join_time
)

# Create the member (user on a server)
bot_member = Ldash::Member.new(
  user: bot,
  server: server,
  joined_at: bot_join_time
)

# Add the member we just created to the server's members list, and the
# user and server we created to the global user and server list
server.members << bot_member
@users << bot
@servers << server
