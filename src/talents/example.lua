local function functor (talents)
        local export = { }

        export.talents = { }
        export.target  = { }

        export.talents.point2D = talents.talent {
                x = talents.required ( ),
                y = talents.required ( ),

                move = function (self, x, y)
                        self.x = self.x + x
                        self.y = self.y + y
                end,

                clear = function (self)
                        self.x = 0
                        self.y = 0
                end,
        }

        export.talents.point3D = talents.extend (export.talents.point2D, {
                z = talents.required ( ),

                move = function (self, x, y, z)
                        self: super (x, y)

                        self.z = self.z + z
                end,

                clear = function (self)
                        self.x = 0
                        self.y = 0
                        self.z = 0
                end,
        })

        export.talents.labeled = talents.talent {
                label = talents.required ( ),

                inspect = function (self)
                        local format = "@%s"

                        return format: format (self.label)
                end,
        }

        export.target.point = { x = 0, y = 0, label = "point2D", }

        export.target.point2D = { x = 0, y = 0, }

        export.talents.observer = talents.talent {
                react = talents.required ( ),
        }

        export.talents.observable = talents.talent {
                observers = talents.required ( ),

                register = function (self, observer)
                        self.observers[ observer ] = true
                end,

                unregister = function (self, observer)
                        self.observers[ observer ] = nil
                end,

                notify = function (self, event)
                        collectgarbage ('stop')

                        for observer in pairs (self.observers) do
                                observer: react (self, event)
                        end

                        collectgarbage ('restart')
                end,
        }

        export.talents.event = talents.talent {
                notify = function (self, observable)
                        observable: notify (self)
                end,
        }

        return export
end

return functor
