local string = require "string"
local table  = require "table"
local export = { }

function export.invalid (expected, current)
	local format = table.concat ({
        "Invalid argument on transference!",
        "Expected [%s], got instead [%s]!",
    }, " ")

	return string.format (format, expected, current)
end

function export.current ( )
    local format =
        "Can't transfer ownership 'cause running coroutine isn't the owner!"

    return format
end

function export.coroutine (status)
    local format = "Can't transfer ownership to a [%s] coroutine!"

    return string.format (format, status)
end

return export

-- END --
