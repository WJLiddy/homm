require "./HOMMCONSTS"

class Hero
  property unit_stacks : Array(Int32)
  def initialize()
    @move_points = 20
    @skill_attack = 0
    @skill_move = 0
    @skill_meme = 0
    @unit_stacks = [5,0,0,0,0]
    @memes = [false,false,false,false,false]
  end

  def move()
    if(@move_points < HOMMCONSTS::HERO_MOVE_COST)
      return false
    end
    @move_points -= HOMMCONSTS::HERO_MOVE_COST
    return true
  end

  def refresh_points()
    @move_points += HOMMCONSTS::HERO_MOVE_RECOVERY
    @move_points = [@move_points, HOMMCONSTS::HERO_MAX_MOVE].min
  end
end