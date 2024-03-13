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

    def movevert(x : Int32, y : Int32, pol : Int32, arena_next : Array(Array(BattleUnit | Nil))) : Bool
        # if there is a unit in the next rank, but not in front of me, move up
        # this is allowed because we check low Y first.
        unit_in_front = false
        HOMMCONSTS::BATTLE_ARENA_HEIGHT.times do |ny|
            if(arena_next[x+pol][ny] != nil && (arena_next[x+pol][ny].as(BattleUnit).team != @arena[x][y].as(BattleUnit).team))
                unit_in_front = true
            end
        end

        if(unit_in_front && arena_next[x][y-1] == nil)
            # moveup
            arena_next[x][y-1] = @arena[x][y]
            return true
        end

        arena_next[x][y] = @arena[x][y]
        return true
    end

    def movehorz(x : Int32, y : Int32, pol : Int32, arena_next : Array(Array(BattleUnit | Nil))) : Bool
        if(arena_next[x+pol][y] == nil)
            arena_next[x+pol][y] = @arena[x][y]
            return true
        end
        return false
    end

    def attack(x : Int32, y : Int32, pol : Int32, arena_next : Array(Array(BattleUnit | Nil))) : Bool
        return false
    end


    def tick()
        arena_next = Array(Array(BattleUnit | Nil)).new(HOMMCONSTS::BATTLE_ARENA_WIDTH) { Array(BattleUnit | Nil).new(HOMMCONSTS::BATTLE_ARENA_HEIGHT, nil)}
        # polarity matters. When units go right, the rightmost unit needs to decide the move first.
        # 
        HOMMCONSTS::BATTLE_ARENA_WIDTH.times do |x|
            HOMMCONSTS::BATTLE_ARENA_HEIGHT.times do |y|
                adj_x = (@turn) ? (HOMMCONSTS::BATTLE_ARENA_WIDTH - 1 - x) : x
                pol = (@turn) ? 1 : -1
                if @arena[adj_x][y] != nil
                    unit = @arena[adj_x][y].as(BattleUnit)
                    if unit.team == 0 && @turn || unit.team == 1 && !@turn
                        (attack(adj_x,y,pol,arena_next) || movehorz(adj_x,y,pol,arena_next) || movevert(adj_x,y,pol,arena_next) )
                    else
                        arena_next[adj_x][y] = unit
                    end
                end      
            end
        end
        @arena = arena_next
        @turn = !@turn
    end
end

