local tArgs = { ... }
local SIDES = {"front", "left", "back", "right", "top", "bottom"}
local listenChannel = 1
local buttons = {}

function isSide(side)
	for i=1,6 do
		if side == SIDES[i] then
			return true
		end
	end
	return false
end

function findPeripherals()
	local foundPeripherals = {}
	for i=1,6 do
		if peripheral.isPresent(SIDES[i]) == true then
			local peripheralType = peripheral.getType(SIDES[i])
			foundPeripherals[peripheralType] = {side = SIDES[i]}

			if peripheralType == "modem" then
				modemSetup(foundPeripherals)
			elseif peripheralType == "monitor" then
				monitorSetup(foundPeripherals)
			end
		end
	end
	return foundPeripherals
end

function modemSetup(foundPeripherals)
	print("Modem is setting up...")
	modem = peripheral.wrap(foundPeripherals.modem.side)
	modem.open(listenChannel)  -- Open channel 3 so that we can listen on it
	print("Modem is on the "..foundPeripherals.modem.side.." side of the computer...")
end

function monitorSetup(foundPeripherals)
	print("Monitor is setting up...")
	monitor = peripheral.wrap(foundPeripherals.monitor.side)
	print("Monitor is on the "..foundPeripherals.monitor.side.." side of the computer...")
	monitor.setBackgroundColor(colors["black"])
	monitor.clear()
end

function buttonAdd(tag, xPos, yPos, widthPar, clr)
	if widthPar < 1 then
		local width = string.len(tag)
	else
		local width  = widthPar
	end

	table.insert(buttons, {tag = tag, xPos = xPos, yPos = yPos, width = widthPar, color = clr, func = buttonsFunctionSet(tag), active = false})
end

function buttonsDraw()
	local n = 1;

	while buttons[n] ~= nil do
		monitor.setBackgroundColor(colors[buttons[n].color])

		monitor.setCursorPos(buttons[n].xPos, buttons[n].yPos-1)
		for i=1,buttons[n].width do
			monitor.write(" ")
		end

		monitor.setCursorPos(buttons[n].xPos, buttons[n].yPos+1)
		for i=1,buttons[n].width do
			monitor.write(" ")
		end

		monitor.setCursorPos(buttons[n].xPos, buttons[n].yPos)
		monitor.setTextColor(colors["white"])

		local restLength = (buttons[n].width - string.len(buttons[n].tag))/2

		if (buttons[n].width - string.len(buttons[n].tag)) % 2 ~= 1 then
			for i=1,restLength do
				monitor.write(" ")
			end
		else
			for i=1,(restLength+1) do
				monitor.write(" ")
			end
		end

		monitor.write(buttons[n].tag)

		for i=1,restLength do
			monitor.write(" ")
		end

		n = n+1
	end
end

function buttonsSet()
	buttonAdd("spawner", 3, 3, 15, "green")
end

function buttonFind(tag)
	for i=1,#buttons do
		if buttons[i].tag == tag then
			return i
		end
	end
end

function buttonsFunctionSet(tag)
	if tag == "spawner" then
		local spawner
		function spawner(active)
			if active==false then
				modem.transmit(3, 1, "on")
				buttons[buttonFind(tag)].active = true
				buttons[buttonFind(tag)].color = "red"
			else
				modem.transmit(3, 1, "off")
				buttons[buttonFind(tag)].active = false
				buttons[buttonFind(tag)].color = "green"
			end
		end

		return spawner
	end
end

function manageActions()
	while true do
		event, side, xPos, yPos = os.pullEvent("monitor_touch")

		local n = 1
		local found = false

		for i=1,#buttons do
			if xPos >= buttons[n].xPos and xPos <= (buttons[n].xPos + buttons[n].width) then
				if yPos >= (buttons[n].yPos-1) and yPos <= (buttons[n].yPos+1) then
					print("Button pressed at: x="..xPos.." y="..yPos)
					buttons[n].func(buttons[n].active)
					break
				end
			end
		end

		buttonsDraw()
	end
end

-- os.sleep(10)

local foundPeripherals = findPeripherals()

buttonsSet()
buttonsDraw()

manageActions()

read()
