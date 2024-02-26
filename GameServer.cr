require "http/server"
require "http/request"
require "json"
require "./Game"

# Start two player game with one hero
game = Game.new(0, 2)

server = HTTP::Server.new do |context|
  # get the request.
  value = context.request.body.as(IO).gets_to_end.to_s
  # parse the request
  result = game.accept_command(value)
  context.response.print game.get_gamestate_json
end

address = server.bind_tcp 7775
puts "Listening on http://#{address}"
server.listen


# testy curl --header "Content-Type: application/json" --request POST --data '{"username":"xyz","password":"xyz"}' http://localhost:7775/