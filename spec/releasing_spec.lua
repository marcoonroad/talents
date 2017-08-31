require 'busted.runner' ( )

local talents = require 'talents'

describe ("talents releasing", function ( )
    it ("should be able to discard garbage collected talents", function ( )
        local emma

        do
            local writer = talents.talent {
                name = talents.required ( ),

                write = function (self)
                    return ("%s is writing a great book!"): format (self.name)
                end,
            }

            emma = talents.decorate (writer, { name = "Emma Goldman", })

            assert.same (emma.name, "Emma Goldman")
            assert.same (emma: write ( ),
                "Emma Goldman is writing a great book!")
        end

        collectgarbage ( )

        -- Emma Goldman is tired of writing, now it's time for Revolution! --
        assert.same (emma.name, "Emma Goldman")
        assert.same (emma.write, nil)
    end)

    it ("should be able to store and persist talents", function ( )
        local peter

        do
            local writer = talents.talent {
                name = talents.required ( ),

                think = function (self, thing)
                    return ("%s is taking some inspiration from %s..."):
                        format (self.name, thing)
                end,
            }

            -- store and persist the writer talent --
            peter = talents.decorate (writer, {
                name   = "Peter Kropotkin",
                talent = writer,
            })

            assert.same (peter.name, "Peter Kropotkin")
            assert.same (peter: think ("the nature"),
              "Peter Kropotkin is taking some inspiration from the nature...")
        end

        collectgarbage ( )

        -- Peter really likes to think a lot. --
        assert.same (peter.name, "Peter Kropotkin")
        assert.same (peter: think ("the cities"),
            "Peter Kropotkin is taking some inspiration from the cities...")
        assert.same (talents.abstract (peter), peter.talent)
    end)
end)

-- END --
