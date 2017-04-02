local setmetatable = setmetatable
local export       = { }

local metatable = {
        key   = { __mode = 'k',  },
        value = { __mode = 'v',  },
        pair  = { __mode = 'kv', },
}

function export.key (structure)
        return setmetatable (structure or { }, metatable.key)
end

function export.value (structure)
        return setmetatable (structure or { }, metatable.value)
end

function export.pair (structure)
        return setmetatable (structure or { }, metatable.pair)
end

return export
