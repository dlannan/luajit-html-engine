local common    	= require("engine.libs.elements-common")
local libstyle  	= require("engine.libs.elements-style")
local layout    	= require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )
		style.display 		= style.display or "inline"
		common.textopened(g, style, xml)
	end,	
	closed 		= common.textclosed,
}

----------------------------------------------------------------------------------