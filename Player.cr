require "./Hero"
require "./Vector2"
require "json"
# class for a player
class Player
    include JSON::Serializable
    
    property bitcoin : Int32
    property pot : Int32
    property cereal : Int32
    property team : Bool
    @[JSON::Field(ignore:true)]
    getter heroes : Hash(Vector2, Hero)
    property name : String
    property ended_turn : Bool
    
    def initialize(name : String, team : Bool)
        @name = name
        @bitcoin = 0
        @pot = 0
        @cereal = 0
        @team = team
        @heroes = Hash(Vector2, Hero).new
        @ended_turn = team
    end

    def print
        return "#{@name}: #{@bitcoin} btc | #{@pot} pot | #{@cereal} cer "
    end
end
