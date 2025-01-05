local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, attribs )
		style.margin 		= libstyle.getmargin(style, libstyle.TEXT_CONST.NONE, 0)
		style.pstyle.linesize = common.getlineheight(style)
	end,
	closed 		= common.defaultclose,
}

----------------------------------------------------------------------------------