require "./HOMMCONSTS"
require "json"
class Hero
  include JSON::Serializable
  property unit_stacks : Array(Int32)
  # don't need to serialize the player
  @[JSON::Field(ignore:true)]
  property player : Player
  property attack_stat : Int32
  property health_stat : Int32
  property move_stat : Int32
  property id : Int32
  
  def initialize(player : Player, id : Int32, move : Int32, health : Int32, attack : Int32)
    @move_points = 7
    @move_stat = move
    @health_stat = health 
    @attack_stat = attack
    @unit_stacks = [5,0,0,0,0]
    @memes = [false,false,false,false,false]
    @player = player
    @id = id
  end

  def move()
    if(@move_points < HOMMCONSTS::HERO_MOVE_COST)
      return false
    end
    @move_points -= HOMMCONSTS::HERO_MOVE_COST
    return true
  end

  def refresh_points()
    @move_points += (@move_stat + HOMMCONSTS::HERO_MOVE_BASE)
    @move_points = [@move_points, HOMMCONSTS::HERO_MAX_MOVE].min
  end
end