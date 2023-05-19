require "./Player"
require "./HOMMCONSTS"
class Battle

    # three lanes
    # tier 1: warrior, moves one at a time forward or to nearest enemy
    # tier 2: archer, doesn't move
    # tier 3: cavalry, moves two a time forward
    # tier 4: ballista, hits stack behind it
    # tier 5: wizard, weak but has ranged attack

    class BattleUnit
        def initialize(@tier : Int32, @unitcount : Int32, @left : Bool)
        end
    end

    def initialize(leftHero : Hero, rightHero : Hero)
        @arena = Array(Array(BattleUnit | Nil)).new(HOMMCONSTS::BATTLE_ARENA_WIDTH) { Array(BattleUnit | Nil).new(HOMMCONSTS::BATTLE_ARENA_HEIGHT, nil)}
        # add unit stacks to arena
        leftHero.unit_stacks.each_with_index do |stack,i|
            if(stack > 0)
                @arena[i][0] = BattleUnit.new(i,stack, true)
            end
        end

        rightHero.unit_stacks.each_with_index do |stack,i|
            if(stack > 0)
                @arena[HOMMCONSTS::BATTLE_ARENA_WIDTH-1-i][0] = BattleUnit.new(i,stack, false)
            end
        end
    end

    def tick()

    end
end

# test battle
leftHero = Hero.new()
rightHero = Hero.new()
battle = Battle.new(leftHero, rightHero)
battle.tick()