require "./Map"
require "./Player"
require "./Hero"
require "json"
require "./HOMMCONSTS"

# HEROES OF TIME AND TERRIOTORY
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
  getter team1 : Array(Player)
  getter team2 : Array(Player)

  def initialize(seed : Int32, playersPerTeam : Int32)
    @random = HommRandom.new(seed)
    @team1 = [] of Player
    @team2 = [] of Player
    playersPerTeam.times do |i|
      @team1 << Player.new("t1p#{i}")
      @team2 << Player.new("t2p#{i}")
    end
    @map = Map.new(seed, playersPerTeam, @random)
    # give players inital heroes
    @team1.each_with_index do |player, i|
      player.heroes[@map.team1spawn[i]] = Hero.new
    end
    @team2.each_with_index do |player, i|
      player.heroes[@map.team2spawn[i]] = Hero.new
    end
  end

  def move_command(value : JSON::Any, playerid : Int32, team : Int32)

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
    player = team == 1 ? @team1[playerid] : @team2[playerid]
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
      print("!!farm taken!")
      @map.farms[newpos] = {@map.farms[newpos][0], player}
    end

    return CommandErrors::NoError
  end

  def build_command(value : JSON::Any, player : Int32, team : Int32)
      # check if valid player
      # check if valid city
      # check if valid unlock
      # check if build finished today.
      # check if has resources
  end

  def buy_command(value : JSON::Any, player : Int32, team : Int32)
      # check if valid player
      # check if valid city
      # check if valid unlock
      # check if has resources
  end

  def donate_command(value : JSON::Any, player : Int32, team : Int32)

  end

  def transfer_command(value : JSON::Any, player : Int32, team : Int32)

  end

  def accept_command(command : String)
    begin
      value = JSON.parse(command)
    rescue
      return CommandErrors::InvalidJSON
    end

    begin
      command = value["command"]
      # bad...
      player = value["player"].as_i
      team = value["team"].as_i
    rescue
      return CommandErrors::MissingJSONKey
    end

    # move a player to a tile, this is also used to enter cities, pick up resources, and start fights.
    if (command == "move")
      return move_command(value, player, team)
    end
    # build a building in a city. Only valid once per city per turn
    if (command == "build")
      return build_command(value, player, team)
    end
    # buy a unit or a new hero in a city.
    if (command == "buy")
      return buy_command(value, player, team)
    end
    # give resources to someone.
    if (command == "donate")
      return donate_command(value, player, team)
    end
    if (command == "transfer")
      return transfer_command(value, player, team)
    end
  end

  def process_turn_start(team1 : Bool)
    # players get income from cities and resources
    (team1 ? @team1 : @team2).each do |player|
      player.bitcoin += HOMMCONSTS::CITY_BITCOIN_INCOME_LEVEL1 * @map.cities.count { |k, v| v.owner == player }
      player.bitcoin += HOMMCONSTS::BITCOIN_FARM_INCOME * @map.farms.count { |k, v| v[0] == Resource::Bitcoin && v[1] == player }
      player.pot += HOMMCONSTS::POT_FARM_INCOME * @map.farms.count { |k, v| v[0] == Resource::Pot && v[1] == player }
      player.cereal += HOMMCONSTS::CEREAL_FARM_INCOME * @map.farms.count { |k, v| v[0] == Resource::Cereal && v[1] == player }
      player.heroes.each do |pos, hero|
        hero.refresh_points()
      end
    end
  end

  def get_hero_at(tpos : Vector2) : Hero | Nil
    (@team1 + @team2).each do |player|
      player.heroes.each do |pos, hero|
        if (pos == tpos)
          return hero
        end
      end
    end
    return nil
  end

  # later, add owner...
  def cities_jsonable()
    cities = Array(Tuple(Int32, Int32, City)).new
    @map.cities.each do |pos, city|
      cities << {pos.x, pos.y, city}
    end
    return cities
  end


  def get_gamestate_json() : String
    string = JSON.build do |json|
      json.object do
        json.field "tiles", @map.tiles
        json.field "cities", cities_jsonable()
      end
    end
  end
end