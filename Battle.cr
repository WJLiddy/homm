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
        getter team : Int32
        getter tier : Int32
        property hp : Int32
        def initialize(@team : Int32, @tier : Int32)    
            # set hp based on tier
            @hp = 0
            case @tier
                when 0
                    @hp = HOMMCONSTS::TIER1_HEALTH
                when 1
                    @hp = HOMMCONSTS::TIER2_HEALTH
                when 2
                    @hp = HOMMCONSTS::TIER3_HEALTH
                when 3
                    @hp = HOMMCONSTS::TIER4_HEALTH
                when 4
                    @hp = HOMMCONSTS::TIER5_HEALTH
                end
            end
    end

    getter arena : Array(Array(BattleUnit | Nil))
        

    # max army is 100 units 5 x (8 + 5 + 3 + 2 + 1) = 95
    # spawn area should be 5 lanes wide and 20 units long for a total of 100
    def initialize(leftHero : Hero, rightHero : Hero)
        @arena = Array(Array(BattleUnit | Nil)).new(HOMMCONSTS::BATTLE_ARENA_WIDTH) { Array(BattleUnit | Nil).new(HOMMCONSTS::BATTLE_ARENA_HEIGHT, nil)}
        # add unit stacks to arena
        lx_ptr = 0
        ly_ptr = 0
        turn = false
        leftHero.unit_stacks.each_with_index do |stack,i|
            stack.times do
                @arena[lx_ptr][ly_ptr] = BattleUnit.new(0,i)
                ly_ptr += 1
                if ly_ptr == HOMMCONSTS::BATTLE_ARENA_HEIGHT
                    ly_ptr = 0
                    lx_ptr += 1
                end
            end
        end

        rx_ptr = HOMMCONSTS::BATTLE_ARENA_WIDTH - 1
        ry_ptr = 0
        rightHero.unit_stacks.each_with_index do |stack,i|
            stack.times do
                @arena[rx_ptr][ry_ptr] = BattleUnit.new(1,i)
                ry_ptr += 1
                if ry_ptr == HOMMCONSTS::BATTLE_ARENA_HEIGHT
                    ry_ptr = 0
                    rx_ptr -= 1
                end
            end
        end
    end

    def tick()
        arena_next = Array(Array(BattleUnit | Nil)).new(HOMMCONSTS::BATTLE_ARENA_WIDTH) { Array(BattleUnit | Nil).new(HOMMCONSTS::BATTLE_ARENA_HEIGHT, nil)}
        # iterate over every unit the army
        @arena.each_with_index do |ary, x|
            ary.each_with_index do |unit, y|
                if unit != nil
                    if (unit.as(BattleUnit)).team == 0 
                        # move right
                        if (x < HOMMCONSTS::BATTLE_ARENA_WIDTH - 1) && @turn && @arena[x+1][y] == nil
                            arena_next[x+1][y] = unit
                        else
                            arena_next[x][y] = unit                           
                        end
                    elsif (unit.as(BattleUnit)).team != 0
                        # move left
                        if x > 0 && !@turn && @arena[x-1][y] == nil
                            arena_next[x-1][y] = unit
                        else
                            arena_next[x][y] = unit                           
                        end
                    end
                end
                
            end
        end
        @arena = arena_next
        @turn = !@turn
    end
end

