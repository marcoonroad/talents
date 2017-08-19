local tostring = tostring
local string   = require 'string'
local table    = require 'table'
local export   = { }

function export.violation (selector, value)
	local format = table.concat ({
        "Mutations aren't allowed outside owner thread!",
        "Context is selector [%s], value [%s].",
    }, " ")

	return string.format (format, tostring (selector), tostring (value))
end

return export

-- END --
