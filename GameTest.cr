require "./Game"

def print_world_map(game : Game)
  game.map.size.times do |y|
    game.map.size.times do |x|
      # Heroes
      if(game.get_hero_at(Vector2.new(x, y)) != nil)
        print "h"
        next
      end

      # Cities
      if (game.map.cities.has_key?(Vector2.new(x, y)))
        print "X"
        next
      end
      # Farms
      if (game.map.farms.has_key?(Vector2.new(x, y)))
        if (game.map.farms[Vector2.new(x, y)][0] == Game::Resource::Bitcoin)
          print "B"
        elsif (game.map.farms[Vector2.new(x, y)][0] == Game::Resource::Pot)
          print "P"
        elsif (game.map.farms[Vector2.new(x, y)][0] == Game::Resource::Cereal)
          print "C"
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
def move(player, team, target, delta)
  JSON.build do |json|
    json.object do
      json.field "command", "move"
      json.field "player", player
      json.field "team", team
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
# Start two player game with one hero
g = Game.new(0, 1)
g.process_turn_start(true)
print_world_map(g)


# first move:
puts(g.accept_command(move(0, 1, Vector2.new(1, 3), Vector2.new(1, -1))))
puts(g.accept_command(move(0, 1, Vector2.new(2, 2), Vector2.new(1, 1))))
puts(g.accept_command(move(0, 1, Vector2.new(3, 3), Vector2.new(1, 1))))
puts(g.accept_command(move(0, 1, Vector2.new(4, 4), Vector2.new(1, 1))))
# gets a bitcoin pickupable.
puts(g.accept_command(move(0, 1, Vector2.new(5, 5), Vector2.new(1, 1))))

# second move:
g.process_turn_start(true)
puts(g.team1[0])

# gets a cereal mine
puts(g.accept_command(move(0, 1, Vector2.new(6, 6), Vector2.new(1, 1))))

puts(g.accept_command(move(0, 1, Vector2.new(7, 7), Vector2.new(1, -1))))
puts(g.accept_command(move(0, 1, Vector2.new(8, 6), Vector2.new(1, -1))))
# gets a bitcoin mine.

puts(g.team1[0].print)
# third move:
g.process_turn_start(true)
print_world_map(g)

g.process_turn_start(true)
g.process_turn_start(true)
g.process_turn_start(true)
g.process_turn_start(true)
puts(g.team1[0].print)
print_world_map(g)

# json working better, ignore for now.. print(g.get_gamestate_json)