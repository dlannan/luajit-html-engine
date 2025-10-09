local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )
		style.fontweight 	= 1
		-- style.display = style.display or "table"
		common.elementopen(g, style, xml)
		-- style["text-align"] = "center"
	end,
	closed 		= function( g, style, xml )

		-- local element 		= layout.getelement(style.elementid)
		-- local obj 			= layout.getelementdim( element.id )

		-- element.width 		= obj.maxX - obj.minX
		-- element.height 		= obj.maxY - obj.minY

		-- layout.updateelement(element.id, element)

		-- common.elementclose(g, style, xml)
		style.fontweight = nil
	end,
}

----------------------------------------------------------------------------------