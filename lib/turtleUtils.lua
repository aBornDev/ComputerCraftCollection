--- Shared helpers for the turtle scripts in this repository.
-- Load with: local utils = require("lib.turtleUtils")

local M = {}

-- How often a move is retried (mobs, falling sand/gravel, ...) before giving up.
M.MAX_MOVE_ATTEMPTS = 20
-- Refuel when the fuel level drops below this value.
M.FUEL_THRESHOLD = 1000

---------------------------------------------------------------------------
-- Logging
---------------------------------------------------------------------------

--- Current (real world) server time as HH:MM.
function M.time()
    return os.date("%H:%M")
end

--- Prints a message and, when a chat box is attached, sends it to chat as well.
function M.log(text)
    local msg = ("turtle(%d): %s"):format(os.getComputerID(), tostring(text or "no message"))
    print(msg)

    local chatBox = peripheral.find("chatBox")
    if chatBox then
        -- The chat box has a cooldown; never let chat errors stop the program.
        pcall(chatBox.sendMessage, msg)
    end
end

---------------------------------------------------------------------------
-- Turtle API per direction / side
---------------------------------------------------------------------------

local MOVE, SIDE = {}, {}

if turtle then
    MOVE = {
        forward = { move = turtle.forward, dig = turtle.dig,     detect = turtle.detect,     attack = turtle.attack },
        up      = { move = turtle.up,      dig = turtle.digUp,   detect = turtle.detectUp,   attack = turtle.attackUp },
        down    = { move = turtle.down,    dig = turtle.digDown, detect = turtle.detectDown, attack = turtle.attackDown },
    }

    SIDE = {
        front = { place = turtle.place,     dig = turtle.dig,     drop = turtle.drop,     suck = turtle.suck },
        up    = { place = turtle.placeUp,   dig = turtle.digUp,   drop = turtle.dropUp,   suck = turtle.suckUp },
        down  = { place = turtle.placeDown, dig = turtle.digDown, drop = turtle.dropDown, suck = turtle.suckDown },
    }
end

local function getSide(side)
    return SIDE[side] or error("Unknown side: " .. tostring(side), 3)
end

---------------------------------------------------------------------------
-- Movement
---------------------------------------------------------------------------

--- Tries to move one block in `dir` ("forward", "up" or "down").
-- Retries when a mob or falling block is in the way. Only digs when `allowDig` is true.
-- @return true on success, or false plus a reason.
function M.tryMove(dir, allowDig)
    local d = MOVE[dir] or error("Unknown direction: " .. tostring(dir), 2)

    for _ = 1, M.MAX_MOVE_ATTEMPTS do
        local ok, reason = d.move()
        if ok then
            return true
        end
        if reason == "Out of fuel" then
            return false, reason
        end

        if d.detect() then
            if allowDig and not d.dig() then
                return false, "unbreakable block"
            end
        else
            d.attack() -- probably a mob
        end
        sleep(0.2)
    end

    return false, "path blocked"
end

--- Moves `count` blocks in `dir` and raises an error when that fails,
-- so the turtle never continues from a wrong position.
function M.move(dir, count, allowDig)
    count = count or 1
    for i = 1, count do
        local ok, reason = M.tryMove(dir, allowDig)
        if not ok then
            error(("Cannot move %s (step %d/%d): %s"):format(dir, i, count, reason), 0)
        end
    end
end

function M.forward(count, allowDig) M.move("forward", count, allowDig) end
function M.up(count, allowDig)      M.move("up", count, allowDig) end
function M.down(count, allowDig)    M.move("down", count, allowDig) end

--- Moves backwards; turns around and moves forward when something is behind the turtle.
function M.back(count, allowDig)
    for _ = 1, count or 1 do
        if not turtle.back() then
            M.reverse()
            M.forward(1, allowDig)
            M.reverse()
        end
    end
end

--- Turns "l" (left) or "r" (right).
function M.turn(direction)
    if direction == "r" then
        turtle.turnRight()
    elseif direction == "l" then
        turtle.turnLeft()
    else
        error("Unknown turn direction: " .. tostring(direction), 2)
    end
end

function M.reverse()
    turtle.turnRight()
    turtle.turnRight()
end

---------------------------------------------------------------------------
-- Inventory / world interaction
---------------------------------------------------------------------------

--- Places the selected item at `side` ("front", "up" or "down").
-- When `allowDig` is true, a block in the way is dug first.
function M.place(side, allowDig)
    local s = getSide(side)
    if s.place() then
        return true
    end
    return allowDig == true and s.dig() and s.place() or false
end

function M.dig(side)  return getSide(side).dig() end
function M.drop(side) return getSide(side).drop() end
function M.suck(side, count) return getSide(side).suck(count) end

---------------------------------------------------------------------------
-- Fuel
---------------------------------------------------------------------------

--- Fuel level as a number (math.huge when fuel is disabled in the server config).
function M.fuelLevel()
    local level = turtle.getFuelLevel()
    if level == "unlimited" then
        return math.huge
    end
    return level
end

function M.needsFuel(threshold)
    return M.fuelLevel() < (threshold or M.FUEL_THRESHOLD)
end

--- Places the fuel container from `slot` at `side`, takes fuel out of it,
-- refuels and picks the container up again.
function M.refuelFromChest(slot, side, allowDig)
    turtle.select(slot)
    if not M.place(side, allowDig) then
        M.log("Could not place the fuel container (" .. side .. ")")
        return false
    end

    M.suck(side, 64)
    turtle.refuel(64)
    M.dig(side)

    if M.needsFuel() then
        M.log("Warning: fuel is still low (" .. M.fuelLevel() .. "), is the fuel container empty?")
    end
    return true
end

---------------------------------------------------------------------------
-- Time
---------------------------------------------------------------------------

local function toMinutes(t)
    return t.hours * 60 + t.minutes
end

--- True when the current server time is between `from` and `to` (inclusive).
-- Both are tables like { hours = 7, minutes = 30 }. Windows over midnight
-- (e.g. 23:00 - 01:00) are supported.
function M.isTimeBetween(from, to)
    local now = tonumber(os.date("%H")) * 60 + tonumber(os.date("%M"))
    local a, b = toMinutes(from), toMinutes(to)
    if a <= b then
        return now >= a and now <= b
    end
    return now >= a or now <= b
end

return M
