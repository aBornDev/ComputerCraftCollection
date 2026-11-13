-- luacheck configuration for ComputerCraft (CC: Tweaked) scripts
stds.computercraft = {
    read_globals = {
        "turtle", "peripheral", "sleep", "read", "write", "colors", "colours",
        "term", "fs", "http", "shell", "textutils", "rednet", "redstone", "settings",
        os = { fields = { "getComputerID", "pullEvent", "pullEventRaw", "startTimer", "epoch", "day" } },
    },
}

std = "lua51+computercraft"
max_line_length = false
