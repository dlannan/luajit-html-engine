local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )
		style.fontstyle 	= bit.bor(style.fontstyle or 0, 2)
		style.display 		= style.display or "inline"
		common.elementopen(g, style, xml)
	end,
	closed 		= function( g, style, xml)
		style.margin.left =  style.pstyle.margin.left
		common.elementclose(g, style, xml)
		style.fontstyle = nil
	end,
}

----------------------------------------------------------------------------------