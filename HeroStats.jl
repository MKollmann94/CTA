##########################################################################################

#### 	REQUIREMENTS

##########################################################################################

using CSV
using DataFrames
using Formatting

##########################################################################################

#### 	EXPORTS

##########################################################################################

export getStats

##########################################################################################

#### 	GLOBAL CONSTANTS

##########################################################################################

const SSHEETPATH = "baseStats.csv"

#=
    returns the base stats of a given hero
=#
function getBaseStats(hero)
    dfStats = CSV.read(string(@__DIR__, "\\", SSHEETPATH), delim = ";", DataFrame)
    HeroNames = dfStats.Name

    #remove whitespaces from column names
    DataFrames.rename!(dfStats, Symbol.(replace.(string.(DataFrames.names(dfStats)), Ref(r"\s"=>""))))
    ind = findall(x -> x == hero, HeroNames)[1]
    return dfStats[ind, :]
end


#=
    returns the total stats of a given hero, taking into account
    stars, awakens and buffs from runes, teambuffs or seasons
=#
function getStats(hero, stars, awakens; hp = 0, tbHP = 0, shield = 0, tbShield = 0, atk = 0, tbAtk = 0, range = 0, totalbuff = 0)
    dfBaseStats = getBaseStats(hero)

    heroHp = (dfBaseStats.Hp * (2 ^ (stars - 1)) * (1.5 ^ awakens) * (((hp + 90 + 0.2 * tbHP) * 10) + 100) / 100) * (1 + totalbuff / 100)
    heroShield = 0.2 * heroHp * ((shield + 0.2 * tbShield + 100) / 100)
    heroAtk = (dfBaseStats.Atk * (2 ^ (stars - 1)) * (1.5 ^ awakens) * (atk + 0.2 * tbAtk + 100) / 100) * (1 + totalbuff / 100)
    heroRange = dfBaseStats.AtkRange * (1 + range / 100)

    println("Hero: $hero")
    println("HP: ", sprintf1("%'d", heroHp))
    if shield != 0
        println("Shield: ", sprintf1("%'d", heroShield))
        println("Total HP: ", sprintf1("%'d", (heroHp + heroShield)))
    end
    println("Atk: ", sprintf1("%'d", heroAtk))
    println("Atk range: $heroRange")
end
