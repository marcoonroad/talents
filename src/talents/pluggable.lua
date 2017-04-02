local assert       = assert
local coroutine    = coroutine
local debug        = debug
local error        = error
local ipairs       = ipairs
local load         = load
local require      = require
local pairs        = pairs
local pcall        = pcall
local setfenv      = setfenv
local setmetatable = setmetatable
local tostring     = tostring
local _VERSION     = _VERSION

local reason  = require 'talents.internals.reason'
local weak    = require 'talents.internals.weak'
local default = require 'talents.internals.default'

local function eval (program, environment, ...)
        local major, minor = _VERSION: match ("(%d).(%d)")

        assert (major == "5", "Only works on some Lua 5.* versions!")

        if minor == "1" then
                local chunk = assert (loadstring (program))

                setfenv (chunk, environment)

                return chunk (...)
        elseif minor == "2" or minor == "3" then
                return assert (load (program, "[pluggable's module space]", "t", environment)) (...)
        end
end

local function binary (operator)
        return ("(value) return decorated[ self ] %s value"): format (operator)
end

local function functor (external)
        local identity = external.identity or default.identity
        local iterator = external.iterator or default.iterator
        local equality = external.equality or default.equality
        local inspect  = external.inspect  or default.inspect

        local export     = { }
        local metatalent = { }
        local selective  = require 'talents.internals.selective' ( )
        local token      = require 'talents.internals.token' { }
        local talents    = nil

        local required = token.generate ( )
        local conflict = token.generate ( )

        local bindings   = weak.key ( )
        local reflected  = weak.pair ( )
        local decorator  = weak.pair ( )
        local decorated  = weak.key ( )
        local delegated  = weak.key ( )
        local subjective = weak.key ( )
        local objective  = weak.pair ( )
        local injected   = weak.key ( )
        local ownership  = weak.key ( )

        local metaobject = { }

        metaobject.__metatable = "[proxy object's metaobject]"

        function metaobject: __index (selector)
                local index   = 2
                local caller  = debug.getinfo (index)

                while caller do
                        if caller and caller.func and injected[ identity (caller.func) ] and
                           injected[ identity (caller.func) ][ identity (self) ] and
                           not decorator[ identity (self) ][ identity (selector) ] then
                                        error (reason.violation (selector))

                        else
                                index  = index + 1
                                caller = debug.getinfo (index)
                        end
                end

                local value = delegated[ identity (self) ][ identity (selector) ]

                if equality (value, nil) and decorator[ identity (self) ] then
                        value = decorator[ identity (self) ][ identity (selector) ]
                end

                if equality (value, nil) or equality (value, required) then
                        value = decorated[ identity (self) ][ identity (selector) ]
                end

                return value
        end

        function metaobject: __newindex (selector, value)
                local owner   = ownership[ identity (self) ]
                local current = coroutine.running ( )

                if equality (owner, current) then
                        delegated[ identity (self) ][ identity (selector) ] = value
                else
                        error (reason.ownership (selector, value))
                end
        end

        local function method (template)
                return function (self, ...)
                        local program = ("return (function %s end) (...) "): format (template)

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
                __call     = "(...)             return decorated[ self ] (...)",
                __tostring = "( )               return tostring (decorated[ self ])",
                __pairs    = "( )               return pairs (decorated[ self ])",
                __ipairs   = "( )               return ipairs (decorated[ self ])",
                __len      = "( )               return #(decorated[ self ])",
                __unm      = "( )               return -(decorated[ self ])",
                __bnot     = "( )               return ~(decorated[ self ])",

                __eq     = binary "==", __lt   = binary "<", __le  = binary "<=",
                __concat = binary "..", __add  = binary "+", __sub = binary "-",
                __idiv   = binary "//", __div  = binary "/", __mod = binary "%",
                                        __pow  = binary "^", __mul = binary "*",
                __shl    = binary "<<", __band = binary "&", __bor = binary "|",
                __shr    = binary ">>", __bxor = binary "~",
        }

        for event, template in pairs (methods) do
                metaobject[ event ] = method (template)
        end

        function metatalent: __tostring ( )
                return "[talent abstraction]"
        end

        function metatalent: __call (structure, scope, ...)
                if scope then
                        return export.activate (self, structure, scope, ...)

                else
                        return export.decorate (self, structure)
                end
        end

        function metatalent: __shr (structure)
                return export.extend (self, structure)
        end

        function metatalent: __add (talent)
                return export.compose (self, talent)
        end

        metatalent.__bor = metatalent.__add

        -- public definitions  --
        function export.required ( )
                return required
        end

        function export.requires (talent, selector)
                return equality (bindings[ identity (talent) ][ identity (selector) ], required)
        end

        function export.conflicts (talent, selector)
                return equality (bindings[ identity (talent) ][ identity (selector) ], conflict)
        end

        function export.provides (talent, selector)
                local value = bindings[ identity (talent) ][ identity (selector) ]

                return not (equality (value, nil) or
                            equality (value, required) or
                            equality (value, conflict))
        end

        function export.talent (structure)
                local token = talents.generate ( )

                local copy = { }

                for selector, value in iterator (structure) do
                        copy[ identity (selector) ] = value
                end

                bindings[ token ]   = copy
                reflected[ copy ]   = token
                subjective[ token ] = weak.key ( )

                return token
        end

        function export.decorate (talent, object)
                local self = { }

                for selector, value in iterator (bindings[ identity (talent) ]) do
                        if equality (value, conflict) then
                                error (reason.conflict (selector))

                        elseif equality (value, required) and equality (object[ identity (selector) ], nil) then
                                error (reason.required (selector))

                        else
                                local class = inspect (value)

                                if class == "function" then
                                        if not injected[ identity (value) ] then
                                                injected[ identity (value) ] = weak.key ( )
                                        end

                                        injected[ identity (value) ][ self ] = true
                                end
                        end
                end

                decorator[ self ] = bindings[ identity (talent) ]
                decorated[ self ] = object
                delegated[ self ] = { }
                ownership[ self ] = coroutine.running ( )

                setmetatable (self, metaobject)

                return self
        end

        function export.compose (first, second)
                local structure = { }
                local token     = talents.generate ( )

                bindings[ token ]      = structure
                reflected[ structure ] = token
                subjective[ token ]    = weak.key ( )

                for selector, value in iterator (bindings[ identity (first) ]) do
                        structure[ identity (selector) ] = value
                end

                for selector, value in iterator (bindings[ identity (second) ]) do
                        if equality (structure[ identity (selector) ], nil) or
                           equality (structure[ identity (selector) ], required) then
                                structure[ identity (selector) ] = value

                        elseif (not equality (value, required)) and
                               (not equality (structure[ identity (selector) ], value)) then
                                structure[ identity (selector) ] = conflict
                        end
                end

                return token
        end

        function export.extend (talent, extension)
                local structure = { }
                local token     = talents.generate ( )

                bindings[ token ]      = structure
                reflected[ structure ] = token
                subjective[ token ]    = weak.key ( )

                for selector, value in iterator (bindings[ identity (talent) ]) do
                        structure[ identity (selector) ] = value
                end

                for selector, value in iterator (extension) do
                        -- let's skip already implemented requirements --
                        if not ((equality (value, required) and not equality (structure[ identity (selector) ], nil))) then
                                structure[ identity (selector) ] = value
                        end
                end

                return token
        end

        function export.abstract (object)
                if decorator[ identity (object) ] then
                        return reflected[ decorator[ identity (object) ] ]

                elseif objective[ identity (object) ] then
                        return export.abstract (objective[ identity (object) ])

                else
                        return nil
                end
        end

        function export.activate (talent, object, scope, ...)
                local subject = nil

                if subjective[ identity (talent) ][ identity (object) ] then
                        subject = subjective[ identity (talent) ][ identity (object) ]

                else
                        local self = export.decorate (talent, object)

                        subject = selective.wrap (self)

                        objective[ subject ]                                 = self
                        subjective[ identity (talent) ][ identity (object) ] = subject
                end

                selective.enable (subject)

                local function procedure (...)
                        return scope (subject, ...)
                end

                local function handler (succeed, value, ...)
                        selective.disable (subject)

                        if succeed then
                                return value, ...

                        else
                                local reason = value: match (".+:%d+:%s(.+)")

                                return assert (succeed, reason)
                        end
                end

                return handler (pcall (procedure, ...))
        end

        talents = require 'talents.internals.token' (metatalent)

        return export
end

return functor
