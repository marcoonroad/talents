local talents = require 'talents'
local reason  = require 'talents.internals.reason'
local example = require 'talents.example' (talents)

describe ("talent contextual activation,", function ( )
        it ("should provide a scoped application", function ( )
                local function scope (self)
                        return self: inspect ( )
                end

                local label = talents.activate (example.talents.labeled, example.target.point, scope)

                assert.equal (label, "@point2D")
        end)

        it ("should provide a scoped application with arguments", function ( )
                local function scope (self, is)
                        return is (self: inspect ( ), "@point2D")
                end

                talents.activate (example.talents.labeled, example.target.point, scope, assert.equal)
        end)

        it ("should fail when using leaked contextual/subjective element", function ( )
                local function scope (self)
                        return self
                end

                local function procedure ( )
                        local subject = talents.activate (example.talents.labeled, example.target.point, scope)

                        subject: inspect ( )
                end

                assert.error (procedure, reason.disabled)
        end)

        it ("should fail on subject leaking regardless exceptional failures", function ( )
                local subject = nil

                local function scope (self)
                        subject = self

                        error ("I trying to bypass the framework invariants!")
                end

                xpcall (function ( )
                        talents.activate (example.talents.labeled, example.target.point, scope)
                end, function (reason)
                        -- ignore the exception --
                end)

                local function procedure ( )
                        return subject: inspect ( )
                end

                assert.error (procedure, reason.disabled)
        end)

        it ("should generate the same identity for contextual activation", function ( )
                local function first (self)
                        return self
                end

                local subject = talents.activate (example.talents.labeled, example.target.point, first)

                local function second (self, is, reference)
                        return is (self, reference)
                end

                talents.activate (example.talents.labeled, example.target.point, second, assert.equal, subject)
        end)

        it ("should fail when contextually accessing a not required neither provided property", function ( )
                local talent = talents.talent {
                        move = function (self, x, y)
                                self.x = self.x + x -- [x] isn't provided neither required --
                                self.y = self.y + y -- the same applies for [y] as well... --
                        end,
                }

                local function scope (self, x, y)
                        self: move (x, y)
                end

                local point = { x = 5, y = 12, }

                local function procedure ( )
                        return talents.activate (talent, point, scope, 7, 14)
                end

                assert.error (procedure, reason.violation ('x'))
        end)
end)

