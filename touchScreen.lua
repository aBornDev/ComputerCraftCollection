--- Touch screen with buttons on a monitor; sends commands through a modem.
-- Needs a monitor and a modem attached to the computer.

local LISTEN_CHANNEL = 1
local SPAWNER_CHANNEL = 3

local modem = peripheral.find("modem") or error("No modem attached", 0)
local monitor = peripheral.find("monitor") or error("No monitor attached", 0)

modem.open(LISTEN_CHANNEL)
monitor.setBackgroundColor(colors.black)
monitor.clear()

local buttons = {}

--- Adds a 3 high button. A width below 1 means "fit the label".
local function addButton(tag, x, y, width, color, onPress)
    if not width or width < 1 then
        width = #tag + 2
    end

    local button = { tag = tag, x = x, y = y, width = width, color = color, active = false, onPress = onPress }
    table.insert(buttons, button)
    return button
end

local function drawButton(button)
    local label = button.tag:sub(1, button.width)
    local free = button.width - #label
    local padLeft = math.ceil(free / 2)
    local padRight = free - padLeft
    local blank = string.rep(" ", button.width)

    monitor.setBackgroundColor(colors[button.color])
    monitor.setTextColor(colors.white)

    monitor.setCursorPos(button.x, button.y - 1)
    monitor.write(blank)
    monitor.setCursorPos(button.x, button.y)
    monitor.write(string.rep(" ", padLeft) .. label .. string.rep(" ", padRight))
    monitor.setCursorPos(button.x, button.y + 1)
    monitor.write(blank)
end

local function drawButtons()
    for _, button in ipairs(buttons) do
        drawButton(button)
    end
end

local function isInside(button, x, y)
    return x >= button.x and x < button.x + button.width
        and y >= button.y - 1 and y <= button.y + 1
end

local function toggleSpawner(button)
    if button.active then
        modem.transmit(SPAWNER_CHANNEL, LISTEN_CHANNEL, "off")
        button.active = false
        button.color = "green"
    else
        modem.transmit(SPAWNER_CHANNEL, LISTEN_CHANNEL, "on")
        button.active = true
        button.color = "red"
    end
end

addButton("spawner", 3, 3, 15, "green", toggleSpawner)
drawButtons()

while true do
    local _, _, x, y = os.pullEvent("monitor_touch")

    for _, button in ipairs(buttons) do
        if isInside(button, x, y) then
            print("Button '" .. button.tag .. "' pressed at: x=" .. x .. " y=" .. y)
            button.onPress(button)
            break
        end
    end

    drawButtons()
end
