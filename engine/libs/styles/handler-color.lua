----------------------------------------------------------------------------------

local csscolors         = require("engine.libs.styles.csscolors")

local lookupcolor		= {
	black 		= { r=0, g=0, b=0, a=255 },
    white 		= { r=255, g=255, b=255, a=255 },    
	red 		= { r=255, g=0, b=0, a=255 },
    green 		= { r=0, g=255, b=0, a=255 },
    blue 		= { r=0, g=0, b=255, a=255 },
    yellow 		= { r=255, g=255, b=0, a=255 },
}

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
