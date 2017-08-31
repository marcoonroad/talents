local function functor (dependency)
    local export = { }

    function export.__tostring (_)
        return "[talent abstraction]"
    end

    function export: __call (structure, scope, ...)
        if scope then
            return dependency.activate (self, structure, scope, ...)

        else
            return dependency.decorate (self, structure)
        end
    end

    function export: __shr (structure)
        return dependency.extend (self, structure)
    end

    function export: __add (talent)
        return dependency.compose (self, talent)
    end

    export.__bor = export.__add

    return export
end

return functor

-- END --
