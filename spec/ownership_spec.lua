require 'busted.runner' ( )

local talents = require 'talents'
local reason  = require 'talents.internals.reason'
local example = require 'talents.example' (talents)

describe ("talent ownership,", function ( )
    it ("should be able to mutate the result object on the owner thread",
        function ( )
        local result = talents.decorate (
            example.talents.point2D,
            example.target.point2D
        )

        result: move (-7, 8)

        assert.equal (result.x, -7)
        assert.equal (result.y, 8)
    end)

    it ("should not be able to mutate the result object on a foreign thread",
    function ( )
        local result = talents.decorate (
            example.talents.point2D,
            example.target.point2D
        )

        local function procedure ( )
            local thread = coroutine.create (function ( )
                result: move (-7, 8)
            end)

            local succeed, message = coroutine.resume (thread)

            if not succeed then error (message: match (".+:%d+:%s(.+)")) end
        end

        assert.error (procedure, reason.ownership.violation ('x', -7))
    end)

    it ("should be able to transfer ownership for another thread", function ( )
        local main    = coroutine.running ( )
        local thread  = coroutine.create (function ( )
            local point = talents.decorate (
                example.talents.point2D,
                example.target.point2D
            )

            point: move (5, 7)

            assert.same (point.x, 5)
            assert.same (point.y, 7)

            return talents.transfer (point, main)
        end)

        local _, point = coroutine.resume (thread)

        point: move (-5, -7)

        assert.same (point.x, 0)
        assert.same (point.y, 0)

        assert.error (function ( )
            talents.transfer (point, thread)
        end, reason.transference.coroutine 'dead')

        assert.error (function ( )
            talents.transfer (point, "Hello, World!")
        end, reason.transference.invalid ('thread', 'string'))

        assert.error (function ( )
            local threadA

            threadA = coroutine.create (function ( )
                talents.transfer (point, threadA)
            end)

            local _, message = coroutine.resume (threadA)
            error (message: match ("[^:]+:%d+: (.*)"))
        end, reason.transference.coroutine 'running')

        assert.error (function ( )
            local threadA = coroutine.create (function ( ) end)

            local threadB = coroutine.create (function ( )
                talents.transfer (point, threadA)
            end)

            local _, message = coroutine.resume (threadB)
            error (message: match ("[^:]+:%d+: (.*)"))
        end, reason.transference.current ( ))
    end)
end)

-- END --
