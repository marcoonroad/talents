local error        = error
local require      = require
local setmetatable = setmetatable

local reason = require 'talents.internals.reason'

local function __index (_, selector)
        error (reason.reading (selector))
end

local function __newindex (_, selector, value)
        error (reason.writing (selector, value))
end

local function __tostring (_)
        return '[unique identity token]'
end

local function functor (external)
        local export = { }

        local metaobject = { }

        metaobject.__metatable = "[hidden token's meta-object]"

        metaobject.__index    = __index
        metaobject.__newindex = __newindex
        metaobject.__tostring = __tostring

        for event, method in pairs (external) do
                metaobject[ event ] = method
        end

        function export.generate ( )
                return setmetatable ({ }, metaobject)
        end

        return export
end

return functor
