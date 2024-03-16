require "./Map"
require "./Player"
require "./Hero"
require "./Battle"
require "json"
require "./HOMMCONSTS"

# HEROES OF TIME AND TERRITORY
# Games MUST be teams of 2. 
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

  def initialize(seed : Int32, playersPerSide : Int32)
    @random = HommRandom.new(seed)
    @day = 0
    @team = true
    
    @availableHeroes = Array(Tuple(Int32,Int32,Int32,Int32)).new
    # hardcoded but it's k
    @availableHeroes << {0,2,1,0}
    @availableHeroes << {1,1,2,0}
    @availableHeroes << {2,2,0,1}
    @availableHeroes << {3,0,2,1}
    @availableHeroes << {4,1,0,2}
    @availableHeroes << {5,0,1,2}
    
    @availableHeroes << {6,2,1,0}
    @availableHeroes << {7,1,2,0}
    @availableHeroes << {8,2,0,1}
    @availableHeroes << {9,0,2,1}
    @availableHeroes << {10,1,0,2}
    @availableHeroes << {11,0,1,2}

    @availableHeroes << {12,2,1,0}
    @availableHeroes << {13,1,2,0}
    @availableHeroes << {14,2,0,1}
    @availableHeroes << {15,0,2,1}
    @availableHeroes << {16,1,0,2}
    @availableHeroes << {17,0,1,2}   

    @players = [] of Player
    playersPerSide.times do |i|
      @players << Player.new("pE#{i}",false)
      @players << Player.new("pO#{i}",true)
    end

    @map = Map.new(seed, playersPerSide, @random)
    @players.each_with_index do |player, i|
      h = get_random_hero()
      # shitty hack to make sure spawns are cross-map
      if(i % 2 == 0)
        player.heroes[@map.spawn[i//2]] = Hero.new(player,h[0],h[1],h[2],h[3])
        # all spawns start on a city
        @map.cities[@map.spawn[i//2]].owner = player
      else
        player.heroes[@map.spawn.reverse[i//2]] = Hero.new(player,h[0],h[1],h[2],h[3])
        # all spawns start on a city
        @map.cities[@map.spawn.reverse[i//2]].owner = player
      end

    end
    @battles = Array(Tuple(Vector2,Vector2, Battle)).new
  end

  def move_command(value : JSON::Any, playerid : Int32) : CommandErrors

    
    # piggyback off name comand..
    begin
      players[playerid].name = value["name"].to_s
    rescue
    end

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
      if(get_hero_at(targetvec) == nil || get_hero_at(targetvec).as(Hero).player != players[playerid])
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

    # make sure we aren't battling
    @battles.each do |b|
      if(b[0] == targetvec || b[1] == targetvec)
        return CommandErrors::InvalidMove
      end
    end
    

    # terrain is open
    if(@map.is_open_terrain?(newpos) == false)
      return CommandErrors::InvalidMove
    end

    battling = nil
    # no moving through friendlies
    if(get_hero_at(newpos) != nil)
      if(get_hero_at(newpos).as(Hero).player == players[playerid])
        return CommandErrors::InvalidMove
      else
        # check if unit is already battling
        @battles.each do |b|
          if(b[0] == newpos || b[1] == newpos)
            return CommandErrors::InvalidMove
          end
        end
        # battle!
        dispstr = "Watch Battle:\n#{get_hero_at(targetvec).as(Hero).player.name} vs.\n#{get_hero_at(newpos).as(Hero).player.name}"
        @battles << {targetvec, newpos, Battle.new(get_hero_at(targetvec).as(Hero), get_hero_at(newpos).as(Hero),dispstr)}
        return CommandErrors::NoError
      end
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

    # hero?
    if(build_str == "hero" && get_hero_at(targetvec) == nil && @availableHeroes.size > 0)
      h = get_random_hero()
      player.heroes[targetvec] = Hero.new(player,h[0],h[1],h[2],h[3])
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
      destype = value["desttype"]
      # unittype, should be string but I'm trying to hurry
      type = value["type"]
    rescue
      return CommandErrors::MissingJSONKey
    end
    
    player = @players[playerid]
    # check source.
    begin
      srcvec = Vector2.new(src[0].as_i, src[1].as_i)
      destvec = Vector2.new(dest[0].as_i, dest[1].as_i)

      if(srctype == "city" && destype == "hero")
        srcloc = map.cities[srcvec]
        destloc = get_hero_at(destvec)
        if(srcvec.x == destvec.x && srcvec.y == destvec.y)
          # try transfer from city to hero destloc
          return srcloc.transfer_helper(type.as_i, destloc.as(Hero), true)
        end
      end

      if(srctype == "hero" && destype == "city")
        srcloc = map.cities[srcvec]
        destloc = get_hero_at(destvec)
        if(srcvec.x == destvec.x && srcvec.y == destvec.y)
          # try transfer from city to hero destloc
          return srcloc.transfer_helper(type.as_i, destloc.as(Hero), false)
        end
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

    # even a valid player?
    if(player < 0 || player >= @players.size)
      return CommandErrors::InvalidTarget
    end

    # no moves when not your turn!
    if(@players[player].ended_turn)
      return CommandErrors::NoError
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

      # don't end your turn if there's a battle.
      @players[player].heroes.each do |pos, hero|
        @battles.each do |b|
          if(b[0] == pos || b[1] == pos)
            return CommandErrors::InvalidMove
          end
        end
      end

      @players[player].ended_turn = true

      # debug hack
      process_turn_start()
      process_turn_start()
      @players[player].ended_turn = false
      return CommandErrors::NoError
      # end

      # later ->
      if(@players.all? { |player| player.ended_turn })
      # run
        process_turn_start()
        # all even players move if @team
        @players.each_with_index do |p, i|
          if((@team && i % 2 == 0) || (!@team && i % 2 == 1))
            p.ended_turn = false
          end
        end
      end
      return CommandErrors::NoError
    end
    return CommandErrors::MissingJSONKey
  end

  def process_turn_start()
    # next turn!
    @team = !@team
    @players.each do |player|
      if(player.team == @team)

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
            city.refresh_units() if ((@day % 7 == 6))
          end
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
    end
    # clear city build flag
    @map.cities.each do |pos, city|
      city.built = false
    end
    @day += 1 if !@team
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

  def get_random_hero()
    i = rand(@availableHeroes.size)
    ret = @availableHeroes[i]
    @availableHeroes.delete_at(i)
    return ret
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

  def battles_jsonable()
    b = Array(Tuple(Int32, Int32, Int32, Int32, Battle)).new
    @battles.each do |battle|
      b << {battle[0].x, battle[0].y, battle[1].x, battle[1].y, battle[2]}
    end
    return b
  end

  def grounditems_jsonable()
    items = Array(Tuple(Int32, Int32, Resource)).new
    @map.groundresources.each do |pos, item|
      items << {pos.x, pos.y, item}
    end
    return items
  end

  def runbattles()
    finishbattles = [] of Int32
    @battles.each_with_index do |battle, i|
      battle[2].tick()
      attacker_alive = battle[2].teamsurv(0)
      defender_alive = battle[2].teamsurv(1)
      if(attacker_alive && !defender_alive)
        finishbattles << i
        # kill defender, end battle
        @players.each do |player|
          player.heroes.delete(battle[1])
            # later- return hero to pool
            get_hero_at(battle[0]).as(Hero).unit_stacks = battle[2].getstackcount(0)
        end
      end

      # kill attacker, end battle
      if(!attacker_alive && defender_alive)     
        finishbattles << i
        @players.each do |player|
          player.heroes.delete(battle[0])
          get_hero_at(battle[1]).as(Hero).unit_stacks = battle[2].getstackcount(1)
          # later- return hero to pool
        end
      end
    end

    finishbattles.reverse!

    # clean up finished battles
    finishbattles.each do |i|
      @battles.delete_at(i)
    end
  end


  def get_gamestate_json() : String
    string = JSON.build do |json|
      json.object do
        json.field "tiles", @map.tiles
        json.field "grounditems", grounditems_jsonable()
        json.field "cities", cities_jsonable()
        json.field "farms", farms_jsonable()
        json.field "players", @players
        json.field "heroes", heroes_jsonable()
        json.field "day", @day
        json.field "team", @team
        json.field "battles", battles_jsonable()
      end
    end
  end
end