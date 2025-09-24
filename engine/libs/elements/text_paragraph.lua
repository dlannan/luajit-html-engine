local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml)
        -- TODO: default paragraph styles needed
		style.textsize 	= libstyle.FONT_SIZES.p
		style.margin.left =  style.margin.left + 1.5 * style.textsize
		style.linesize 	= style.textsize
        if(style.pstyle) then 
            style.width = g.frame.width 
        end        
		-- libstyle.checkmargins( g, style )
		common.elementopen(g, style, xml)
	end,
	closed 		= function( g, style, xml)
		style.margin.left =  style.pstyle.margin.left
		common.defaultclose( g, style )
	end,
}

----------------------------------------------------------------------------------