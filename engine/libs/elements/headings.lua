
local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

local function headingopen( g, style, xml )

	style.textsize 	= libstyle.FONT_SIZES[string.lower(style.etype)]
	style.margin 	= libstyle.getmargin(style, libstyle.TEXT_CONST.HEADINGS, 0)
	style.linesize 	= common.getlineheight(style)
	style.fontweight = 1

	-- style.display = "inline"

	libstyle.checkmargins( g, style )
	common.elementopen(g, style, xml)
end	

----------------------------------------------------------------------------------

return {
	opened 		= headingopen,
	closed 		= function( g, style, xml )
		style.margin 		= libstyle.defaultmargin(style)
		common.defaultclose(g, style, xml)
	end,
}

----------------------------------------------------------------------------------