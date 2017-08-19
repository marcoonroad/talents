require 'busted.runner' ( )

local talents = require 'talents'
local reason  = require 'talents.internals.reason'
local example = require 'talents.example' (talents)

describe ("talent application,", function ( )
    it ("should decorate given object", function ( )
        local object = talents.decorate (
            example.talents.labeled,
            example.target.point
        )

        local label = object: inspect ( )

        assert.equal (label, "@point2D")
    end)

    it ("should fail due non-implemented requirements", function ( )
        local function procedure ( )
            return talents.decorate (
                example.talents.labeled,
                { x = 0, y = 0 }
            )
        end

        assert.error (procedure, reason.application.required 'label')
    end)

    it ("should generate different proxies for the same application",
    function ( )
        local first = talents.decorate (
            example.talents.labeled,
            example.target.point
        )

        local second = talents.decorate (
            example.talents.labeled,
            example.target.point
        )

        assert.falsy (rawequal (first, second))
    end)

    it ("should not cause effects on target object", function ( )
        local point     = { x = 0, y = 0, label = "point2D" }
        local decorated = talents.decorate (
            example.talents.labeled,
            point
        )

        assert.equal (point.x, decorated.x)
        assert.equal (point.y, decorated.y)

        decorated.x = 12

        assert.falsy (rawequal (point.x, decorated.x))
        assert.truthy (rawequal (point.y, decorated.y))
    end)

    it ("may observe effects from the target object", function ( )
        local point     = { x = 0, y = 0, label = "point2D" }
        local decorated = talents.decorate (example.talents.labeled, point)

        assert.equal (point.x, decorated.x)
        assert.equal (point.y, decorated.y)

        point.x = 12

        assert.equal (point.x, decorated.x)
        assert.equal (point.y, decorated.y)
    end)

    it ("should preserve common delegation semantics in the wild",
    function ( )
        local point     = { x = 0, y = 0, label = "point2D" }
        local decorated = talents.decorate (example.talents.labeled, point)

        assert.equal (point.x, decorated.x)

        decorated.x = 12
        assert.falsy (rawequal (point.x, decorated.x))

        point.x = 12
        assert.equal (point.x, decorated.x)

        decorated.x = 5
        assert.falsy (rawequal (point.x, decorated.x))

        -- nil will trigger the lookup on parent, in --
        -- the case, in the associated target object --
        decorated.x = nil
        assert.equal (point.x, decorated.x)
    end)

    it ("should fail when accessing a not required neither provided property",
    function ( )
        local talent = talents.talent {
            move = function (self, x, y)
                self.x = self.x + x -- [x] isn't provided neither required --
                self.y = self.y + y -- the same applies for [y] as well... --
            end,
        }

        local point = talents.decorate (talent, { x = 5, y = 12, })

        local function procedure ( )
            point: move (7, 14)
        end

        assert.error (procedure, reason.application.violation ('x'))
    end)

    it ("should preserve metatable invariants except __newindex",
    function ( )
        local metatable = { }
        local missing   = "The property [%s] was not implemented!"
        local final     =
            "This object is not extensible, can't add [%s] property!"

        local function point (x, y)
            return setmetatable ({ x = x, y = y, label = "point2D" },
                metatable)
        end

        function metatable: __add (that)
            return point (self.x + that.x, self.y + that.y)
        end

        function metatable: __tostring ( )
            local format = "(%d, %d)"

            return format: format (self.x, self.y)
        end

        function metatable.__index (_, selector)
            error (missing: format (tostring (selector)))
        end

        function metatable.__newindex (_, selector, _)
            error (final: format (tostring (selector)))
        end

        local object = talents.decorate (
            example.talents.labeled,
            point (2, 5)
        )

        local function missed ( )
            return object.inexistent
        end

        assert.error (missed, missing: format ('inexistent'))

        object.extension = "[Anything can be put here...]"

        local sum = object + object

        assert.equal (tostring (object), "(2, 5)")
        assert.equal (tostring (sum), "(4, 10)")

        assert.equal (talents.abstract (object), example.talents.labeled)
        assert.equal (talents.abstract (sum), nil)
    end)
end)

-- END --
