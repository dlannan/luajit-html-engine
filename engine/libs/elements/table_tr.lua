local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, attribs )

		libstyle.setmargins(style, 0, 0, 0, 0)
		libstyle.setpadding(style, 8, 0, 8, 0)
		
		common.elementopen(g, style, attribs)
	end,
	closed 		= function( g, style)

		-- Push the size of the element into the button object
		local element 		= layout.getelement(style.elementid)
		local geom 			= layout.getgeom()
		local obj 			= geom.get( element.gid )

		element.width 		= obj.width
		element.height 		= obj.height

		geom.renew( element.gid, element.pos.left, element.pos.top, element.width, element.height )

		if(element.height > style.pstyle.linesize) then style.pstyle.linesize  = element.height end		
		common.defaultclose(g, style)
	end,
}


----------------------------------------------------------------------------------