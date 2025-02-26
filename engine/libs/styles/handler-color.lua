----------------------------------------------------------------------------------

local csscolors         = require("engine.libs.styles.csscolors")

----------------------------------------------------------------------------------

return {

    open_handler = function(g, style, xml)

        local color = style["color"]
        if(type(color) == "string") then 
            color = csscolors.rgba_color(color) or nil
        end
        -- Convert from various types to rgba in use in rapi
        style.color = color
    end 
}

----------------------------------------------------------------------------------
