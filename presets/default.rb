# This file is the default session that l- loads if no other session preset is specified

bot = User.new(
  self,
  name: 'l- bot',
  email: 'abc@test.com',
  password: 'l- is awesome!',
  verified: true
)

server = Server.new(
  self,
  name: 'l- test server',
  owner_id: bot.id
)

bot_member = Member.new(
  self,
  user: bot,
  server: server
)

server.members << bot_member
@users << bot
@servers << server
