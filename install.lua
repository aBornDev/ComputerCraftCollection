--- Downloads all programs (and the shared library) from GitHub.
-- Usage: install [branch]          (default: main)
-- First time: wget run https://raw.githubusercontent.com/aBornDev/ComputerCraftCollection/main/install.lua

local branch = ({ ... })[1] or "main"
local BASE_URL = "https://raw.githubusercontent.com/aBornDev/ComputerCraftCollection/" .. branch .. "/"

local FILES = {
    "lib/turtleUtils.lua",
    "builderQuarry.lua",
    "autoDigitalMiner.lua",
    "betterExcavate.lua",
    "touchScreen.lua",
    "remoteLoadTest.lua",
    "install.lua",
}

if not http then
    error("The HTTP API is disabled in the ComputerCraft config", 0)
end

local failed = 0
for _, path in ipairs(FILES) do
    write("Downloading " .. path .. "... ")
    local response, err = http.get(BASE_URL .. path)
    if response then
        local content = response.readAll()
        response.close()

        local file = fs.open(path, "w")
        file.write(content)
        file.close()
        print("ok")
    else
        print("failed (" .. tostring(err) .. ")")
        failed = failed + 1
    end
end

if failed > 0 then
    print(failed .. " file(s) failed to download")
else
    print("All files installed from branch '" .. branch .. "'")
end
