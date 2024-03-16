require "./Game"
require "colorize"

def colorize_team(string : String, playerID : Int32 | Nil)
  if(playerID == nil)
    return string.colorize(:white)
  end
  colors = [:blue, :red, :green, :yellow, :magenta, :white]
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
  JSON.parse(
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
  end)
end

# shorthand for buy
def buy(player, target, delta)
  JSON.parse(
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
  end)
end

# shorthand for build
def build(player, target, build)
  JSON.parse(
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
  )
end


# shorthand for build
def endturn(player)
  JSON.parse(
  JSON.build do |json|
    json.object do
      json.field "command", "endturn"
      json.field "player", player
    end
  end
  )
end



# Start six player game
g = Game.new(0, 1)

100000.times do
  # accept random commands
  g.accept_command(move(rand(6), Vector2.new(rand(30),rand(30)) , Vector2.new(rand(3) - 1, rand(3) - 1)))
  g.accept_command(endturn(rand(6)))
end

print_world_map(g)