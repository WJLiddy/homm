# class for a player
class Player
    getter heroes : Hash(Vector2, Hero)
    def initialize(name : String)
        @name = name
        @bitcoin = 0
        @pot = 0
        @cereal = 0
        @heroes = Hash(Vector2, Hero).new
    end

    def print
        return "#{@name}: #{@bitcoin} b | #{@pot} p | #{@cereal} | c #{@heroes.count} h"
    end
end
