----------------------------------------------------------------------------------

local csscolors         = require("engine.libs.styles.csscolors")
local utils             = require("lua.utils")

----------------------------------------------------------------------------------

return {

    open_handler = function(g, style, xml)

        local color = style["background-color"]
        if(type(color) == "string") then 
            color = csscolors.rgba_color(color) or nil
        end
        -- Convert from various types to rgba in use in rapi
        style["background-color"] = color
        print("TYPE:", style.etype)
    end 
}

----------------------------------------------------------------------------------
