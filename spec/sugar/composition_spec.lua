local talents = require 'talents'
local weak    = require 'talents.internals.weak'
local reason  = require 'talents.internals.reason'
local example = require 'talents.example' (talents)

describe ("talent composition with syntax sugar,", function ( )
        it ("should merge both talents", function ( )
                local talent = example.talents.observer + example.talents.observable

                assert.truthy (talents.requires (talent, 'react'))
                assert.truthy (talents.requires (talent, 'observers'))
                assert.truthy (talents.provides (talent, 'register'))
                assert.truthy (talents.provides (talent, 'unregister'))
                assert.truthy (talents.provides (talent, 'notify'))
        end)

        it ("should merge without conflicts if definitions are identical", function ( )
                local talent = example.talents.observable + example.talents.observable

                assert.truthy (talents.requires (talent, 'observers'))
                assert.truthy (talents.provides (talent, 'register'))
                assert.truthy (talents.provides (talent, 'unregister'))
                assert.truthy (talents.provides (talent, 'notify'))
        end)

        it ("should not care about the order of arguments", function ( )
                local list = {
                        example.talents.observer   + example.talents.observable,
                        example.talents.observable + example.talents.observer,
                }

                for index = 1, #list do
                        talent = list[ index ]

                        assert.truthy (talents.requires (talent, 'react'))
                        assert.truthy (talents.requires (talent, 'observers'))
                        assert.truthy (talents.provides (talent, 'register'))
                        assert.truthy (talents.provides (talent, 'unregister'))
                        assert.truthy (talents.provides (talent, 'notify'))
                end
        end)

        it ("may contain some conflicts", function ( )
                local talent = example.talents.observable + example.talents.event

                assert.truthy (talents.requires (talent, 'observers'))
                assert.truthy (talents.provides (talent, 'register'))
                assert.truthy (talents.provides (talent, 'unregister'))
                assert.truthy (talents.conflicts (talent, 'notify'))
        end)

        it ("should fail for non implemented requirements cases", function ( )
                local function procedure ( )
                        local _ = example.talents.observer { }
                end

                assert.error (procedure, reason.required ('react'))
        end)

        it ("should fail for existent conflicts", function ( )
                local function procedure ( )
                        local talent = example.talents.event + example.talents.observable
                        local _      = talent { observers = weak.key ( ), }
                end

                assert.error (procedure, reason.conflict ('notify'))
        end)

        it ("may have conflicts ignored through override with talent inheritance", function ( )
                local supertalent = example.talents.event + example.talents.observable

                local subtalent = talents.extend (supertalent, {
                        notify = function (self, event)
                                error ("I don't know what to do, but I want to throw away these conflicts for now.")
                        end,
                })

                local result = subtalent { observers = weak.key ( ), }

                assert (talents.provides (subtalent, 'notify'))
        end)
end)
