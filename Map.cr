require "./Vector2"
require "./Game"
require "./City"
require "./HommRandom"

# Game world, with cities and resources. No players.
class Map
  enum TileType
    Open
    Mountain
    Water
  end

  getter size : Int32
  getter tiles : Array(Array(TileType))
  getter cities : Hash(Vector2, City)
  getter farms : Hash(Vector2, Tuple(Game::Resource, Player | Nil))
  getter groundresources : Hash(Vector2, Game::Resource)
  getter spawn : Array(Vector2)

  def initialize(seed : Int32, @playersPerTeam : Int32, hr : HommRandom)
    @size = 15 + @playersPerTeam * 7
    @hr = hr

    # generate map. We will only edit the left half tho
    @tiles = Array.new(@size) { Array.new(@size) { TileType::Open } }
    @groundresources = Hash(Vector2, Game::Resource).new
    @farms = Hash(Vector2, Tuple(Game::Resource, Player | Nil)).new
    @cities = Hash(Vector2, City).new
    @spawn = Array(Vector2).new
    @playersPerTeam = playersPerTeam

    spawn_mountains()
    spawn_rivers()
    spawn_cities()
    spawn_farms()
    spawn_groundresources()
    add_bridges()
    mirror()
  end

  def spawn_mountains
    # mountains. later : perlin noise for mountains, for now rand is okay
    mountains = @hr.rint(0, @size) + (@size).to_i
    mountains.times do |t|
      @tiles[@hr.rint(0, @size)][@hr.rint(0, @size)] = TileType::Mountain
    end
  end

  def spawn_rivers
    # rivers. will never intersect and should always stay in their own lane.
    rivers = @playersPerTeam*2
    rivers.times do |t|
      rmin = (@size * (t/rivers)).to_i
      rmax = (@size * ((t + 1)/rivers)).to_i - 2
      run_river(@hr.rint(rmin, rmax), rmin, rmax)
    end
  end

  def spawn_cities
    # cities. later, make sure that all of them can be connected.
    # 1v1 : 4
    # 2v2 : 6
    # 3v3 : 6
    citycount = Math.min(3,1 + @playersPerTeam)
    citycount.times do |c|
      xmin = ((@size/2) * (c/citycount)).to_i
      xmax = ((@size/2) * ((c + 1)/citycount)).to_i - 2
      pos = Vector2.new(@hr.rint(xmin, xmax), @hr.rint(0, @size))
      @cities[pos] = City.new
      @spawn << pos
      @tiles[pos.x][pos.y] = TileType::Open
      # assign this city to a player.
    end
  end

  def random_open_tile
    pos = Vector2.new(@hr.rint(0, (@size/2).to_i), @hr.rint(0, @size))
    # only spawn on open terrain, only spawn where there's no city and no other resources
    while (!is_open_terrain?(pos) || @cities.has_key?(pos) || @groundresources.has_key?(pos))
      pos = Vector2.new(@hr.rint(0, (@size/2).to_i), @hr.rint(0, @size))
    end
    return pos
  end

  def spawn_farms
    # add bitcoin, pot, cereal farms
    bitcoin_farm_count = 2*@playersPerTeam
    pot_farm_count = 2*@playersPerTeam
    cereal_farm_count = 2*@playersPerTeam

    bitcoin_farm_count.times do |t|
      pos = random_open_tile
      @farms[pos] = {Game::Resource::Bitcoin,nil}
    end

    pot_farm_count.times do |t|
      pos = random_open_tile
      @farms[pos] = {Game::Resource::Pot,nil}
    end

    cereal_farm_count.times do |t|
      pos = random_open_tile
      @farms[pos] = {Game::Resource::Cereal,nil}
    end
  end

  def spawn_groundresources
    bitcoin_ground_count = 4*@playersPerTeam
    pot_ground_count = 3*@playersPerTeam
    cereal_ground_count = 3*@playersPerTeam

    bitcoin_ground_count.times do |t|
      pos = random_open_tile
      @groundresources[pos] = Game::Resource::Bitcoin
    end

    pot_ground_count.times do |t|
      pos = random_open_tile
      @groundresources[pos] = Game::Resource::Pot
    end

    cereal_ground_count.times do |t|
      pos = random_open_tile
      @groundresources[pos] = Game::Resource::Cereal
    end
  end

  # runs a river from (start_y) through the map being constrained by (ymin) and (ymax)
  def run_river(start_y : Int32, ymin : Int32, ymax : Int32)
    yptr = start_y

    # start at the side and go right
    # can either place forward, place two up, place two down
    (@size/2).to_i.times do |t|
      # place left water tile
      if (t == 0)
        @tiles[0][yptr] = TileType::Water
        next
      end

      direction = @hr.rint(0, 5)
      if (direction == 0 && yptr > ymin)
        # water up
        yptr -= 1
        @tiles[t][yptr] = TileType::Water
        @tiles[t - 1][yptr] = TileType::Water
      elsif (direction == 1 && yptr < ymax)
        # water down
        yptr += 1
        @tiles[t][yptr] = TileType::Water
        @tiles[t - 1][yptr] = TileType::Water
      else
        # forward
        @tiles[t][yptr] = TileType::Water
      end
    end
  end

  def add_bridges()
    @size.times do |x|
      @size.times do |y|
        if (@tiles[x][y] == TileType::Water)
          # check if we can place a bridge
          if (y > 0 && @tiles[x][y-1] == TileType::Open && y < @size-1 && @tiles[x][y+1] == TileType::Open && @hr.rint(0, 4) == 0)
            @tiles[x][y] = TileType::Open
          end
        end
      end
    end
  end

  def mirror
    # mirror the map
    @size.times do |x|
      @size.times do |y|
        @tiles[@size - x - 1][y] = @tiles[x][y]
      end
    end

    @cities.each do |k, v|
      @cities[Vector2.new(@size - k.x - 1, k.y)] = City.new
    end

    @farms.each do |k, v|
      @farms[Vector2.new(@size - k.x - 1, k.y)] = v
    end

    @groundresources.each do |k, v|
      @groundresources[Vector2.new(@size - k.x - 1, k.y)] = v
    end

    mirrored_spawns = [] of Vector2
    @spawn.each do |k|
      mirrored_spawns << Vector2.new(@size - k.x - 1, k.y)
    end
    @spawn = @spawn + mirrored_spawns
  end

  def is_open_terrain?(pos : Vector2)
    return @tiles[pos.x][pos.y] == TileType::Open
  end

  def take_resource(pos : Vector2)
    if (@groundresources.has_key?(pos))
      res = @groundresources[pos]
      @groundresources.delete(pos)
      return res
    end
    return nil
  end
end
