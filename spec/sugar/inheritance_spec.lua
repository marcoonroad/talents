local talents = require 'talents'
local example = require 'talents.example' (talents)

describe ("talent inheritance with syntax sugar,", function ( )
        local plane = talents.talent {
                x = talents.required ( ),
                y = talents.required ( ),

                tostring = function (self)
                        local format = "(%d, %d)"

                        return format: format (self.x, self.y)
                end,

                is2D = function (self) return true end,
        }

        it ("should extend another talent", function ( )
                local spatial = talents.extend (plane, {
                        z = talents.required ( ),

                        tostring = function (self)
                                local format = "(%d, %d, %d)"

                                return format: format (self.x, self.y, self.z)
                        end,

                        is2D = function (self) return false end,
                        is3D = function (self) return true  end,
                })

                local point2D = plane { x = 1, y = 2, }
                local point3D = spatial { x = 1, y = 2, z = 3, }

                assert.equal (point2D: tostring ( ), "(1, 2)")
                assert.equal (point3D: tostring ( ), "(1, 2, 3)")

                assert.truthy (talents.provides (plane, 'is2D'))
                assert.truthy (talents.provides (plane, 'tostring'))
                assert.truthy (talents.requires (plane, 'x'))
                assert.truthy (talents.requires (plane, 'y'))
                assert.falsy  (talents.requires (plane, 'z'))

                assert.truthy (talents.provides (spatial, 'is2D'))
                assert.truthy (talents.provides (spatial, 'is3D'))
                assert.truthy (talents.provides (spatial, 'tostring'))
                assert.truthy (talents.requires (spatial, 'x'))
                assert.truthy (talents.requires (spatial, 'y'))
                assert.truthy (talents.requires (spatial, 'z'))
        end)

        it ("should not override when requiring some selector", function ( )
                local talent = talents.extend (plane, {
                        tostring = talents.required ( ),
                })

                assert.truthy (talents.requires (talent, 'x'))
                assert.truthy (talents.requires (talent, 'y'))
                assert.truthy (talents.provides (talent, 'tostring'))
                assert.truthy (talents.provides (talent, 'is2D'))
        end)

        it ("should not observe any direct effects from extension structure", function ( )
                local structure = { x = 0, }
                local parent    = talents.talent { }
                local talent    = talents.extend (parent, structure)

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
