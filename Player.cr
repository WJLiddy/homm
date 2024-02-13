require "./Hero"
require "./Vector2"
# class for a player
class Player
    property bitcoin : Int32
    property pot : Int32
    property cereal : Int32
    property team : Int32
    
    getter heroes : Hash(Vector2, Hero)
    def initialize(name : String, team : Int32)
        @name = name
        @bitcoin = 0
        @pot = 0
        @cereal = 0
        @team = team
        @heroes = Hash(Vector2, Hero).new
    end

    def print
        return "#{@name}: #{@bitcoin} btc | #{@pot} pot | #{@cereal} cer "
    end
end
