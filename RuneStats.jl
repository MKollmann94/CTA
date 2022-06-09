using CSV
using DataFrames

export getRuneStats

#absolut path to primaryRuneStats.csv
const SPRIMARYRUNESPATH = "primaryRuneStats.csv"
#absolute path to secondaryRuneStats.csv
const SSECONDARYRUNESPATH = "secondaryRuneStats.csv"


function getRuneStats(primaryName, stars, level, first = "", second = "", third = "", fourth = "")
    dfPrimaryStats = dfStats = CSV.read(string(@__DIR__, "\\", SPRIMARYRUNESPATH), delim = ";", DataFrame)
    dfSecondaryStats = dfStats = CSV.read(string(@__DIR__, "\\", SSECONDARYRUNESPATH), delim = ";", DataFrame)

    primaryNames = dfPrimaryStats.Stat
    primaryStats = dfPrimaryStats.BaseValue

    secondaryNames = dfSecondaryStats.Stat
    secondaryStats = dfSecondaryStats.BaseValue

    if primaryName in primaryNames
        ind = findall(x -> x == primaryName, primaryNames)[1]
        basePrimary = primaryStats[ind]
    else
        println("Valid primary stats are:")
        for i in 1 : size(primaryNames)[1] - 1
            print("$(primaryNames[i]), ")
        end
        println(primaryNames[end])
        error("Primary stat not found, please check for spelling errors!")
    end

    secondaries = [first, second, third, fourth]
    baseSecondary = []
    secondaryValues = []
    typo = false

    for secInd in 1 : size(secondaries)[1]
        if secondaries[secInd] != ""
            if secondaries[secInd] in secondaryNames
                ind = findall(x -> x == secondaries[secInd], secondaryNames)[1]
                push!(baseSecondary, secondaryStats[ind])
            else
                secondaries[secInd] = ""
                push!(baseSecondary, 0)
                typo = true
            end
        end
    end

    maxLevel = stars * 5

    if level > maxLevel
        error("Level of a $stars stars rune can't be higher than $(maxLevel)!")
    end

    primaryStat = basePrimary * stars * (1 + (level - 1) // (maxLevel - 1))
    primaryStat = round(primaryStat, digits = 1)

    for value in baseSecondary
        stat = value * stars * (1+ (level - 1) // (maxLevel - 1))
        push!(secondaryValues, stat)
    end

    secondaryValues = round.(getSecondaryStats(secondaryValues, stars, level), digits = 1)

    println("$stars stars, level $level")
    println("$primaryName: $primaryStat%")
    for (secondary, value) in zip(secondaries, secondaryValues)
        if secondary != ""
            println("$secondary: $value%")
        end
    end
    if typo
        println("Valid secondary stats are:")
        for i in 1 : size(secondaryNames)[1] - 1
            print("$(secondaryNames[i]), ")
        end
        println(secondaryNames[end])
    end
end


function doubleFirstnElements!(arrayToDouble, n)
    n = min(size(arrayToDouble)[1], n)
    for ind in 1 : n
        arrayToDouble[ind] += arrayToDouble[ind]
    end
end


function getSecondaryStats(values, stars, level)
    if stars == 6
        if level >= 25
            #double all 4 secondaries
            doubleFirstnElements!(values, 4)
        elseif level >= 20
            #double first 3 secondaries
            doubleFirstnElement!(values, 3)
        elseif level >= 15
            #double first 2 secondaries
            doubleFirstnElements!(values, 2)
        elseif level >= 10
            #double first secondary
            doubleFirstnElements!(values, 1)
        end
    else
        if level >= 25
            #double first 3 secondaries
            doubleFirstnElements!(values, 3)
        elseif level >= 20
            #double first 2 secondaries
            doubleFirstnElements!(values, 2)
        elseif level >= 15 && stars > 3
            #double first secondary
            doubleFirstnElements!(values, 1)
        end
    end
    return values
end
