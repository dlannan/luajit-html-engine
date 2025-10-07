local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )
		local ml, mr = style.margin.left, style.margin.right
		-- style.margin 		= libstyle.getmargin(style, libstyle.TEXT_CONST.NONE, 0)
		style.pstyle.linesize = common.getlineheight(style)

		libstyle.newlinebox(g, style, xml)
	end,
	closed 		= function( g, style, xml)
		common.defaultclose( g, style )
	end,
}

----------------------------------------------------------------------------------