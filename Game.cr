require "./Map"
require "./Player"
require "./Hero"
require "json"
require "./HOMMCONSTS"

# HEROES OF TIME AND TERRITORY
class Game
  enum Resource
    Bitcoin
    Pot
    Cereal
  end

  enum CommandErrors
    NoError
    InvalidJSON
    MissingJSONKey
    InvalidTarget
    InvalidMove
    InsufficientResources
  end

  getter map : Map
  getter players : Array(Player)

  def initialize(seed : Int32, playersTotal : Int32)
    @random = HommRandom.new(seed)
    @day = 1
    @players = [] of Player
    playersTotal.times do |i|
      @players << Player.new("p#{i}",i)
    end
    # fixme
    @map = Map.new(seed, playersTotal // 2, @random)
    # give players inital heroes
    @players.each_with_index do |player, i|
      # this sucks here, heroes are not picked from a pool correctly
      player.heroes[@map.spawn[i]] = Hero.new(player,i,1,2,3)
      # all spawns start on a city
      @map.cities[@map.spawn[i]].owner = player
    end
  end

  def move_command(value : JSON::Any, playerid : Int32) : CommandErrors

    # error checking, make sure we have all the keys and targets
    begin
      target = value["target"]
      delta = value["delta"]
    rescue
      return CommandErrors::MissingJSONKey
    end

    # make sure the target is a valid hero
    begin
      targetvec = Vector2.new(target[0].as_i, target[1].as_i)
      # check if valid hero
      if(get_hero_at(targetvec) == nil)
        return CommandErrors::InvalidTarget
      end
    rescue
      return CommandErrors::InvalidTarget
    end

    # make sure the delta is a valid move
    begin
      deltavec = Vector2.new(delta[0].as_i, delta[1].as_i)
      # check if valid move
      if (deltavec.x.abs > 1 || deltavec.y.abs > 1)
        return CommandErrors::InvalidMove
      end
    rescue
      return CommandErrors::InvalidMove
    end

    # make sure the move is valid
    newpos = targetvec + deltavec
    # no OOB
    if(newpos.x < 0 || newpos.x >= @map.size || newpos.y < 0 || newpos.y >= @map.size)
      return CommandErrors::InvalidMove
    end
    # no heroes (well, for now, combat will be added later)
    if(get_hero_at(newpos) != nil)
      return CommandErrors::InvalidMove
    end
    # terrain is open
    if(@map.is_open_terrain?(newpos) == false)
      return CommandErrors::InvalidMove
    end

    # move seems good.
    player = players[playerid]
    hero = player.heroes[targetvec]

    # has points
    if(!hero.move())
      return CommandErrors::InsufficientResources
    end
    player.heroes.delete(targetvec)
    player.heroes[newpos] = hero

    # check if we picked something up
    item_at_feet = @map.take_resource(newpos)
    if(item_at_feet != nil) 
      if(item_at_feet == Resource::Bitcoin)
        player.bitcoin += HOMMCONSTS::BITCOIN_GROUNDITEM_INCOME
      end
      if(item_at_feet == Resource::Pot)
        player.pot += HOMMCONSTS::POT_GROUNDITEM_VALUE
      end
      if(item_at_feet == Resource::Cereal)
        player.cereal += HOMMCONSTS::CEREAL_FARM_INCOME
      end
    end

    # check if we can take over a city
    if(@map.cities.has_key?(newpos))
      @map.cities[newpos].owner = player
    end

    # check if we can take over a farm
    if(@map.farms.has_key?(newpos))
      @map.farms[newpos] = {@map.farms[newpos][0], player}
    end

    return CommandErrors::NoError
  end

  def buy_command(value : JSON::Any, playerid : Int32) : CommandErrors
    begin
      target = value["target"]
      buy = value["buy"]
    rescue
      return CommandErrors::MissingJSONKey
    end
    
    player = @players[playerid]

    # check if valid city
    begin
      targetvec = Vector2.new(target[0].as_i, target[1].as_i)
      buystr = buy.as_s
      if(map.cities[targetvec] == nil)
        return CommandErrors::InvalidTarget
      end
    rescue
      return CommandErrors::InvalidTarget
    end
    return map.cities[targetvec].buy_helper(buystr)
  end

  def build_command(value : JSON::Any, playerid : Int32) : CommandErrors
    begin
      target = value["target"]
      build = value["build"]
    rescue
      return CommandErrors::MissingJSONKey
    end
    
    player = @players[playerid]

    # check if valid city
    begin
      targetvec = Vector2.new(target[0].as_i, target[1].as_i)
      if(map.cities[targetvec] == nil)
        return CommandErrors::InvalidTarget
      end
      build_str = build.as_s
    rescue
      return CommandErrors::InvalidTarget
    end
    return map.cities[targetvec].build_helper(build_str)
  end

  def donate_command(value : JSON::Any, playerid : Int32) : CommandErrors
    return CommandErrors::InvalidJSON
  end

  # specify two vectors. Units can be transferred between city->hero and hero->hero
  def transfer_command(value : JSON::Any, playerid : Int32) : CommandErrors

    begin
      src = value["src"]
      dest = value["dest"]
      # src/destype must be city or hero
      srctype = value["srctype"]
      destype = value["destype"]
      # unittype
      type = value["unittype"]
      count = value["unitcount"]
    rescue
      return CommandErrors::MissingJSONKey
    end
    
    player = @players[playerid]
    # check source.
    begin
      srcvec = Vector2.new(src[0].as_i, src[1].as_i)
      destvec = Vector2.new(dest[0].as_i, dest[1].as_i)
      srcloc = nil
      destloc = nil
      if(srctype == "city")
        srcloc = map.cities[srcvec]
        #does hero have enough?
      end
      if(srctype == "hero")
        srcloc = get_hero_at(srcvec)
      end
      if(destype == "city")
        destloc = map.cities[destvec]
      end
      if(destype == "hero")
        destloc = get_hero_at(destvec)
      end
    rescue
      return CommandErrors::InvalidTarget
    end

    # check for valid src, dest 
    return CommandErrors::InvalidJSON
    
  end

  def accept_command(value : JSON::Any) : CommandErrors

    begin
      command = value["command"]
      player = value["player"].as_i
      # later - assert command came from the right player.
    rescue
      return CommandErrors::MissingJSONKey
    end

    # move a player to a tile, this is also used to enter cities, pick up resources, and start fights.
    if (command == "move")
      return move_command(value, player)
    end
    # build a building in a city. Only valid once per city per turn
    if (command == "build")
      return build_command(value, player)
    end
    # buy a unit or a new hero in a city.
    if (command == "buy")
      return buy_command(value, player)
    end
    # give resources to someone.
    if (command == "donate")
      return donate_command(value, player)
    end
    if (command == "transfer")
      return transfer_command(value, player)
    end
    if (command == "endturn")
      process_turn_start(player)
      return CommandErrors::NoError
    end
    return CommandErrors::MissingJSONKey
  end

  def process_turn_start(team : Int32)
    # players get income from cities and resources
    @players.each do |player|
      # city income
      @map.cities.each do |pos, city|
        if(city.owner == player)
          if(city.bitcoin_level == 1)
            player.bitcoin += HOMMCONSTS::CITY_BITCOIN_INCOME_LEVEL1
          elsif(city.bitcoin_level == 2)
            player.bitcoin += HOMMCONSTS::CITY_BITCOIN_INCOME_LEVEL2
          elsif(city.bitcoin_level == 3)
            player.bitcoin += HOMMCONSTS::CITY_BITCOIN_INCOME_LEVEL3
          end
        end
        city.refresh_units()
      end
      
      # farm income
      player.bitcoin += HOMMCONSTS::BITCOIN_FARM_INCOME * @map.farms.count { |k, v| v[0] == Resource::Bitcoin && v[1] == player }
      player.pot += HOMMCONSTS::POT_FARM_INCOME * @map.farms.count { |k, v| v[0] == Resource::Pot && v[1] == player }
      player.cereal += HOMMCONSTS::CEREAL_FARM_INCOME * @map.farms.count { |k, v| v[0] == Resource::Cereal && v[1] == player }

      # hero move points refresh
      player.heroes.each do |pos, hero|
        hero.refresh_points()
      end
    end
    
    # clear city build flag
    @map.cities.each do |pos, city|
      city.built = false
    end
    @day += 1
  end

  def get_hero_at(tpos : Vector2) : Hero | Nil
    @players.each do |player|
      player.heroes.each do |pos, hero|
        if (pos == tpos)
          return hero
        end
      end
    end
    return nil
  end

  # convert cities, farms because we use a dict to store the coords and vec2 can't be conv to key
  def cities_jsonable()
    cities = Array(Tuple(Int32, Int32, City, Int32)).new
    @map.cities.each do |pos, city|
      cities << {pos.x, pos.y, city, city.owner.nil? ? -1 : players.index(city.owner).as(Int32)}
    end
    return cities
  end

  def farms_jsonable()
    farms = Array(Tuple(Int32, Int32, Resource, Int32)).new
    @map.farms.each do |pos, farm|
      farms << {pos.x, pos.y, farm[0], farm[1].nil? ? -1 : players.index(farm[1]).as(Int32)}
    end
    return farms
  end

  def heroes_jsonable()
    heroes = Array(Tuple(Int32, Int32, Hero, Int32)).new
    @players.each do |player|
      player.heroes.each do |pos, hero|
        heroes << {pos.x, pos.y, hero, players.index(player).as(Int32)}
      end
    end
    return heroes
  end


  def get_gamestate_json() : String
    string = JSON.build do |json|
      json.object do
        json.field "tiles", @map.tiles
        json.field "cities", cities_jsonable()
        json.field "farms", farms_jsonable()
        json.field "players", @players
        json.field "heroes", heroes_jsonable()
        json.field "day", @day
      end
    end
  end
end