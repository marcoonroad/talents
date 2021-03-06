local assert       = assert
local coroutine    = coroutine
-- local debug        = debug
local error        = error
-- local ipairs       = ipairs
-- local load         = load
local require      = require
-- local pairs        = pairs
local pcall        = pcall
-- local setfenv      = setfenv
local setmetatable = setmetatable
-- local tostring     = tostring
-- local _VERSION     = _VERSION

local reason    = require 'talents.internals.reason'
local weak      = require 'talents.internals.weak'
local default   = require 'talents.internals.default'
-- local utilities = require 'talents.internals.utilities'
local memory    = require 'talents.internals.memory'

local bindings   = memory.bindings
local reflected  = memory.reflected
local decorator  = memory.decorator
local decorated  = memory.decorated
local delegated  = memory.delegated
local subjective = memory.subjective
local objective  = memory.objective
local injected   = memory.injected
local ownership  = memory.ownership

local function functor (external)
    local identity = external.identity or default.identity
    local iterator = external.iterator or default.iterator
    local equality = external.equality or default.equality
    local inspect  = external.inspect  or default.inspect

    local export     = { }
    local selective  = require 'talents.internals.selective' ( )
    local token      = require 'talents.internals.token' { }
    local talentID

    local required  = token.generate ( )
    local conflict  = token.generate ( )
    local exclusive = token.generate ( )

    local metaobject = require 'talents.internals.metatable.metaobject' {
        identity  = identity,
        iterator  = iterator,
        equality  = equality,
        inspect   = inspect,
        required  = required,
        exclusive = exclusive,
        conflict  = conflict,
    }

    local metatalent = require 'talents.internals.metatable.metatalent' (export)

     -- public definitions  --
    function export.required ( )
        return required
    end

	function export.exclusive ( )
		return exclusive
	end

    function export.requires (talent, selector)
        return equality (bindings[ identity (talent) ][ identity (selector) ],
            required)
    end

    function export.conflicts (talent, selector)
        return equality (bindings[ identity (talent) ][ identity (selector) ],
            conflict)
    end

    function export.excludes (talent, selector)
        return equality (bindings[ identity (talent) ][ identity (selector) ],
            exclusive)
    end

    function export.provides (talent, selector)
        local value = bindings[ identity (talent) ][ identity (selector) ]

        return not (equality (value, nil) or
            equality (value, required) or
            equality (value, exclusive) or
            equality (value, conflict))
    end

    function export.talent (structure)
        local ID = talentID.generate ( )

        local copy = { }

        for selector, value in iterator (structure) do
            copy[ identity (selector) ] = value
        end

        bindings[ ID ]    = copy
        reflected[ copy ] = ID
        subjective[ ID ]  = weak.key ( )

        return ID
    end

    function export.decorate (talent, object)
        local self = { }

        for selector, value in iterator (bindings[ identity (talent) ]) do
            if equality (value, conflict) then
                -- there is a unsolved conflict --
                error (reason.application.conflict (selector))

            elseif equality (value, required) and
                equality (object[ identity (selector) ], nil)
            then
                -- implemented selector is not implemented --
                error (reason.application.required (selector))

			elseif equality (value, exclusive) and
                equality (object[ identity (selector) ], nil)
            then
                -- exclusive selector is not provided --
				error (reason.application.exclusive (selector))

            else
                local class = inspect (value)

                if class == 'function' then
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
        ownership[ self ] = coroutine.running ( ) or true

        setmetatable (self, metaobject)

        return self
    end

    function export.compose (first, second)
        local structure = { }
        local ID        = talentID.generate ( )

        bindings[ ID ]         = structure
        reflected[ structure ] = ID
        subjective[ ID ]       = weak.key ( )

		-- shallow cloning --
        for selector, value in iterator (bindings[ identity (first) ]) do
            structure[ identity (selector) ] = value
        end

		-- composition algorithm --
        for selector, value in iterator (bindings[ identity (second) ]) do
            -- overrides required or not implemented --
            if equality (structure[ identity (selector) ], nil) or
                equality (structure[ identity (selector) ], required)
            then
                structure[ identity (selector) ] = value

			-- exclusive slots have greater priority --
			elseif equality (value, exclusive) then
				structure[ identity (selector) ] = value

			-- already implemented, but not [ required | same | exclusive ] --
            elseif (not equality (value, required)) and
                (not equality (value, exclusive)) and
                (not equality (structure[ identity (selector) ], value))
            then
                structure[ identity (selector) ] = conflict
            end
        end

        return ID
    end

    function export.extend (talent, extension)
        local structure = { }
        local ID        = talentID.generate ( )

        bindings[ ID ]         = structure
        reflected[ structure ] = ID
        subjective[ ID ]       = weak.key ( )

        for selector, value in iterator (bindings[ identity (talent) ]) do
            structure[ identity (selector) ] = value
        end

        for selector, value in iterator (extension) do
            -- let's skip already implemented requirements --
            if not ((equality (value, required) and
                not equality (structure[ identity (selector) ], nil)))
            then
                structure[ identity (selector) ] = value
            end
        end

        return ID
    end

    function export.abstract (object)
        if decorator[ identity (object) ] then
            return reflected[ decorator[ identity (object) ] ]

        elseif objective[ identity (object) ] then
            return export.abstract (objective[ identity (object) ])

        -- talent was collected/released --
        else
            return nil
        end
    end

    function export.activate (talent, object, scope, ...)
        local subject

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
                local message = value: match (".+:%d+:%s(.+)")

                return assert (succeed, message)
            end
        end

        return handler (pcall (procedure, ...))
    end

	function export.transfer (owned, thread)
		local class = type (thread)
		assert (class == 'thread' or class == 'nil',
            reason.transference.invalid ('thread or nil', class))

		local status = coroutine.status (thread)
		assert (status == 'suspended' or
		        status == 'normal',
		        reason.transference.coroutine (status))

		local owner   = ownership[ identity (owned) ]
		local current = coroutine.running ( ) or true

		if equality (owner, current) then
		    ownership[ identity (owned) ] = thread

		else
		    error (reason.transference.current ( ))
		end

        return owned
	end

    talentID = require 'talents.internals.token' (metatalent)

    return export
end

return functor

-- END --
