local check = false;

function checkStats()
    if turtle.getFuelLevel() < 1000 then
        refuel()
    end
end
 
function refuel()
    log( "Refueling..." )
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

function log(text)
	local default = "no message"
	append = text or (text == nil and default)
	msg = "turtle(" .. os.getComputerID() .. "): ".. append
	print(msg)
	if(peripheral.isPresent("top")) then
		chat = peripheral.wrap("top")
		chat.sendMessage(msg)
	end
end

function minerPickUp()
	sleep(1)
	checkStats()
	log("Picking up the builder for transport at" .. os.date("%H:%M"))
	turtle.select(6) -- chat box
	turtle.digUp()
	turtle.select(2) -- miner
	turtle.digDown()
	down(1)
	reverse()
	forward(1)
	turtle.select(5) -- loot ender chest
	turtle.dig()
	down(1)
	turtle.select(4) -- teleporter
	turtle.digDown()
	down(1)
	reverse()
	turtle.select(3) -- Quantum entangloporter
	turtle.dig()
	forward(1)
	log("The builder has been picked up for transport at " .. os.date("%H:%M"))
	moveChunk()
end

function moveChunk()
	forward(64)
	minerBuild()
end


-- TODO: Refactor to use helper function
function minerBuild()
	checkStats()
	log("Initiating the build of the miner at " .. os.date("%H:%M"))
	reverse()
	turtle.select(2) -- miner
	turtle.placeUp()
	reverse()
	down(1)
	turtle.select(3) -- Quantum entangloporter
	turtle.placeUp()
	reverse()
	forward(1)
	turtle.select(4) -- teleporter
	turtle.placeUp()
	forward(1)
	up(4)
	turtle.select(5)
	turtle.placeDown()
	reverse()
	forward(2)
	turtle.select(6)
	turtle.placeUp()
	log("Finished the build of the builder at " .. os.date("%H:%M"))
	
	runningCheck()
end

function runningCheck()
	checkStats()
	local miner
	
	if(peripheral.isPresent("bottom")) then
		miner = peripheral.wrap("bottom")
		if(not check) then
			log("starting the Quarrying check of the miner " .. os.date("%H:%M"))
			check = true;
			runningCheck();
		end
		
		if miner.getEnergyUsage() == 0 then
			if miner.getState() == "IDLE" then
				miner.start()
			else
				log("Quarrying Finished at " .. os.date("%H:%M"))
				check = false;
				minerPickUp()
			end
		end

		sleep(60)
		runningCheck()
	else
		turtle.select(6) -- chat box
		turtle.placeUp()
		log("Error: Something isn't in the right place, Will now try to place teleporter and terminate. " .. os.date("%H:%M"))
		turtle.select(4) -- teleporter
		turtle.place()
		turtle.placeUp()
		turtle.placeDown()
		error()
	end	
end

function main( task )
	if task == "build" then
		minerBuild()
	elseif task == "pickup" then
		minerPickUp()

	elseif task == "check" then
		runningCheck()
	else
		log("413: instructions unclear. I'm a teapot")
	end
	runningCheck()
end

-- write( "What should I do with the builder? pickup, build, or check : \n" )
-- task = read()
-- task = task:lower()


main(task)