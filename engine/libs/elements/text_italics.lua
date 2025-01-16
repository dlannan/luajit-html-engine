local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )
		style.fontstyle 	= 1
		common.elementopen(g, style, xml)
	end,
	closed 		= function( g, style )	
		common.elementclose(g, style)
		style.fontstyle = nil
	end,
}

----------------------------------------------------------------------------------