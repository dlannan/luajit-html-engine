local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")
local rapi 		= require("engine.libs.htmlrender-api")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, attribs )

		style.etype 		= "img"

		if(attribs.width) then style.width = attribs.width end 
		if(attribs.height) then style.height = attribs.height end 
		if(attribs.src) then 
			style.src = attribs.src
			style.imgid = style.imgid or rapi.image_load(attribs.src) 
		end

		--checkmargins( g, style )
		
		local element 		= layout.addelement( g, style, attribs )
		layout.addimageobject( g, style )
	end,
	
	closed 		= function( g, style )	
		-- Push the size of the element into the button object
		local element 		= layout.getelement(style.elementid)
		local geom = layout.getgeom()
		geom.renew( element.gid, element.pos.left, element.pos.top, element.width, element.height )

		-- Return to leftmost + parent margin
		g.cursor.left 	= g.cursor.left + element.width
		g.cursor.element_left = g.cursor.left
		
		-- g.cursor.top 	= geom[ element.gid ].top
		if(element.height > style.pstyle.linesize) then style.pstyle.linesize  = element.height end
	end,
}

----------------------------------------------------------------------------------