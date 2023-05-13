require "./Map"
require "./Player"
require "./Hero"

# Entire game state for Heroes of Might and Memes game
class Game

  enum Resource
    Bitcoin
    Pot
    Cereal
  end
  
  def initialize(seed : Int32, playersPerTeam : Int32)
    @random = HommRandom.new(seed)
    @team1 = [] of Player
    @team2 = [] of Player
    playersPerTeam.times do |i|
      @team1 << Player.new("1#{i}")
      @team2 << Player.new("2#{i}")
    end
    @map = Map.new(seed, playersPerTeam, @random)
    # give players inital heroes
    @team1.each_with_index do |player,i|
      player.heroes[@map.team1spawn[i]] =  Hero.new()
    end
    @team2.each_with_index do |player,i|
      player.heroes[@map.team2spawn[i]] = Hero.new()
    end
  end

  def accept_command(command : String)
    if(command == "print")
      print_world_map()
    end
  end

  def process_turn_start()
    # players get income from cities and resources

  end

  def print_world_map()
    @map.size.times do |y|
      @map.size.times do |x|
        # Cities
        if(@map.cities.has_key?(Vector2.new(x,y)))
          print "X"
          next
        end
        # Farms
        if(@map.farms.has_key?(Vector2.new(x,y)))
          if(@map.farms[Vector2.new(x,y)][0] == Resource::Bitcoin)
            print "B"
          elsif(@map.farms[Vector2.new(x,y)][0] == Resource::Pot)
            print "P"
          elsif(@map.farms[Vector2.new(x,y)][0] == Resource::Cereal)
            print "C"
          end
          next
        end
        # Ground
        if(@map.groundresources.has_key?(Vector2.new(x,y)))
          if(@map.groundresources[Vector2.new(x,y)] == Resource::Bitcoin)
            print "b"
          elsif(@map.groundresources[Vector2.new(x,y)] == Resource::Pot)
            print "p"
          elsif(@map.groundresources[Vector2.new(x,y)] == Resource::Cereal)
            print "c"
          end
        end
        if(@map.tiles[x][y] == Map::TileType::Open)
          print " "
        elsif(@map.tiles[x][y] == Map::TileType::Mountain)
          print "^"
        elsif(@map.tiles[x][y] == Map::TileType::Water)
          print "~"
        end
      end
      print "\n"
    end
  end
end

Game.new(13455342, 1).print_world_map()