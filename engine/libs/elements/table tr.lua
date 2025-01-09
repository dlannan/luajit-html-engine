local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return  {
	opened 		= function (g, style, attribs) 
		style.margin 		= libstyle.getmargin(style, libstyle.TEXT_CONST.NONE, 0)
		style.pstyle.linesize = common.getlineheight(style)
		common.elementopen(g, style, attribs)
	end,
	closed 		= function( g, style )
		-- Update table dimensions	
		common.elementclose(g, style)
	end,
}

----------------------------------------------------------------------------------