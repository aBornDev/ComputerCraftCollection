--- Digs a rectangular hole (length x width x depth), three layers per pass.
--
-- Usage: betterExcavate [length] [width] [depth] [l|r] [u|d]
-- Missing arguments are asked for.
-- Slot 1: container with fuel, slot 2: ender chest that receives the items.

local utils = require("lib.turtleUtils")

local args = { ... }

local SLOT = { fuel = 1, enderChest = 2, firstLoot = 3, lastLoot = 16 }
-- Items are sent away as soon as this slot is in use.
local DUMP_SLOT = 15

local TURN_INPUT = { r = "r", right = "r", l = "l", left = "l" }
local VERTICAL_INPUT = { u = "u", up = "u", d = "d", down = "d" }

---------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------

local function ask(index, prompt)
    if args[index] then
        return args[index]
    end
    write(prompt .. ": ")
    return read()
end

local length = tonumber(ask(1, "Length"))
if not length or length <= 1 then
    print("Error 400: length must be a number above 1")
    return
end

local width = tonumber(ask(2, "Width"))
if not width or width <= 1 then
    print("Error 400: width must be a number above 1")
    return
end

local depth = tonumber(ask(3, "Depth/Height"))
if not depth or depth < 0 then
    print("Error 400: depth must be a number of 0 or more")
    return
end

local nextTurn = TURN_INPUT[ask(4, "Direction (l/r)"):lower()]
if not nextTurn then
    print("Error 400: direction must be left or right")
    return
end

local vDirection = VERTICAL_INPUT[ask(5, "Should the turtle mine up or down? (u/d)"):lower()]
if not vDirection then
    print("Error 400: vertical direction must be up or down")
    return
end

local target
if vDirection == "u" then
    depth = -depth
    target = depth + 1
else
    target = depth - 1
end
print("target = " .. target)

if #args < 5 then
    print("Make sure slot 1 contains a container with fuel")
    print("Make sure slot 2 contains an ender chest to receive items")
    print("_______________________________________")
    write("Press Enter to continue")
    read()
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

-- The chest side is the side the turtle came from (above when mining down).
local chestSide = vDirection == "d" and "up" or "down"

local unloaded = 0

-- Position relative to the start; y grows downwards.
local pos = { x = 0, y = 0, z = 0 }
-- Relative facing from the start: 1 north, 2 east, 3 south, 4 west.
local facing = 1
local FACING = {
    { name = "North", dx = 0,  dz = 1 },
    { name = "East",  dx = 1,  dz = 0 },
    { name = "South", dx = 0,  dz = -1 },
    { name = "West",  dx = -1, dz = 0 },
}

local endOfRun = false
local last = false

---------------------------------------------------------------------------
-- Inventory
---------------------------------------------------------------------------

local function dumpItems()
    print("Sending items home...")

    turtle.select(SLOT.enderChest)
    if not utils.place(chestSide, true) then
        print("Warning: could not place the ender chest")
        return
    end

    for n = SLOT.firstLoot, SLOT.lastLoot do
        local before = turtle.getItemCount(n)
        if before > 0 then
            turtle.select(n)
            utils.drop(chestSide)
            unloaded = unloaded + before - turtle.getItemCount(n)
        end
    end

    turtle.select(SLOT.enderChest)
    utils.dig(chestSide)
end

local function checkStats()
    if turtle.getItemCount(DUMP_SLOT) > 0 then
        dumpItems()
    end

    if utils.needsFuel() then
        print("Refueling...")
        utils.refuelFromChest(SLOT.fuel, chestSide, true)
    end
end

---------------------------------------------------------------------------
-- Movement with position tracking
---------------------------------------------------------------------------

local function turn(direction)
    utils.turn(direction)
    if direction == "r" then
        facing = facing % 4 + 1
    else
        facing = (facing + 2) % 4 + 1
    end
end

local function reverse()
    turn("r")
    turn("r")
end

local function setFacing(looking)
    while facing ~= looking do
        turn("r")
    end
end

--- Each move only updates the position when it actually succeeded.
-- A failed move (e.g. bedrock) makes the current layer the last one.
local function forward()
    local ok, reason = utils.tryMove("forward", true)
    if ok then
        pos.x = pos.x + FACING[facing].dx
        pos.z = pos.z + FACING[facing].dz
    else
        print("Cannot move forward (" .. reason .. "), this will be the last layer")
        last = true
    end
    checkStats()
    return ok
end

local function down()
    local ok = utils.tryMove("down", true)
    if ok then
        pos.y = pos.y + 1
    else
        last = true
    end
    return ok
end

local function up()
    local ok = utils.tryMove("up", true)
    if ok then
        pos.y = pos.y - 1
    else
        last = true
    end
    return ok
end

local function digUpDown()
    if turtle.detectUp() then
        turtle.digUp()
    end
    if turtle.detectDown() then
        turtle.digDown()
    end
end

local function zigzag()
    for n = 1, width do
        for _ = 1, length - 1 do
            forward()
            digUpDown()
        end

        if n < width then
            turn(nextTurn)
            forward()
            digUpDown()
            turn(nextTurn)
            nextTurn = nextTurn == "r" and "l" or "r"
        end
    end
end

local function must(ok, what)
    if not ok then
        error(("Stuck while moving %s at x=%d, y=%d, z=%d"):format(what, pos.x, pos.y, pos.z), 0)
    end
end

local function goTo(x, y, z)
    print(("Moving to x: %d, y: %d, z: %d..."):format(x, y, z))
    while pos.y > y do must(up(), "up") end
    while pos.y < y do must(down(), "down") end

    if pos.x > x then
        setFacing(4)
        while pos.x > x do must(forward(), "west") end
    elseif pos.x < x then
        setFacing(2)
        while pos.x < x do must(forward(), "east") end
    end

    if pos.z > z then
        setFacing(3)
        while pos.z > z do must(forward(), "south") end
    elseif pos.z < z then
        setFacing(1)
        while pos.z < z do must(forward(), "north") end
    end
end

--- Returns the turtle to the start position.
local function home()
    print("Returning home...")
    print(("Current coordinates: x=%d, y=%d, z=%d"):format(pos.x, pos.y, pos.z))
    print("Turtle is facing " .. FACING[facing].name)

    goTo(0, 0, -1)
    setFacing(1)
end

---------------------------------------------------------------------------
-- Main
---------------------------------------------------------------------------

checkStats()
digUpDown()

while not endOfRun do
    zigzag()

    if not last then
        reverse()
        print("Moving to the next layer...")
        for _ = 1, 3 do
            if pos.y == target and depth ~= 0 then
                print("I hit my target!")
                last = true
                break
            end
            if vDirection == "d" then
                down()
            else
                up()
            end
        end
        digUpDown()
    else
        print("This is my last run...")
        endOfRun = true
    end
end

home()
dumpItems()

print("In total " .. unloaded .. " items were mined...")
