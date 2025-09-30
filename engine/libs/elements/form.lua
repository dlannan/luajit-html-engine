local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function (g, style, xml) 
		libstyle.styleinput(style)
		-- style.margin 		= libstyle.getmargin(style, libstyle.TEXT_CONST.NONE, 0)
		common.elementopen(g, style, xml)
	end, 
	closed 		= common.defaultclose,
}

----------------------------------------------------------------------------------