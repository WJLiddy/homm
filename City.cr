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
        @defense_level = 1
        # 1 - 3, how many memes can your hero learn?
        @meme_level = 1
        # which units can this city train?
        @unit_unlocks = [true,false,false,false,false]
        # which units are available to train?
        @units_available = [0,0,0,0,0]
        # which units are garrisoned?
        @units_garrisoned = [0,0,0,0,0]
        # who owns the city?
        @owner = nil
    end
end