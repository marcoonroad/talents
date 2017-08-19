require 'busted.runner' ( )

local talents = require 'talents'
local reason  = require 'talents.internals.reason'
local example = require 'talents.example' (talents)

describe ("talent ownership with syntax sugar,", function ( )
    it ("should be able to mutate the result object on the owner thread",
    function ( )
        local result = example.talents.point2D (example.target.point2D)

        result: move (-7, 8)

        assert.equal (result.x, -7)
        assert.equal (result.y, 8)
    end)

    it ("should not be able to mutate the result object on a foreign thread",
    function ( )
        local result = example.talents.point2D (example.target.point2D)

        local function procedure ( )
            local thread = coroutine.create (function ( )
                result: move (-7, 8)
            end)

            local succeed, message = coroutine.resume (thread)

            if not succeed then error (message: match (".+:%d+:%s(.+)")) end
        end

        assert.error (procedure, reason.ownership.violation ('x', -7))
    end)
end)

-- END --
