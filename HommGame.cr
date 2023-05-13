require "./Vector2"
class HommGame

  enum TileType
    Open
    Mountain
    Water
  end

  enum Resource
    Bitcoin
    Pot
    Cereal
  end

  @map : Array(Array(TileType))
  @groundresources : Hash(Vector2, Resource)
  @farms : Hash(Vector2, Tuple(Resource, Int32))

  def initialize(seed : Int32, playersPerTeam : Int32)
    @mapsize = playersPerTeam * 10
    
    # generate map. We will only edit the left half tho
    @map = Array.new(@mapsize) { Array.new(@mapsize) { TileType::Open } }
    @groundresources = Hash(Vector2, Resource).new
    @farms = Hash(Vector2, Tuple(Resource, Int32)).new

    # Look I know we're using the same random instance for everything
    # If you can somehow use this to your advantage, you deserve it
    @random = Random.new(seed, sequence = 0_u64)

    # later : perlin noise for mountains, for now rand is okay
    mountains = rint(0,@mapsize) + (@mapsize/2).to_i
    mountains.times do |t|
      @map[rint(0,@mapsize)][rint(0,@mapsize)] = TileType::Mountain
    end

    # rivers will never intersect and should always stay in their own lane.
    rivers = (rint(0,@mapsize)/10).to_i + 1
    rivers.times do |t|
      rmin = (@mapsize * (t/rivers)).to_i
      rmax = (@mapsize * ((t+1)/rivers)).to_i - 2
      run_river(rint(rmin,rmax), rmin, rmax)
    end
  end

  # random between to integers exclusive
  def rint(lo : Int32, hi : Int32)
    return @random.rand(lo..hi-1)
  end

  # runs a river from (start_y) through the map being constrained by (ymin) and (ymax)
  def run_river(start_y : Int32, ymin : Int32, ymax : Int32)
    yptr = start_y

    # start at the side and go right
    # can either place forward, place two up, place two down
    (@mapsize/2).to_i.times do |t|
      # place left water tile
      if(t == 0)
        @map[0][yptr] = TileType::Water
        next
      end

      direction = rint(0,5)
      if(direction == 0 && yptr > ymin)
        # water up
        yptr -= 1
        @map[t][yptr] = TileType::Water
        @map[t-1][yptr] = TileType::Water
      elsif(direction == 1 && yptr < ymax)
        # water down
        yptr += 1
        @map[t][yptr] = TileType::Water
        @map[t-1][yptr] = TileType::Water
      else
        # forward
        @map[t][yptr] = TileType::Water
      end
    end
  end

  def print_world_map()
    @mapsize.times do |y|
      @mapsize.times do |x|
        if(@map[x][y] == TileType::Open)
          print " "
        elsif(@map[x][y] == TileType::Mountain)
          print "^"
        elsif(@map[x][y] == TileType::Water)
          print "~"
        end
      end
      print "\n"
    end
  end
end

HommGame.new(223344,2).print_world_map()