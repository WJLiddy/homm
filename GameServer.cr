require "http/server"
require "http/request"
require "json"
require "./Game"

# Start two player game with one hero
game = Game.new(0, 2)

server = HTTP::Server.new do |context|
  # get the request.
  rawvalues = context.request.body.as(IO).gets_to_end

  # nasty fix, but user just wanted update
  if(rawvalues == "")
    context.response.print game.get_gamestate_json
    next
  end
  # parse the request
  values = JSON.parse(rawvalues).as_a
  # return CommandErrors::InvalidJSON
  
  # run commands unless an error happens, then stop
  values.each do |v|
    result = game.accept_command(v)
    if !(result.is_a? Game::CommandErrors::NoError)
      # error happened
      print "Error: #{result}"
      break
    end
  end

  context.response.print game.get_gamestate_json
end

address = server.bind_tcp 7775
puts "Listening on http://#{address}"
server.listen


# testy curl --header "Content-Type: application/json" --request POST --data '{"username":"xyz","password":"xyz"}' http://localhost:7775/