--- Chat with Claude from a ComputerCraft computer.
--
-- Setup (once):  set claude.key sk-ant-...
-- Usage:         claudeChat
-- Commands:      /reset  start a new conversation
--                /usage  show tokens used this session
--                /exit   quit
--
-- Note: the API key is stored on this computer. On a shared server, admins
-- (and anyone who can open this computer) can read it.

local API_URL = "https://api.anthropic.com/v1/messages"
local API_VERSION = "2026-10-21"
local FALLBACK_BETA = "server-side-fallback-2026-07-01"
local REQUEST_TIMEOUT = 120 -- seconds

settings.define("claude.key", { description = "Anthropic API key for claudeChat", type = "string" })
settings.define("claude.model", { description = "Claude model for claudeChat", default = "claude-opus-5-5", type = "string" })
settings.define("claude.effort", { description = "Effort: low, medium, high, xhigh or max", default = "low", type = "string" })
settings.define("claude.max_tokens", { description = "Maximum tokens per answer", default = 1024, type = "number" })

local apiKey = settings.get("claude.key")
if not apiKey or apiKey == "" then
    print("No API key set. Run:")
    print("  set claude.key sk-ant-...")
    return
end
if not http then
    error("The HTTP API is disabled in the ComputerCraft config", 0)
end

local width = term.getSize()
local SYSTEM_PROMPT = ("You are Claude, chatting through a ComputerCraft computer in Minecraft. "
    .. "The screen is a plain-text terminal %d characters wide: do not use Markdown, tables or emoji. "
    .. "Keep answers short unless the player asks for detail. "
    .. "When asked for ComputerCraft code, write Lua for CC: Tweaked."):format(width)

local messages = {}
local usage = { input = 0, output = 0, cacheRead = 0 }

---------------------------------------------------------------------------
-- Output helpers
---------------------------------------------------------------------------

local function setColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end

-- The terminal font only has ASCII/Latin-1; replace common UTF-8 punctuation.
local REPLACEMENTS = {
    ["\226\128\152"] = "'", ["\226\128\153"] = "'", -- ‘ ’
    ["\226\128\156"] = '"', ["\226\128\157"] = '"', -- “ ”
    ["\226\128\147"] = "-", ["\226\128\148"] = "-", -- – —
    ["\226\128\166"] = "...",                       -- …
    ["\226\128\162"] = "*",                         -- •
    ["\194\160"] = " ",                             -- non-breaking space
}

local function toTerminal(text)
    for from, to in pairs(REPLACEMENTS) do
        text = text:gsub(from, to)
    end
    -- Any other multi-byte character becomes "?"
    return (text:gsub("[\192-\247][\128-\191]*", "?"))
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------

local function errorMessage(response, fallback)
    if not response then
        return fallback
    end
    local ok, data = pcall(textutils.unserialiseJSON, response.readAll())
    response.close()
    if ok and type(data) == "table" and data.error and data.error.message then
        return data.error.type .. ": " .. data.error.message
    end
    return fallback
end

--- Sends the conversation to Claude. Returns the response message or nil plus an error.
local function ask()
    local body = textutils.serialiseJSON({
        model = settings.get("claude.model"),
        max_tokens = settings.get("claude.max_tokens"),
        system = SYSTEM_PROMPT,
        output_config = { effort = settings.get("claude.effort") },
        cache_control = { type = "ephemeral" },
        fallbacks = "default",
        messages = messages,
    }, { unicode_strings = true })

    local response, err, errResponse = http.post({
        url = API_URL,
        body = body,
        headers = {
            ["Content-Type"] = "application/json",
            ["x-api-key"] = apiKey,
            ["anthropic-version"] = API_VERSION,
            ["anthropic-beta"] = FALLBACK_BETA,
        },
        timeout = REQUEST_TIMEOUT,
    })

    if not response then
        return nil, errorMessage(errResponse, tostring(err))
    end

    local text = response.readAll()
    response.close()
    local data = textutils.unserialiseJSON(text)
    if type(data) ~= "table" then
        return nil, "Could not read the response from the API"
    end
    return data
end

--- textutils.serialiseJSON writes an empty Lua table as {}; turn empty
-- tables that came from JSON back into [] so resent content stays unchanged.
local function fixEmptyArrays(value)
    if type(value) ~= "table" then
        return value
    end
    if next(value) == nil then
        return textutils.empty_json_array
    end
    for k, v in pairs(value) do
        value[k] = fixEmptyArrays(v)
    end
    return value
end

local function addUsage(u)
    if not u then return end
    usage.input = usage.input + (u.input_tokens or 0) + (u.cache_creation_input_tokens or 0)
    usage.cacheRead = usage.cacheRead + (u.cache_read_input_tokens or 0)
    usage.output = usage.output + (u.output_tokens or 0)
end

---------------------------------------------------------------------------
-- Chat loop
---------------------------------------------------------------------------

local function showHelp()
    setColor(colors.lightGray)
    print("Commands: /reset (new conversation), /usage, /exit")
    setColor(colors.white)
end

term.clear()
term.setCursorPos(1, 1)
setColor(colors.orange)
print("Claude chat (" .. settings.get("claude.model") .. ")")
showHelp()

local inputHistory = {}

while true do
    setColor(colors.yellow)
    write("> ")
    setColor(colors.white)
    local input = read(nil, inputHistory)

    if input == nil or input == "/exit" or input == "exit" then
        break
    elseif input == "/reset" then
        messages = {}
        setColor(colors.lightGray)
        print("Started a new conversation.")
    elseif input == "/usage" then
        setColor(colors.lightGray)
        print(("Input: %d tokens (+%d from cache), output: %d tokens"):format(
            usage.input, usage.cacheRead, usage.output))
    elseif input == "/help" then
        showHelp()
    elseif input:find("%S") then
        table.insert(inputHistory, input)
        table.insert(messages, { role = "user", content = input })

        setColor(colors.lightGray)
        print("Thinking...")
        local reply, err = ask()

        if not reply then
            -- Drop the unanswered question so the conversation stays valid.
            table.remove(messages)
            setColor(colors.red)
            print("Error: " .. err)
        elseif reply.stop_reason == "refusal" then
            table.remove(messages)
            addUsage(reply.usage)
            setColor(colors.red)
            print("Claude declined to answer that.")
        elseif type(reply.content) ~= "table" or #reply.content == 0 then
            table.remove(messages)
            addUsage(reply.usage)
            setColor(colors.red)
            print("Claude sent an empty answer, try again.")
        else
            addUsage(reply.usage)
            -- Keep the full content (including thinking blocks) for the next request.
            table.insert(messages, { role = "assistant", content = fixEmptyArrays(reply.content) })

            local parts = {}
            for _, block in ipairs(reply.content) do
                if block.type == "text" then
                    table.insert(parts, block.text)
                end
            end

            setColor(colors.white)
            textutils.pagedPrint(toTerminal(table.concat(parts, "\n")))
            if reply.stop_reason == "max_tokens" then
                setColor(colors.lightGray)
                print("(answer cut off; raise claude.max_tokens for longer answers)")
            end
        end
    end
end

setColor(colors.white)
