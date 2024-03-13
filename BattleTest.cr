require "./Battle"
require "colorize"



def printBattle(b : Battle)
    abvs = ["i","a","c","b","w"]
    b.arena.each_with_index do |row, i|
        row.each_with_index do |cell, j|
            if cell == nil
                print " "
            else
                c = cell.as(Battle::BattleUnit)
                print (c.team == 0 ? abvs[c.tier].colorize(:blue) : abvs[c.tier].colorize(:red))
            end
        end
        puts ""
    end
end
# test battle
leftHero = Hero.new(Player.new("a",false),0,0,3,2)
rightHero = Hero.new(Player.new("b",true),0,0,3,2)
battle = Battle.new(leftHero, rightHero)
100.times do 
    battle.tick()
end
printBattle(battle)