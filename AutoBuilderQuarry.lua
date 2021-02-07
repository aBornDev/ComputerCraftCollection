-- in between time to stop program
local time1 = {["hours"]=07, ["minutes"]=30}
local time2 = {["hours"]=08, ["minutes"]=00}


function checkStats()
    if turtle.getFuelLevel() < 1000 then
        refuel()
    end
end
 
function refuel()
    print( "Refueling..." )
 	reverse()
    turtle.select(1)
    turtle.place()
    turtle.suck(64)
    turtle.refuel(64)
    turtle.dig()
    reverse()
end

function reverse()
    turn( "r" )
    turn( "r" )
end
 
function turn( direction )
    if direction == "r" then
        turtle.turnRight()
 
        return true
    elseif direction == "l" then
        turtle.turnLeft()
 
        return true
    else
        return false
    end
end

function forward(count)
  	local default = 1
  	count = count or (count == nil and default)

	for i=1,count do
        turtle.forward()
    end
end

function up(count)
  	local default = 1
  	count = count or (count == nil and default)

	for i=1,count do
        turtle.up()
    end
end

function down(count)
  	local default = 1
  	count = count or (count == nil and default)

	for i=1,count do
        turtle.down()
    end
end


local function getMinutes(hours,minutes) 
    return (hours*60)+minutes
end

function timeBetween(time1,time2)
	local value1 = getMinutes(time1.hours,time1.minutes)
	local value2 = getMinutes(time2.hours,time2.minutes)
	local currentHour = tonumber(os.date("%H"))
	local currentMinute = tonumber(os.date("%M"))
	local currentTime = getMinutes(currentHour,currentMinute)

	local isBetween = false

	if (currentTime >= value1 and currentTime <= value2) or (currentTime >= value2 and currentTime <= value1) then
	    isBetween = true
	end
	return isBetween
end

function builderPickUp()
	checkStats()
	print("Picking up the builder for transport at", os.date("%H:%M"))
	turtle.select(2)
	turtle.dig()
	turtle.digDown()
	down(1)
	turtle.dig()
	turtle.forward()
	turtle.dig()
	turn("l")
	turtle.dig()
	reverse()
	turtle.dig()
	turtle.digDown()
	down(1)
	turtle.dig()
	turn("l")
	turtle.dig()
	turn("l")
	turtle.dig()
	turn("r")
	print("The builder has been picked up for transport at ", os.date("%H:%M"))
	moveChunk()
	
end

-- TODO: Refactor to use helper function
function builderBuild()
	checkStats()
	print("Initiating the build of the builder at ", os.date("%H:%M"))
	turtle.select(5)
	turn("l")
	turtle.place()
	turn("r")
	turtle.place()
	turn("r")
	turtle.place()
	up(1)
	turtle.place()
	turn("l")
	turtle.place()
	turn("l")
	turtle.place()
	turtle.select(6)
	turtle.placeDown()
	turn("r")
	turtle.select(2)
	turtle.placeUp()
	turtle.back()
	turtle.select(4)
	turtle.place()
	up(1)
	turtle.select(3)
	turtle.placeDown()
	turtle.select(15)
	turtle.placeUp()
	print("Finished the build of the builder at ", os.date("%H:%M"))

	collectChunkLoader()
end

function moveChunk()
	checkStats()
    forward(8)
    turtle.select(16)
    turtle.placeUp()
    reverse()
	forward(9)
    up(2)
    turtle.select(16)
    turtle.digUp()
    reverse()
	down(2)
	forward(9)
    down(1)
    turtle.select(16)
    turtle.place()
    up(1)
    turtle.forward()
    up(1)
    reverse()
    turtle.select(15)
    turtle.dig()
    reverse()
    down(1)
    forward(7)
    builderBuild()
end

function collectChunkLoader()
	checkStats()
	reverse()
	forward(6)
	down(2)
	turtle.select(16)
	turtle.digDown()
	up(2)
	reverse()
	forward(6)
	runningCheck()
end

-- function to check if builder is still mining
function runningCheck()
	checkStats()
	local chest
	local emptyTime = 0
	if(peripheral.isPresent("front")) then
		chest = peripheral.wrap("front")
		print("starting the Quarrying check of the builder", os.date("%H:%M"))
		
		while emptyTime <= 60 do
			if timeBetween(time1,time2) then
				print("time is between", time1.hours, ":", time1.minutes, "and ", time2.hours, ":", time2.minutes)
				error()
			end

			if chest.getItemDetail(1) == nil then
				emptyTime = emptyTime + 1
			else
				emptyTime = 0
			end
			sleep(1)
		end
		print("Quarrying Finished at ", os.date("%H:%M"))
		builderPickUp()

	else
		print("Error: Something isn't in the right place, Will now terminate. ", os.date("%H:%M"))
		error()
	end

	
end

function main( task )
	--[[
	if task == "build" then
		builderBuild()
	elseif task == "pickup" then
		builderPickUp()

	elseif task == "check" then
		runningCheck()

	elseif task == "movechunk" then
		moveChunk()
	elseif task == "collect" then
		collectChunkLoader()
	else
		print("413: instructions unclear. I'm a teapot")
	end
]]--
	runningCheck()
end

--[[
write( "What should I do with the builder? pickup, build, movechunk or check : \n" )
task = read()
task = task:lower()
]]--

main(task)
