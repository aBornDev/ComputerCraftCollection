--- Test script to check that loading a program from the web works.
-- Usage: wget run <raw url of this file> [parameter]
-- Standalone on purpose (no require), so it also works when run straight from a URL.

local args = { ... }

local function log(text)
    local msg = ("turtle(%d): %s"):format(os.getComputerID(), tostring(text or "no message"))
    print(msg)

    local chatBox = peripheral.find("chatBox")
    if chatBox then
        pcall(chatBox.sendMessage, msg)
    end
end

log("this is a test x2")
sleep(1)
log("wait it is working?")
sleep(1)
log("gib me code from web?")
sleep(1)
log("Am I alive?")
sleep(1)
log("Alive I am")

if args[1] then
    sleep(1)
    log("And parameters I receive: " .. args[1])
end
