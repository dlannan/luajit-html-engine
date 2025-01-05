local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, attribs )
		style.fontweight 	= 1
		common.elementopen(g, style, attribs)
	end,
	closed 		= function( g, style )
		common.elementclose(g, style)
		style.fontweight = nil
	end,
}

----------------------------------------------------------------------------------