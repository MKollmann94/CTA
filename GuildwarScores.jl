##########################################################################################

#### 	REQUIREMENTS

##########################################################################################

using Images
using OffsetArrays
using OCReract
using CSV
using DataFrames
using DelimitedFiles
using Suppressor

##########################################################################################

#### 	REQUIREMENTS

##########################################################################################

export getNamesAndScores, sortIntoFile, extractFolder

##########################################################################################

#### 	GLOBAL CONSTANTS

##########################################################################################

const A = 1 / 16 * [1 1 1 1 1
     		  1 0 0 0 1
     		  1 0 0 0 1
     		  1 0 0 0 1
			  1 1 1 1 1]
const kernel = OffsetArray(A, -2 : 2, -2 : 2)

##########################################################################################

#### 	COLOR FUNCTIONS

##########################################################################################

#=
	turns a blueish color into a white one and all others to a black one
=#
function blueToBinary(color)
    if color.b > 0.75 && color.r < 0.4
        return RGB(1,1,1)
    else
        return RGB(0, 0, 0)
    end
end

#=
	turns a grayish color into a white one and all others to a black one
=#
function grayToBinary(color)
	if color.r/3 + color.g/3 + color.b/3 > 0.9
		return RGB(1,1,1)
	else
		return RGB(0,0,0)
	end
end

#=
	turns a nearly white color into a black one and all others to a white one
=#
function whiteToBinary(color)
	if color.r/3 + color.g/3 + color.b/3 > 0.99
		return RGB(0,0,0)
	else
		return RGB(1,1,1)
	end
end

#=
	image convolution with the constant kernel
=#
function convolve(M, kernel)
    height, width = size(kernel)

    half_height = height ÷ 2
    half_width = width ÷ 2

    new_image = similar(M)

    # (i, j) loop over the original image
	m, n = size(M)
    @inbounds for i in 1:m
        for j in 1:n
            # (k, l) loop over the neighbouring pixels
			accumulator = 0 * M[1, 1]
			for k in -half_height:-half_height + height - 1
				for l in -half_width:-half_width + width - 1
					Mi = i - k
					Mj = j - l
					# First index into M
					if Mi < 1
						Mi = 1
					elseif Mi > m
						Mi = m
					end
					# Second index into M
					if Mj < 1
						Mj = 1
					elseif Mj > n
						Mj = n
					end

					accumulator += kernel[k, l] * M[Mi, Mj]
				end
			end

			new_image[i, j] = RGB(min(1, max(0, accumulator.r)), min(1, max(0, accumulator.g)), min(1, max(0, accumulator.b)))
        end
    end

    return new_image

end

#=
	returns the first row in which a white pixel is found
	as well as the coordinates of each row which has a neighbourhood
	of white pixels
=#
function findRow(img)
	whites = findall(x -> x == RGB(1, 1, 1), img)
	if length(whites) == 0
		return 0, []
	end
	yValues = []
	coords = []

	for i in 1 : length(whites)
		push!(yValues, whites[i][2])
	end
	min = minimum(yValues)
	firstColumn = findall(x -> x == min + 2, yValues)

	firstCoord = whites[firstColumn[1]][1]

	for j in 2 : length(firstColumn) - 1
		if whites[firstColumn[j]][1] - 5 > whites[firstColumn[j - 1]][1]
			push!(coords, (firstCoord, whites[firstColumn[j-1]][1]))
			firstCoord = whites[firstColumn[j]][1]
		end
	end
	push!(coords, (firstCoord, whites[firstColumn[end]][1]))

	#edge cases
	diff = 0
	for k in 1 : length(coords)
		diff = max(diff, coords[k][2] - coords[k][1])
	end

	newCoords = []
	for l in 1 : length(coords)
		if coords[l][2] - coords[l][1] >= diff * 7 / 10
			push!(newCoords, coords[l])
		end
	end

	return min, newCoords
end

#=
	extracts player names and their coresponding scores out of a screenshot
	also returns the image parts out of which player names and scores
	are extracted from
=#
function getNamesAndScores(img)
	img2 = blueToBinary.(img)
	img2 = convolve(img2, kernel)
	img2 = grayToBinary.(img2)
	img2 = convolve(img2, kernel)
	img2 = grayToBinary.(img2)

	min, coords = findRow(img2)
	rawNames = []
	rawScores = []
	extractedNames = []
	extractedScores = []
	cut1 = trunc(Int, size(img)[2] * 6 / 10)
	cut2 = trunc(Int, size(img)[2] * 8 / 10)


	for i in 1 : length(coords)
		height = coords[i][2] - coords[i][1]
		push!(rawNames, img[coords[i][1] : coords[i][2], min + trunc(Int, 2.25 * height) : cut1])
		push!(rawScores, img[coords[i][1] : coords[i][2], cut2 : end])
	end

	@suppress begin
		for j in 1 : length(rawNames)
			resTextName = run_tesseract(whiteToBinary.(rawNames[j]), psm = 7);
			resTextScore = run_tesseract(whiteToBinary.(rawScores[j]), psm = 7);
			push!(extractedNames, strip(resTextName))
			push!(extractedScores, strip(resTextScore))
		end
	end

	return extractedNames, extractedScores, rawNames, rawScores
end

#=
	sorts the given player names and scores into the file specified
	file is created if it doesn't already exist
	player scores are added to the same row if the player name already exists
	otherwise it is added as a new row
	new scores are added under the given column name
=#
function sortIntoFile(names, scores, file, columnName)
	try
		table = readdlm(file, '%')
	catch
		pushfirst!(names, "Players")
		pushfirst!(scores, columnName)
		writedlm(file, unique(zip(names, scores)), "%")
		return
	end
	n, m = size(table)
	oldNames = table[:, 1]
	emptyScores = fill("", (1, m - 1))
	newScores = fill("", length(oldNames) - 1)
	pushfirst!(newScores, columnName)

	for i in 1 : length(names)
		if names[i] in oldNames
			ind = findall(x -> x == names[i], oldNames)[1]
			newScores[ind] = scores[i]
		else
			push!(newScores, scores[i])
			table = [table
					 names[i] emptyScores]
			oldNames = table[:, 1]
		end
	end
	table = [table newScores]
	writedlm(file, table, "%")
end


#=
	returns player names and scores of all screenshots in a folder
=#
function extractFolder(path)
	extNames = []
	extScores = []
	for i in readdir(path)
		img = load(path * "\\" * i)
		tempNames, tempScores = getNamesAndScores(img)
		extNames = vcat(extNames, tempNames)
		extScores = vcat(extScores, tempScores)
	end
	return extNames, extScores
end
