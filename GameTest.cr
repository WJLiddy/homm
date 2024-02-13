require "./Game"
require "colorize"

def colorize_team(string : String, playerID : Int32 | Nil)
  if(playerID == nil)
    return string.colorize(:white)
  end
  colors = [:blue, :red, :green, :yellow, :magenta, :cyan]
  return string.colorize(colors[playerID.as(Int32)])
end

def print_world_map(game : Game)
  game.map.size.times do |y|
    game.map.size.times do |x|

      # Heroes
      h = game.get_hero_at(Vector2.new(x, y))
      if(h != nil)
        print colorize_team("h", game.players.index((h.as(Hero)).player))
        next
      end

      # Cities
      if (game.map.cities.has_key?(Vector2.new(x, y)))
        c = game.map.cities[Vector2.new(x, y)]
        print colorize_team("X", game.players.index((c.as(City)).owner))
        next
      end

      # Farms
      if (game.map.farms.has_key?(Vector2.new(x, y)))
        team = game.players.index(game.map.farms[Vector2.new(x, y)][1])
        if (game.map.farms[Vector2.new(x, y)][0] == Game::Resource::Bitcoin)
          print colorize_team("B", team)
        elsif (game.map.farms[Vector2.new(x, y)][0] == Game::Resource::Pot)
          print colorize_team("P", team)
        elsif (game.map.farms[Vector2.new(x, y)][0] == Game::Resource::Cereal)
          print colorize_team("C", team)
        end
        next
      end
      # Ground
      if (game.map.groundresources.has_key?(Vector2.new(x, y)))
        if (game.map.groundresources[Vector2.new(x, y)] == Game::Resource::Bitcoin)
          print "b"
        elsif (game.map.groundresources[Vector2.new(x, y)] == Game::Resource::Pot)
          print "p"
        elsif (game.map.groundresources[Vector2.new(x, y)] == Game::Resource::Cereal)
          print "c"
        end
        next
      end
      if (game.map.tiles[x][y] == Map::TileType::Open)
        print " "
      elsif (game.map.tiles[x][y] == Map::TileType::Mountain)
        print "^"
      elsif (game.map.tiles[x][y] == Map::TileType::Water)
        print "~"
      end
    end
    print "\n"
  end
end

# shorthand for move event
def move(player, target, delta)
  JSON.build do |json|
    json.object do
      json.field "command", "move"
      json.field "player", player
      json.field "target" do
        json.array do
          json.number target.x
          json.number target.y
        end
      end
      json.field "delta" do
        json.array do
          json.number delta.x
          json.number delta.y
        end
      end
    end
  end
end

# shorthand for buy
def buy(player, target, delta)
  JSON.build do |json|
    json.object do
      json.field "command", "buy"
      json.field "player", player
      json.field "build", build
      json.field "param", param
      json.field "target" do
        json.array do
          json.number target.x
          json.number target.y
        end
      end
    end
  end
end

# shorthand for build
def build(player, target, build)
  JSON.build do |json|
    json.object do
      json.field "command", "build"
      json.field "player", player
      json.field "build", build
      json.field "target" do
        json.array do
          json.number target.x
          json.number target.y
        end
      end
    end
  end
end



# Start two player game with one hero
g = Game.new(0, 2)
g.process_turn_start(0)
print_world_map(g)


# first move:
puts(g.accept_command(move(0,  Vector2.new(1, 3), Vector2.new(1, -1))))
puts(g.accept_command(move(0,  Vector2.new(2, 2), Vector2.new(1, 1))))
puts(g.accept_command(move(0,  Vector2.new(3, 3), Vector2.new(1, 1))))
puts(g.accept_command(move(0,  Vector2.new(4, 4), Vector2.new(1, 1))))
# gets a bitcoin pickupable.
puts(g.accept_command(move(0,  Vector2.new(5, 5), Vector2.new(1, 1))))

# second move:
g.process_turn_start(0)
puts(g.players[0])

# gets a cereal mine
puts(g.accept_command(move(0,  Vector2.new(6, 6), Vector2.new(1, 1))))

puts(g.accept_command(move(0,  Vector2.new(7, 7), Vector2.new(1, -1))))
puts(g.accept_command(move(0,  Vector2.new(8, 6), Vector2.new(1, -1))))
puts(g.accept_command(move(0,  Vector2.new(9, 5), Vector2.new(-1, 0))))
puts(g.accept_command(move(0,  Vector2.new(8, 5), Vector2.new(-1, 0))))
# gets a bitcoin mine.

puts(g.players[0].print)
# third move:
g.process_turn_start(0)
print_world_map(g)

g.process_turn_start(0)
g.process_turn_start(0)
g.process_turn_start(0)
g.process_turn_start(0)
puts(g.players[0].print)
g.process_turn_start(0)
puts(g.players[0].print)
print_world_map(g)


# order some city commands
puts(g.accept_command(build(0,  Vector2.new(1, 3), "range")))
puts(g.accept_command(build(0,  Vector2.new(1, 3), "range")))
g.process_turn_start(0)
puts(g.players[0].print)
puts(g.accept_command(build(0,  Vector2.new(1, 3), "datacenter")))
g.process_turn_start(0)
puts(g.players[0].print)
puts(g.accept_command(build(0,  Vector2.new(1, 3), "datacenter")))
g.process_turn_start(0)
puts(g.players[0].print)
g.process_turn_start(0)
puts(g.players[0].print)
puts("trying for walls")
puts(g.accept_command(build(0,  Vector2.new(1, 3), "walls")))
g.process_turn_start(0)
puts(g.accept_command(build(0,  Vector2.new(1, 3), "walls")))
puts(g.players[0].print)
g.process_turn_start(0)
puts(g.accept_command(build(0,  Vector2.new(1, 3), "walls")))
g.process_turn_start(0)
g.process_turn_start(0)
g.process_turn_start(0)
g.process_turn_start(0)
g.process_turn_start(0)
g.process_turn_start(0)
g.process_turn_start(0)
g.process_turn_start(0)
g.process_turn_start(0)
g.process_turn_start(0)
puts("walls again")
puts(g.accept_command(build(0,  Vector2.new(1, 3), "walls")))
puts(g.players[0].print)
puts(g.accept_command(build(0,  Vector2.new(1, 3), "library")))
puts(g.accept_command(build(0,  Vector2.new(1, 3), "walls")))
puts(g.accept_command(build(0,  Vector2.new(1, 3), "stables")))
puts(g.accept_command(build(0,  Vector2.new(1, 3), "workshop")))
puts(g.accept_command(build(0,  Vector2.new(1, 3), "school")))