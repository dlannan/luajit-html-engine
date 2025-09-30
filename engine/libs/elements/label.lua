local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )

		local attribs = xml.xarg
		-- style.margin 		= libstyle.getmargin(style, libstyle.TEXT_CONST.NONE, 0)
		style.textsize 		= libstyle.FONT_SIZES.p
		style.linesize 		= common.getlineheight(style)
		libstyle.checkmargins( g, style )
		common.elementopen(g, style, xml)
	end,
	closed 		= common.elementclose,
}

----------------------------------------------------------------------------------