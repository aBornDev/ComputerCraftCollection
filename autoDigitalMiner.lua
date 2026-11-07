--- Digital miner: builds a Mekanism digital miner setup, waits until it is done,
-- breaks it down, moves one chunk (64 blocks) and starts over.
--
-- Usage: autoDigitalMiner [check|build|pickup]   (default: check)

local utils = require("lib.turtleUtils")
local log, reverse = utils.log, utils.reverse
local forward, up, down = utils.forward, utils.up, utils.down

local args = { ... }

-- Seconds between two checks of the miner.
local CHECK_INTERVAL = 60
-- Distance (in blocks) to the next mining location.
local MOVE_DISTANCE = 64

local SLOT = {
    fuel           = 1,  -- container with fuel
    miner          = 2,  -- digital miner
    entangloporter = 3,  -- quantum entangloporter
    teleporter     = 4,
    lootChest      = 5,  -- ender chest for the loot
    chatBox        = 6,
}

local function checkStats()
    if utils.needsFuel() then
        log("Refueling...")
        reverse()
        utils.refuelFromChest(SLOT.fuel, "front")
        reverse()
    end
end

local function pickUp()
    checkStats()
    log("Picking up the miner for transport at " .. utils.time())
    turtle.select(SLOT.chatBox)
    turtle.digUp()
    turtle.select(SLOT.miner)
    turtle.digDown()
    down(1)
    reverse()
    forward(1)
    turtle.select(SLOT.lootChest)
    turtle.dig()
    down(1)
    turtle.select(SLOT.teleporter)
    turtle.digDown()
    down(1)
    reverse()
    turtle.select(SLOT.entangloporter)
    turtle.dig()
    forward(1)
    log("The miner has been picked up for transport at " .. utils.time())
end

local function moveChunk()
    forward(MOVE_DISTANCE)
end

local function build()
    checkStats()
    log("Initiating the build of the miner at " .. utils.time())
    reverse()
    turtle.select(SLOT.miner)
    turtle.placeUp()
    reverse()
    down(1)
    turtle.select(SLOT.entangloporter)
    turtle.placeUp()
    reverse()
    forward(1)
    turtle.select(SLOT.teleporter)
    turtle.placeUp()
    forward(1)
    up(4)
    turtle.select(SLOT.lootChest)
    turtle.placeDown()
    reverse()
    forward(2)
    turtle.select(SLOT.chatBox)
    turtle.placeUp()
    sleep(1)
    log("Finished the build of the miner at " .. utils.time())
end

--- Places a teleporter so the turtle can be reached, then stops the program.
local function failSafe()
    turtle.select(SLOT.chatBox)
    turtle.placeUp()
    log("Error 404: Miner not found, will now try to place a teleporter and terminate. " .. utils.time())
    turtle.select(SLOT.teleporter)
    turtle.place()
    turtle.placeUp()
    turtle.placeDown()
    error("Miner not found", 0)
end

--- Keeps the miner running and returns when it has finished.
local function waitUntilFinished()
    checkStats()
    if not peripheral.isPresent("bottom") then
        failSafe()
    end

    local miner = peripheral.wrap("bottom")
    log("Starting the quarrying check of the miner at " .. utils.time())

    while true do
        if miner.getEnergyUsage() == 0 then
            if miner.getState() == "IDLE" then
                miner.start()
            else
                log("Quarrying finished at " .. utils.time())
                return
            end
        end
        sleep(CHECK_INTERVAL)
    end
end

local task = (args[1] or "check"):lower()

if task == "build" then
    build()
elseif task == "pickup" then
    pickUp()
    moveChunk()
    build()
elseif task ~= "check" then
    log("413: instructions unclear. I'm a teapot. Use: check, build or pickup")
    return
end

while true do
    waitUntilFinished()
    pickUp()
    moveChunk()
    build()
end
