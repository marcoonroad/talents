local talents = require 'talents'

describe ("talent definition,", function ( )
        it ("should not observe any direct effects from passed structure", function ( )
                local structure = { x = 0, }
                local talent    = talents.talent (structure)

                assert.truthy (talents.provides (talent, "x"))
                assert.falsy  (talents.requires (talent, "y"))
                assert.falsy  (talents.provides (talent, "move"))

                structure.y = talents.required ( )

                assert.truthy (talents.provides (talent, "x"))
                assert.falsy  (talents.requires (talent, "y"))

                function structure: move (x, y)
                        self.x = self.x + x
                        self.y = self.y + y
                end

                assert.truthy (talents.provides (talent, "x"))
                assert.falsy  (talents.requires (talent, "y"))
                assert.falsy  (talents.provides (talent, "move"))

                structure.x = nil

                assert.truthy (talents.provides (talent, "x"))
                assert.falsy  (talents.requires (talent, "y"))
                assert.falsy  (talents.provides (talent, "move"))
        end)
end)
