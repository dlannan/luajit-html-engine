local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )

		-- libstyle.setmargins(style, 0, 0, 0, 0)
		-- libstyle.setpadding(style, 8, 0, 8, 0)

		common.elementopen(g, style, xml)
	end,
	closed 		= function( g, style)

		-- Push the size of the element into the button object
		-- local element 		= layout.getelement(style.elementid)
		-- local obj 			= layout.getelementdim( element.id )

		-- element.width 		= obj.maxX - obj.minX
		-- element.height 		= obj.maxY - obj.minY

		-- layout.updateelement(element.id, element)
		
		-- if(element.height > style.pstyle.linesize) then style.pstyle.linesize  = element.height end		
		common.defaultclose(g, style)
	end,
}


----------------------------------------------------------------------------------