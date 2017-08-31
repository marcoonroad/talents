local require = require
local export  = { }
local weak    = require 'talents.internals.weak'

export.bindings   = weak.key ( )
export.reflected  = weak.pair ( )
export.decorator  = weak.pair ( )
export.decorated  = weak.key ( )
export.delegated  = weak.key ( )
export.subjective = weak.key ( )
export.objective  = weak.key ( )
export.injected   = weak.key ( )
export.ownership  = weak.key ( )

return export

-- END --
