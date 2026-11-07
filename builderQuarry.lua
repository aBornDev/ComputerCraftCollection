--- Builder quarry: builds a builder setup, waits until it is done, breaks it down,
-- moves one chunk and starts over.
--
-- Usage: builderQuarry <task>
--   auto      run the full cycle forever (check -> pickup -> movechunk -> build -> collect)
--   build     build the setup once
--   pickup    break the setup down once
--   check     wait until the builder is done
--   movechunk move the chunk loaders and the turtle one chunk
--   collect   pick up the chunk loader after building
-- Without a task the program asks for one.

local utils = require("lib.turtleUtils")
local log, turn, reverse = utils.log, utils.turn, utils.reverse
local forward, up, down, back = utils.forward, utils.up, utils.down, utils.back

local args = { ... }

-- Between these (real world) server times the program stops, e.g. for a server restart.
local STOP_WINDOW = {
    from = { hours = 7, minutes = 30 },
    to   = { hours = 8, minutes = 0 },
}
-- Seconds the output chest has to stay empty before the builder counts as done.
local EMPTY_TIMEOUT = 60

local SLOT = {
    fuel         = 1,  -- container with fuel
    builder      = 2,  -- builder (placed up); pickup also starts digging into this slot
    part3        = 3,  -- placed down on top of the setup
    part4        = 4,  -- placed in front, behind the builder
    frame        = 5,  -- 6 blocks around the turtle
    part6        = 6,  -- placed below the turtle
    chunkLoader2 = 15,
    chunkLoader1 = 16,
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
    log("Picking up the builder for transport at " .. utils.time())
    turtle.select(SLOT.builder)
    turtle.dig()
    turtle.digDown()
    down(1)
    turtle.dig()
    forward(1)
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
    log("The builder has been picked up for transport at " .. utils.time())
end

local function build()
    checkStats()
    log("Initiating the build of the builder at " .. utils.time())
    turtle.select(SLOT.frame)
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
    turtle.select(SLOT.part6)
    turtle.placeDown()
    turn("r")
    turtle.select(SLOT.builder)
    turtle.placeUp()
    back(1)
    turtle.select(SLOT.part4)
    turtle.place()
    up(1)
    turtle.select(SLOT.part3)
    turtle.placeDown()
    turtle.select(SLOT.chunkLoader2)
    turtle.placeUp()
    log("Finished the build of the builder at " .. utils.time())
end

local function moveChunk()
    checkStats()
    forward(8)
    turtle.select(SLOT.chunkLoader1)
    turtle.placeUp()
    reverse()
    forward(9)
    up(2)
    turtle.select(SLOT.chunkLoader1)
    turtle.digUp()
    reverse()
    down(2)
    forward(9)
    down(1)
    turtle.select(SLOT.chunkLoader1)
    turtle.place()
    up(1)
    forward(1)
    up(1)
    reverse()
    turtle.select(SLOT.chunkLoader2)
    turtle.dig()
    reverse()
    down(1)
    forward(7)
end

local function collectChunkLoader()
    checkStats()
    reverse()
    forward(6)
    down(2)
    turtle.select(SLOT.chunkLoader1)
    turtle.digDown()
    up(2)
    reverse()
    forward(6)
end

--- Waits until the chest in front of the turtle stays empty for EMPTY_TIMEOUT seconds.
-- @return true when the builder is done, false when the stop window was reached.
local function waitUntilFinished()
    checkStats()
    if not peripheral.isPresent("front") then
        error("Something isn't in the right place (no chest in front), terminating at " .. utils.time(), 0)
    end

    local chest = peripheral.wrap("front")
    log("Starting the quarrying check of the builder at " .. utils.time())

    local emptySeconds = 0
    while emptySeconds <= EMPTY_TIMEOUT do
        if utils.isTimeBetween(STOP_WINDOW.from, STOP_WINDOW.to) then
            log(("Time is between %02d:%02d and %02d:%02d, stopping."):format(
                STOP_WINDOW.from.hours, STOP_WINDOW.from.minutes,
                STOP_WINDOW.to.hours, STOP_WINDOW.to.minutes))
            return false
        end

        if chest.getItemDetail(1) == nil then
            emptySeconds = emptySeconds + 1
        else
            emptySeconds = 0
        end
        sleep(1)
    end

    log("Quarrying finished at " .. utils.time())
    return true
end

local function autoLoop()
    while waitUntilFinished() do
        pickUp()
        moveChunk()
        build()
        collectChunkLoader()
    end
end

local TASKS = {
    auto = autoLoop,
    build = build,
    pickup = pickUp,
    check = waitUntilFinished,
    movechunk = moveChunk,
    collect = collectChunkLoader,
}

local task = args[1]
if not task then
    write("What should I do with the builder? auto, build, pickup, check, movechunk or collect: ")
    task = read()
end

local run = TASKS[task:lower()]
if not run then
    print("Unknown task '" .. task .. "'. Use: auto, build, pickup, check, movechunk or collect")
    return
end
run()
