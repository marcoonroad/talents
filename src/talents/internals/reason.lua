local tostring = tostring
local export   = { }

local ownership    = require 'talents.internals.reason.ownership'
local transference = require 'talents.internals.reason.transference'
local application  = require 'talents.internals.reason.application'

function export.reading (selector)
    local format = "This read operation (on selector [%s]) is not allowed!"

    return format: format (tostring (selector))
end

function export.writing (selector, value)
    local format =
      "This write operation (on selector [%s] with value [%s]) is not allowed!"

    return format: format (tostring (selector), tostring (value))
end

export.disabled     = "Cannot use this confined reference outside the contract!"
export.invalid      = "That function was called with an invalid argument!"

export.application  = application
export.ownership    = ownership
export.transference = transference

return export

-- END --
