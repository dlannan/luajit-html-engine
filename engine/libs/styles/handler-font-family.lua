local utils         = require("lua.utils")

----------------------------------------------------------------------------------

return {
    open_handler    = function(g, style, xml)

        -- Note: the loading for the family uses the normal css calls. Thus it should be in the font system
        local str           = style["font-family"]
        local faces         = utils.csplit(str, ",")
        style.fontface      = faces[1]:gsub("[\"']","")
    end,
}

----------------------------------------------------------------------------------
