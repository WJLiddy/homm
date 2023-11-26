require "json"

class City
    include JSON::Serializable
    
    # don't need to serialize the player, it's set in the json.
    @[JSON::Field(ignore:true)]
    property owner : Player | Nil

    def initialize()
        # 1 - 3, how fast can you mine bitcoins?
        @bitcoin_level = 1
        # 1 - 3, how good are your defenses?
        @defense_level = 0
        # 1 - 3, how many memes can your hero learn?
        @meme_level = 0
        # which units can this city train?
        @unit_unlocks = [true,false,false,false,false]
        # which units are available to train?
        @units_available = [0,0,0,0,0]
        # which units are garrisoned?
        @units_garrisoned = [0,0,0,0,0]
        # who owns the city?
        @owner = nil
        # did anyone build this turn?
        @built = false
    end

    # yucky but i dont care lol
    def upgrade_bitcoin_level()
        return if @owner.nil?
        owner = (@owner.as Player)
        if @bitcoin_level == 1 && owner.bitcoin >= HOMMCONSTS::LEVEL2_BITCOIN_UPGRADE_COST
            owner.bitcoin -= HOMMCONSTS::LEVEL2_BITCOIN_UPGRADE_COST
            @bitcoin_level = 2
            @built = true
            return true
        elsif @bitcoin_level == 2 && owner.bitcoin >= HOMMCONSTS::LEVEL3_BITCOIN_UPGRADE_COST
            owner.bitcoin -= HOMMCONSTS::LEVEL3_BITCOIN_UPGRADE_COST
            @bitcoin_level = 3
            @built = true
            return true
        end
        return false
    end

    def upgrade_defense_level()
        return if @owner.nil?
        owner = (@owner.as Player)
        if @defense_level == 0 && owner.bitcoin >= HOMMCONSTS::LEVEL1_DEFENSE_COST_BITCOIN  && owner.cereal >= HOMMCONSTS::LEVEL1_DEFENSE_COST_CEREAL
            owner.bitcoin -= HOMMCONSTS::LEVEL1_DEFENSE_COST_BITCOIN
            owner.cereal -= HOMMCONSTS::LEVEL1_DEFENSE_COST_CEREAL
            @defense_level = 1
            @built = true
            return true
        elsif @defense_level == 1 && owner.bitcoin >= HOMMCONSTS::LEVEL2_DEFENSE_COST_BITCOIN  && owner.cereal >= HOMMCONSTS::LEVEL2_DEFENSE_COST_CEREAL
            owner.bitcoin -= HOMMCONSTS::LEVEL2_DEFENSE_COST_BITCOIN
            owner.cereal -= HOMMCONSTS::LEVEL2_DEFENSE_COST_CEREAL
            @defense_level = 2
            @built = true
            return true
        elsif @defense_level == 2 && owner.bitcoin >= HOMMCONSTS::LEVEL3_DEFENSE_COST_BITCOIN  && owner.cereal >= HOMMCONSTS::LEVEL3_DEFENSE_COST_CEREAL
            owner.bitcoin -= HOMMCONSTS::LEVEL3_DEFENSE_COST_BITCOIN
            owner.cereal -= HOMMCONSTS::LEVEL3_DEFENSE_COST_CEREAL
            @defense_level = 3
            @built = true
            return true
        end
        return false
    end

    def upgrade_meme_level()
        if @defense_level == 0 && try_purchase(HOMMCONSTS::LEVEL1_MEME_COST_BITCOIN,HOMMCONSTS::LEVEL1_MEME_COST_POT,0)
            @meme_level = 1
            @built = true
            return true
        elsif @meme_level == 1 && try_purchase(HOMMCONSTS::LEVEL2_MEME_COST_BITCOIN,HOMMCONSTS::LEVEL2_MEME_COST_POT,0)
            @meme_level = 2
            @built = true
            return true
        elsif @meme_level == 2 && try_purchase(HOMMCONSTS::LEVEL3_MEME_COST_BITCOIN,HOMMCONSTS::LEVEL3_MEME_COST_POT,0)
            @meme_level = 3
            @built = true
            return true
        end
        return false
    end

    def try_purchase(bitcoin : Int, pot : Int, cereal : Int)
        if @owner.nil?
            return false
        end
        owner = (@owner.as Player)
        if owner.bitcoin >= bitcoin && owner.pot >= pot && owner.cereal >= cereal
            owner.bitcoin -= bitcoin
            owner.pot -= pot
            owner.cereal -= cereal
            return true
        end
        return false
    end

    def unlock_unit_building(unit_type : Int)
        if unit_type >= 0 && unit_type < 5
            @unit_unlocks[unit_type] = true
        end
    end

    def train_unit(unit_type : Int, amount : Int)
        if unit_type >= 0 && unit_type < 5
            @units_available[unit_type] += amount
        end
    end

    # assumes that player owns city and all other checks are ok
    def build_helper(build : String)
        if build == "datacenter"
            if @bitcoin_level == 3
                return Game::CommandErrors::InvalidTarget
            elsif upgrade_bitcoin_level()
                return Game::CommandErrors::NoError
            else
                return Game::CommandErrors::InsufficientResources
            end

        elsif build == "walls"
            if @defense_level == 3
                return Game::CommandErrors::InvalidTarget
            elsif upgrade_defense_level()
                return Game::CommandErrors::NoError
            else
                return Game::CommandErrors::InsufficientResources
            end

        elsif build == "library"
            if @meme_level == 3
                return Game::CommandErrors::InvalidTarget
            elsif upgrade_meme_level()
                return Game::CommandErrors::NoError
            else
                return Game::CommandErrors::InsufficientResources
            end

        elsif build == "TODO"
            unlock_unit_building(1)
        end

        return Game::CommandErrors::InvalidTarget


    end

    def buy_helper(build : String, arg : Int)
        #elsif build == "u"
        #    city.unlock_unit_building(arg)
        #elsif build == "t"
        #    city.train_unit(arg, 1)
        #end
    end
end