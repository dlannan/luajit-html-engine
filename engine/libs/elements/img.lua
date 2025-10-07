local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")
local rapi 		= require("engine.libs.htmlrender-api")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )

		style.etype 		= "img"
		local attribs 		= xml.xarg
		if(attribs.width) then style.width = attribs.width end 
		if(attribs.height) then style.height = attribs.height end 
		if(attribs.src) then 
			style.src = attribs.src
			if(style.imgid == nil) then 
				style.imgid, twidth, theight = rapi.image_load(attribs.src) 
				if(style.width == 0 or style.width == nil) then style.width = twidth or 16 end
				if(style.height == 0 or style.height == nil) then style.height = theight or 16 end
			end
		end

		--checkmargins( g, style )
		style.display 		= style.display or "inline"
		
		local element 		= layout.addelement( g, style, xml.xarg )
		style.elementid 	= element.id
		xml.eid 			= element.id
		element.cursor_top 	= g.cursor.top

		layout.addimageobject( g, style )
	end,
	
	closed 		= function( g, style )	
		-- Push the size of the element into the button object
		local element 		= layout.getelement(style.elementid)
		local dim 			= layout.getelementdim(element.id)

		element.height 		= tonumber(style.height)
		--print(element.height)
		layout.updateelement(element.id, element)
		
		-- Return to leftmost + parent margin
		g.cursor.left 	= g.cursor.left + element.width
		g.cursor.element_left = g.cursor.left
		
		if(element.height > style.pstyle.linesize) then style.pstyle.linesize  = element.height end
	end,
}

----------------------------------------------------------------------------------