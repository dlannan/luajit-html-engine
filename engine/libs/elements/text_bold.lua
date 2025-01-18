local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )
		style.fontweight 	= 1
		common.elementopen(g, style, xml)
	end,
	closed 		= function( g, style, xml )
		common.elementclose(g, style, xml)
		style.fontweight = nil
	end,
}

----------------------------------------------------------------------------------