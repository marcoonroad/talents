local tostring = tostring
local export   = { }

function export.required (selector)
        local format = "Selector [%s] is required but not implemented!"

        return format: format (tostring (selector))
end

function export.conflict (selector)
        local format = "A conflict arises on object's selector [%s]!"

        return format: format (tostring (selector))
end

function export.reading (selector)
        local format = "This read operation (on selector [%s]) is not allowed!"

        return format: format (tostring (selector))
end

function export.writing (selector, value)
        local format = "This write operation (on selector [%s] with value [%s]) is not allowed!"

        return format: format (tostring (selector), tostring (value))
end

function export.ownership (selector, value)
        local format = "Attempt to perform mutation outside the owner thread (at [%s], with [%s])!"

        return format: format (tostring (selector), tostring (value))
end

function export.violation (selector)
        local format = "Violation of contract by applied talent, selector [%s] is not required neither provided!"

        return format: format (tostring (selector))
end

export.disabled  = "Cannot use this confined reference outside the contract!"
export.invalid   = "That function was called with an invalid argument!"

return export
