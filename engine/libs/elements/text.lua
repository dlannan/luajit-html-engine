local common    	= require("engine.libs.elements-common")
local libstyle  	= require("engine.libs.elements-style")
local layout    	= require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, attribs, xml )
		common.elementopen(g, style, attribs)
		common.textdefault( g, style, attribs, xml.xarg["text"] )
	end,
	closed 		= function( g, style )
		common.elementclose(g, style)
	end,
}

----------------------------------------------------------------------------------