local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, attribs)
        -- TODO: default paragraph styles needed
		style.textsize 	= libstyle.FONT_SIZES.p
		style.margin 	= libstyle.getmargin(style, libstyle.TEXT_CONST.MARGINS, 2)
		style.linesize 	= style.textsize
		libstyle.checkmargins( g, style )
		common.elementopen(g, style, attribs)
	end,
	closed 		= common.defaultclose,
}

----------------------------------------------------------------------------------