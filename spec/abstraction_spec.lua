local talents = require 'talents'
local example = require 'talents.example' (talents)

describe ("talent abstraction,", function ( )
        local astolph = {
                name     = "Astolph",
                health   = 120,
                mana     = 348,
                class    = "Rat",
                job      = "Dragon/Devil Slayer",
                strength = 67,
                critical = 0.7,
                label    = "hero",
        }

        it ("should extract a talent from an object", function ( )
                local yeggor = {
                        name     = "Yeggor",
                        class    = "Dragon",
                        job      = "The Dark Lord",
                        strength = 1920,
                        mana     = 5000,
                        health   = 6200,
                        critical = 0.95,
                        label    = "enemy",
                }

                local hero   = talents.decorate (example.talents.labeled, astolph)
                local talent = talents.abstract (hero)
                local enemy  = talents.decorate (talent, yeggor)

                assert.equal (talent, example.talents.labeled)
                assert.equal (talent, talents.abstract (enemy))
        end)

        it ("should also work on contextual talent application", function ( )
                local talent = talents.activate (example.talents.labeled, astolph, talents.abstract)

                assert.equal (talent, example.talents.labeled)
        end)
end)

