local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )
		style.fontweight 	= 1
		common.elementopen(g, style, xml)
		style["text-align"] = "center"
	end,
	closed 		= function( g, style, xml )

		local geom 			= layout.getgeom()
		local element 		= layout.getelement(style.elementid)
		local obj 			= geom.get( element.gid )

		element.width 		= obj.width
		element.height 		= obj.height

		geom.renew( element.gid, element.pos.left, element.pos.top, element.width, element.height )

		common.elementclose(g, style, xml)
		style.fontweight = nil
	end,
}

----------------------------------------------------------------------------------