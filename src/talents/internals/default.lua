local export = { }

-- when overridden, a proxy might assume the --
-- identity of its respective target object. --
function export.identity (value)
        return value
end

-- client can provide a custom discrimination --
-- of objects coming from external framework. --
export.equality = rawequal
export.inspect  = type
export.iterator = pairs

return export
