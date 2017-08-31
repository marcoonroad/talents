local ipairs    = ipairs
local pairs     = pairs
local tostring  = tostring
local reason    = require 'talents.internals.reason'
local memory    = require 'talents.internals.memory'
local utilities = require 'talents.internals.utilities'

local eval      = utilities.eval
local binary    = utilities.binary
local injected  = memory.injected
local decorator = memory.decorator
local decorated = memory.decorated
local ownership = memory.ownership
local delegated = memory.delegated

local function functor (external)
    local export    = { }
    local identity  = external.identity
    local equality  = external.equality
    local _         = external.iterator
    local _         = external.inspect

    local required  = external.required
    local exclusive = external.exclusive
    local _         = external.conflict

    export.__metatable = "[proxy object's metaobject]"

    function export: __index (selector)
        local index   = 2
        local caller  = debug.getinfo (index)

        while caller do
            if caller and caller.func and
                injected[ identity (caller.func) ] and
                injected[ identity (caller.func) ][ identity (self) ] and
                not decorator[ identity (self) ][ identity (selector) ]
            then
                error (reason.application.violation (selector))

            else
                index  = index + 1
                caller = debug.getinfo (index)
            end
        end

        local value = delegated[ identity (self) ][ identity (selector) ]

        if equality (value, nil) and decorator[ identity (self) ] then
            value = decorator[ identity (self) ][ identity (selector) ]
        end

        if (equality (value, nil) or equality (value, required)
            or equality (value, exclusive)) and decorated[ identity (self) ]
        then
            value = decorated[ identity (self) ][ identity (selector) ]
        end

        return value
    end

    function export: __newindex (selector, value)
        local owner   = ownership[ identity (self) ]
        local current = coroutine.running ( ) or true

        if equality (owner, current) then
			local previous = decorator[ identity (self) ][ identity (selector) ]

			if equality (previous, exclusive) then
				decorated[ identity (self) ][ identity (selector) ] = value

			else
				delegated[ identity (self) ][ identity (selector) ] = value
            end

        else
            error (reason.ownership.violation (selector, value))
        end
    end

    local function method (template)
        return function (self, ...)
            local program = ("return (function %s end) (...) "):
                format (template)

            return eval (program, {
                self       = self,
                decorated  = decorated,
                tostring   = tostring,
                pairs      = pairs,
                ipairs     = ipairs,
            }, ...)
        end
    end

    local methods = {
        __call     = "(...) return decorated[ self ] (...)",
        __tostring = "( )   return tostring (decorated[ self ])",
        __pairs    = "( )   return pairs (decorated[ self ])",
        __ipairs   = "( )   return ipairs (decorated[ self ])",
        __len      = "( )   return #(decorated[ self ])",
        __unm      = "( )   return -(decorated[ self ])",
        __bnot     = "( )   return ~(decorated[ self ])",

        __eq     = binary "==", __lt   = binary "<", __le  = binary "<=",
        __concat = binary "..", __add  = binary "+", __sub = binary "-",
        __idiv   = binary "//", __div  = binary "/", __mod = binary "%",
        __pow    = binary "^",  __mul  = binary "*",
        __shl    = binary "<<", __band = binary "&", __bor = binary "|",
        __shr    = binary ">>", __bxor = binary "~",
    }

    for event, template in pairs (methods) do
        export[ event ] = method (template)
    end

    return export
end

return functor

-- END --
