local tostring = tostring
local string   = require "string"
local table    = require "table"
local export   = { }

function export.required (selector)
    local format = "Selector [%s] is required but not implemented!"

    return string.format (format, tostring (selector))
end

function export.conflict (selector)
    local format = "A conflict arises on object's selector [%s]!"

    return string.format (format, tostring (selector))
end

function export.violation (selector)
    local format = table.concat ({
        "Violation of contract by applied talent!",
        "Selector [%s] is not required neither provided."
    }, " ")

    return string.format (format, tostring (selector))
end

return export

-- END --
