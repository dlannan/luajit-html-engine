local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")
local csscolors = require("engine.libs.styles.csscolors")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )
		style.color = csscolors.rgba_color("blue")
		common.elementopen(g, style, xml)
	end,
	closed 		= function( g, style, xml )
		common.elementclose(g, style, xml)
		style.color = nil
	end,
}

----------------------------------------------------------------------------------