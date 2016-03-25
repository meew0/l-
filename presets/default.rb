# This file is the default session that l- loads if no other session preset is specified

bot = Ldash::User.new(
  $session,
  name: 'l- bot',
  email: 'abc@test.com',
  password: 'l- is awesome!',
  verified: true
)

server = Ldash::Server.new(
  $session,
  name: 'l- test server',
  owner_id: bot.id
)

bot_member = Ldash::Member.new(
  $session,
  user: bot,
  server: server
)

server.members << bot_member
