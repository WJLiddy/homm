require "./Player"
require "./HOMMCONSTS"
class Battle
    include JSON::Serializable

    # three lanes
    # tier 1: warrior, moves one at a time forward or to nearest enemy
    # tier 2: archer, doesn't move
    # tier 3: cavalry, moves two a time forward
    # tier 4: ballista, hits stack behind it
    # tier 5: wizard, weak but has ranged attack
    @@ID_CTR = 0

    # really should be a "team" bool
    class BattleUnit
            include JSON::Serializable
        getter team : Int32
        getter tier : Int32
        property hp : Int32
        getter id : Int32
        def initialize(@team : Int32, @tier : Int32, @id : Int32)    
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
    getter attacks : Array(Array(Int32))
        

    # max army is 100 units 5 x (8 + 5 + 3 + 2 + 1) = 95
    # spawn area should be 5 lanes wide and 20 units long for a total of 100
    # this initalizer is an affront to god
    # left hero is attacking hero, right hero is defending hero
    def initialize(leftHero : Hero, rightHero : Hero, @info : String)
        @arena = Array(Array(BattleUnit | Nil)).new(HOMMCONSTS::BATTLE_ARENA_WIDTH) { Array(BattleUnit | Nil).new(HOMMCONSTS::BATTLE_ARENA_HEIGHT, nil)}
        # add unit stacks to arena
        lx_ptr = 0
        ly_ptr = 0
        @attacks = Array(Array(Int32)).new
        turn = false
        leftHero.unit_stacks.each_with_index do |stack,i|
            stack.times do
                @arena[lx_ptr][ly_ptr] = BattleUnit.new(0,i,@@ID_CTR += 1)
                ly_ptr += 1
                if ly_ptr == HOMMCONSTS::BATTLE_ARENA_HEIGHT
                    ly_ptr = 0
                    lx_ptr += 1
                end
            end
        end
        # possibly shuffle some front ranks forward so the first player doesn't always have an advantage
        lx_ptr += 1
        while(lx_ptr >= 0)
            HOMMCONSTS::BATTLE_ARENA_HEIGHT.times do |y|
                pol = 1
                if @arena[lx_ptr][y] != nil && @arena[lx_ptr+pol][y] == nil && rand(2) == 1
                    unit = @arena[lx_ptr][y].as(BattleUnit)
                    @arena[lx_ptr][y] = nil
                    @arena[lx_ptr+pol][y] = unit
                end      
            end
            lx_ptr -= 1
        end

        rx_ptr = HOMMCONSTS::BATTLE_ARENA_WIDTH - 1
        ry_ptr = 0
        rightHero.unit_stacks.each_with_index do |stack,i|
            stack.times do
                @arena[rx_ptr][ry_ptr] = BattleUnit.new(1,i,@@ID_CTR += 1)
                ry_ptr += 1
                if ry_ptr == HOMMCONSTS::BATTLE_ARENA_HEIGHT
                    ry_ptr = 0
                    rx_ptr -= 1
                end
            end
        end

        # possibly shuffle..
        rx_ptr -= 1
        while(rx_ptr < HOMMCONSTS::BATTLE_ARENA_WIDTH)
            HOMMCONSTS::BATTLE_ARENA_HEIGHT.times do |y|
                pol = -1
                if @arena[rx_ptr][y] != nil && @arena[rx_ptr+pol][y] == nil && rand(2) == 1
                    unit = @arena[rx_ptr][y].as(BattleUnit)
                    @arena[rx_ptr][y] = nil
                    @arena[rx_ptr+pol][y] = unit
                end      
            end
            rx_ptr += 1
        end
        @leftHero = leftHero
        @rightHero = rightHero
    end

    def movevert(x : Int32, y : Int32, pol : Int32, arena_next : Array(Array(BattleUnit | Nil))) : Bool
        if(y != 0 && arena_next[x][y-1] == nil)
            # moveup
            arena_next[x][y-1] = @arena[x][y]
            return true
        end

        arena_next[x][y] = @arena[x][y]
        return true
    end

    def movehorz(x : Int32, y : Int32, pol : Int32, arena_next : Array(Array(BattleUnit | Nil))) : Bool
        # if there is a unit in the next rank, we can't move up
        unit_in_front = false
        HOMMCONSTS::BATTLE_ARENA_HEIGHT.times do |ny|
            if(arena_next[x+pol][ny] != nil && (arena_next[x+pol][ny].as(BattleUnit).team != @arena[x][y].as(BattleUnit).team))
                unit_in_front = true
            end
        end

        if(arena_next[x+pol][y] == nil && !unit_in_front)
            arena_next[x+pol][y] = @arena[x][y]
            return true
        end
        return false
    end

    # probably should have array'd these lol
    def get_damage_for_unit(tier : Int32, bonus : Int32) : Int32
        case tier
        when 0
            return HOMMCONSTS::TIER1_DAMAGE + rand(HOMMCONSTS::TIER1_DAMAGE_RAND) + bonus
        when 1
            return HOMMCONSTS::TIER2_DAMAGE + rand(HOMMCONSTS::TIER2_DAMAGE_RAND) + bonus
        when 2
            return HOMMCONSTS::TIER3_DAMAGE + rand(HOMMCONSTS::TIER3_DAMAGE_RAND) + bonus
        when 3
            return HOMMCONSTS::TIER4_DAMAGE + rand(HOMMCONSTS::TIER4_DAMAGE_RAND) + bonus
        when 4
            return HOMMCONSTS::TIER5_DAMAGE + rand(HOMMCONSTS::TIER5_DAMAGE_RAND) + bonus
        end
        return 0
    end

    def attack(x : Int32, y : Int32, pol : Int32, arena_next : Array(Array(BattleUnit | Nil))) : Bool
        unittype = @arena[x][y].as(BattleUnit).tier

        bonus = 0
        # find bonus
        if(@arena[x][y].as(BattleUnit).team == 0 && rand(10) == 0)
            bonus = @leftHero.attack_stat - @rightHero.health_stat
        end

        if(@arena[x][y].as(BattleUnit).team == 1 && rand(10) == 0)
            bonus = @rightHero.attack_stat - @leftHero.health_stat
        end
        
        if((unittype == 0 || unittype == 2) && arena_next[x+pol][y] != nil && (arena_next[x+pol][y].as(BattleUnit).team != @arena[x][y].as(BattleUnit).team))
                  
            # attack
            arena_next[x+pol][y].as(BattleUnit).hp -= get_damage_for_unit(@arena[x][y].as(BattleUnit).tier, bonus)
            @attacks.push([@arena[x][y].as(BattleUnit).id,x+pol,y])
            # kill will be cleaned up when we move forward..
            arena_next[x][y] = @arena[x][y]
            return true
        end

        if(unittype == 1 || unittype == 3 || unittype == 4)
            # otherwise, we can target anyone in front of us
            4.times do |fwd|
                # OOB check
                return false if(x+(pol*fwd) < 0 || x+(pol*fwd) >= HOMMCONSTS::BATTLE_ARENA_WIDTH)

                if(arena_next[x+(pol*fwd)][y] != nil && (arena_next[x+(pol*fwd)][y].as(BattleUnit).team != @arena[x][y].as(BattleUnit).team))
                    # attack
                    arena_next[x+(pol*fwd)][y].as(BattleUnit).hp -= get_damage_for_unit(@arena[x][y].as(BattleUnit).tier, bonus)
                    @attacks.push([@arena[x][y].as(BattleUnit).id,x+pol,y])
                    # kill will be cleaned up when we move forward..
                    arena_next[x][y] = @arena[x][y]
                    return true
                end
            end
        end
        return false
    end

    def teamsurv(team : Int32) : Bool
        HOMMCONSTS::BATTLE_ARENA_WIDTH.times do |x|
            HOMMCONSTS::BATTLE_ARENA_HEIGHT.times do |y|
                if(@arena[x][y] != nil && @arena[x][y].as(BattleUnit).team == team)
                    return true
                end
            end
        end
        return false
    end

    def getstackcount(team : Int32)
        count = [0,0,0,0,0]
        HOMMCONSTS::BATTLE_ARENA_WIDTH.times do |x|
            HOMMCONSTS::BATTLE_ARENA_HEIGHT.times do |y|
                if(@arena[x][y] != nil && @arena[x][y].as(BattleUnit).team == team)
                    count[@arena[x][y].as(BattleUnit).tier] += 1
                end
            end
        end
        return count
    end

    def tick()
        @attacks = Array(Array(Int32)).new
        arena_next = Array(Array(BattleUnit | Nil)).new(HOMMCONSTS::BATTLE_ARENA_WIDTH) { Array(BattleUnit | Nil).new(HOMMCONSTS::BATTLE_ARENA_HEIGHT, nil)}
        # polarity matters. When units go right, the rightmost unit needs to decide the move first.
        HOMMCONSTS::BATTLE_ARENA_WIDTH.times do |x|
            HOMMCONSTS::BATTLE_ARENA_HEIGHT.times do |y|
                adj_x = (@turn) ? (HOMMCONSTS::BATTLE_ARENA_WIDTH - 1 - x) : x
                pol = (@turn) ? 1 : -1
                if @arena[adj_x][y] != nil
                    unit = @arena[adj_x][y].as(BattleUnit)
                    if(unit.hp > 0)
                        
                        # do not run any logic if we reach the last line
                        if (unit.team == 0 && @turn && adj_x < HOMMCONSTS::BATTLE_ARENA_WIDTH - 1) || (unit.team == 1 && !@turn && adj_x > 0)
                            (attack(adj_x,y,pol,arena_next) || movehorz(adj_x,y,pol,arena_next) || movevert(adj_x,y,pol,arena_next) )
                        else
                            arena_next[adj_x][y] = unit
                        end
                    end
                end      
            end
        end
        @arena = arena_next
        @turn = !@turn
    end

    def get_battle_json()
        string = JSON.build do |json|
            json.object do
                json.field "grid", @arena
                json.field "attacks", @attacks
                json.field "info", @info
            end
        end
    end
end

