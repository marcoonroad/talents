local _VERSION   = _VERSION
local assert     = assert
local load       = load
local loadstring = loadstring
local setfenv    = setfenv
local string     = require "string"
local export     = { }

function export.eval (program, environment, ...)
    local major, minor = string.match (_VERSION, "(%d).(%d)")

    assert (major == "5", "Only works on some Lua 5.* versions!")

    if minor == "1" then
        local chunk = assert (loadstring (program))

        setfenv (chunk, environment)

        return chunk (...)

    elseif minor == "2" or minor == "3" then
        return assert (load (program,
            "[pluggable's module space]", "t", environment)) (...)

    else
        error (string.format ("Version v%s%.%s is not supported yet!",
            major, minor))
    end
end

function export.binary (operator)
    return string.format ("(value) return decorated[ self ] %s value",
        operator)
end

return export

-- END --
