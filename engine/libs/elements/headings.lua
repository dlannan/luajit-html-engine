
local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

local function headingopen( g, style, attribs )

	style.textsize 	= libstyle.FONT_SIZES[string.lower(style.etype)]
	style.margin 	= libstyle.getmargin(style, libstyle.TEXT_CONST.HEADINGS, 0)
	style.linesize 	= common.getlineheight(style)
	style.fontweight = 1

	libstyle.checkmargins( g, style )
	common.elementopen(g, style, attribs)
end	

----------------------------------------------------------------------------------

return {
	opened 		= headingopen,
	closed 		= common.defaultclose,
}

----------------------------------------------------------------------------------