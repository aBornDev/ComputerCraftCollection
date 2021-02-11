local tArgs = { ... }
local input
local target

write( "Length: " )
input = read()
local length = tonumber(input)
if (type(length) ~= "number") or (length <= 1) then
	print( "Error 400: length must be a number above 1" )
	return
end

write( "Width: " )
input = read()
local width = tonumber(input)
if (type(width) ~= "number") or (width <= 1) then
	print( "Error 400: width must be a number above 1" )
	return
end

write( "Depth/Hight: " )
input = read()
local depth = tonumber(input)
if (type(depth) ~= "number") or (depth < 0) then
	print( "Error 400: depth must be a number above 0" )
	return
end

write( "Direction: " )
local nextTurn = read()
if type(nextTurn) ~= "string" then
	print( "Error 400: direction must be a string" )
	return
end
if (nextTurn == "r") or (nextTurn == "R") or (nextTurn == "right") or (nextTurn == "Right") then
	nextTurn = "r"
elseif (nextTurn == "l") or (nextTurn == "L") or (nextTurn == "left") or (nextTurn == "Left") then
	nextTurn = "l"
else
	print( "Error 400: direction must be derived from left or right" )
	return
end

write( "Should the turtle mine up or down?: " )
local vDirection = read()
if (vDirection == "u") or (vDirection == "up") or (vDirection == "Up") then
	vDirection = "u"
	depth = depth-(depth*2)
	target = depth+1
	print( "target= "..target )
elseif (vDirection == "d") or (vDirection == "down") or (vDirection == "Down") then
	vDirection = "d"
	target = depth-1
	print( "target= "..target )
else
	print( "Error 400: vertical direction must be derived from up or down" )
	return
end

print( "Make sure slot 1 contains a container with fuel" )
print( "Make sute slot 2 contains an enderchest to receive items" )
print( "_______________________________________" )
write( "Press Enter to continue" )
read( " " )

local unloaded = 0
local collected = 0

local xPos,zPos,yPos = 0,0,0
local facing = 1 -- This is relative direction from the start of the programm 1: north, 2: east, 3: south, 4: west
local xDir,zDir = 0,1

local endOfRun = false
local last = false

function dumpItems()
	print( "Sending items home..." )

	turtle.select(2)
	if vDirection == "d" then
		if not turtle.placeUp() then
			turtle.digUp()
			turtle.placeUp()
		end
	elseif vDirection == "u" then
		if not turtle.placeDown() then
			turtle.digDown()
			turtle.placeDown()
		end
	end

	for n=3,16 do
		local itemCount = turtle.getItemCount(n)
		if itemCount > 0 then
			turtle.select(n)
			if vDirection == "d" then
				turtle.dropUp()
			elseif vDirection == "u" then
				turtle.dropDown()
			end
			unloaded = unloaded + itemCount
		end
	end

	turtle.select(2)
	if vDirection == "d" then
		turtle.digUp()
	elseif vDirection == "u" then
		turtle.digDown()
	end
end

function refuel()
	print( "Refueling..." )

	turtle.select(1)
	if vDirection == "d" then
		if not turtle.placeUp() then
			turtle.digUp()
			turtle.placeUp()
		end
		turtle.suckUp(64)
		turtle.refuel(64)
		turtle.digUp()
	elseif vDirection == "u" then
		if not turtle.placeDown() then
			turtle.digDown()
			turtle.placeDown()
		end
		turtle.suckDown(64)
		turtle.refuel(64)
		turtle.digDown()
	end
end

function checkStats()
	if turtle.getItemCount(15) > 0 then
		dumpItems()
	end

	if turtle.getFuelLevel() < 1000 then
		refuel()
	end
end

function down()
	if not turtle.down() then
		turtle.digDown()
		if not turtle.down() then
			last = true
			return
		end
	end

	yPos = yPos + 1

	return true
end

function forward()
	while turtle.detect() do
		turtle.dig()
	end
	turtle.forward()

	checkStats()

	xPos = xPos + xDir
	zPos = zPos + zDir

	return true
end

function up()
	while turtle.detectUp() do
		turtle.digUp()
	end

	turtle.up()

	yPos = yPos - 1

	return true
end

function turn( direction )
	if direction == "r" then
		turtle.turnRight()
		if facing == 4 then
			facing = 1
		else 
			facing = facing + 1
		end
		setDir()

		return true
	elseif direction == "l" then
		turtle.turnLeft()
		if facing == 1 then
			facing = 4
		else 
			facing = facing - 1
		end
		setDir()

		return true
	else
		return false
	end
end

function setFacing( looking )
	while facing ~= looking do
		turn( "r" )
	end
end

function setDir()
	if facing == 1 then
		xDir = 0
		zDir = 1
	elseif facing == 2 then
		xDir = 1
		zDir = 0
	elseif facing == 3 then
		xDir = 0
		zDir = -1
	elseif facing == 4 then
		xDir = -1
		zDir = 0
	end
end

function translateFacing()
	if facing == 1 then
		return "North"
	elseif facing == 2 then
		return "East"
	elseif facing == 3 then
		return "South"
	elseif facing == 4 then
		return "West"
	end
end

function reverse()
	turn( "r" )
	turn( "r" )
end

function digUpDown()
	if turtle.detectUp() then
		turtle.digUp()
	end

	if turtle.detectDown() then
		turtle.digDown()
	end
end

function zigzag()
	for n=1,width do
		for m=1,length-1 do
			forward()
			digUpDown()
		end

		if n < width then
			turn(nextTurn)
			forward()
			digUpDown()
			turn(nextTurn)

			if nextTurn == "r" then
				nextTurn = "l"
			elseif nextTurn == "l" then
				nextTurn = "r"
			end
		end
	end
end

function goTo( x,y,z )
	print( "Moving to x: "..x..", y: "..y..", z: "..z.."..." )
	while yPos > y do
		up()
	end

	while yPos < y do
		down()
	end

	if xPos > x then
		setFacing(4)
		while xPos > x do
			forward()
		end
	elseif xPos < x then
		setFacing(2)
		while xPos < x do
			forward()
		end
	end

	if zPos > z then
		setFacing(3)
		while zPos > z do
			forward()
		end
	elseif zPos < z then
		setFacing(1)
		while zPos < z do
			forward()
		end
	end
end

function home() -- returns the turtle to 0,0,0
	print( "Returning home..." )
	print( "Current Coordinates: x="..xPos..", y="..yPos..", z="..zPos )
	print( "Turtle is facing "..translateFacing() )

	goTo( 0,0,-1 )
	setFacing(1)
end

checkStats()
digUpDown()

while not endOfRun do
	zigzag()

	if last == false then
		reverse()
		print( "Moving to the next layer..." )
		for i=1,3 do
			if (yPos == target) and (depth ~= 0) then
				print( "I hit my target!" )
				last = true
				break
			end
			if vDirection == "d" then
				down()
			elseif vDirection == "u" then
				up()
			end
		end
		digUpDown()
	else 
		print( "This is my last run..." )
		endOfRun = true
	end
end

home()

dumpItems()

print( "In total "..unloaded.." items were mined..." )
