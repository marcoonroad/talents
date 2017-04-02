local assert       = assert
local error        = error
local ipairs       = ipairs
local load         = load
local pairs        = pairs
local require      = require
local setfenv      = setfenv
local setmetatable = setmetatable
local tostring     = tostring
local _VERSION     = _VERSION

local reason = require 'talents.internals.reason'
local weak   = require 'talents.internals.weak'

local function eval (program, environment, ...)
        local major, minor = _VERSION: match ("(%d).(%d)")

        assert (major == "5", "Only works on some Lua 5 versions!")

        if minor == "1" then
                local chunk = assert (loadstring (program))

                setfenv (chunk, environment)

                return chunk (...)
        elseif minor == "2" or minor == "3" then
                return assert (load (program, "[selective's module space]", "t", environment)) (...)
        end
end

local function binary (operator)
        return ("(value) return target[ self ] %s value"): format (operator)
end

local function functor ( )
        local export = { }

        local target  = weak.key ( )
        local enabled = weak.key ( )

        local handler = { }

        handler.__metatable = "[selective proxy's handler]"

        local function method (template)
                return function (self, ...)
                        if enabled[ self ] then
                                local program = ("return (function %s end) (...) "): format (template)

                                return eval (program, {
                                        enabled  = enabled,
                                        self     = self,
                                        target   = target,
                                        tostring = tostring,
                                        pairs    = pairs,
                                        ipairs   = ipairs,
                                }, ...)
                        else
                                error (reason.disabled)
                        end
                end
        end

        local methods = {
                __index    = "(selector)        return target[ self ][ selector ]",
                __newindex = "(selector, value)        target[ self ][ selector ] = value",
                __call     = "(...)             return target[ self ] (...)",
                __tostring = "( )               return tostring (target[ self ])",
                __pairs    = "( )               return pairs (target[ self ])",
                __ipairs   = "( )               return ipairs (target[ self ])",
                __len      = "( )               return #(target[ self ])",
                __unm      = "( )               return -(target[ self ])",
                __bnot     = "( )               return ~(target[ self ])",

                __eq     = binary "==", __lt   = binary "<", __le  = binary "<=",
                __concat = binary "..", __add  = binary "+", __sub = binary "-",
                __idiv   = binary "//", __div  = binary "/", __mod = binary "%",
                                        __pow  = binary "^", __mul = binary "*",
                __shl    = binary "<<", __band = binary "&", __bor = binary "|",
                __shr    = binary ">>", __bxor = binary "~",
        }

        for event, template in pairs (methods) do
                handler[ event ] = method (template)
        end

        -- public definitions --
        function export.wrap (object)
                local proxy = { }

                target[ proxy ]  = object
                enabled[ proxy ] = true

                setmetatable (proxy, handler)

                return proxy
        end

        function export.enable (proxy)
                if target[ proxy ] then
                        enabled[ proxy ] = true
                else
                        error (reason.invalid)
                end
        end

        function export.disable (proxy)
                if target[ proxy ] then
                        enabled[ proxy ] = false
                else
                        error (reason.invalid)
                end
        end

        return export
end

return functor
