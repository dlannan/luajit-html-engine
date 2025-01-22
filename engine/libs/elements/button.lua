local common    	= require("engine.libs.elements-common")
local libstyle  	= require("engine.libs.elements-style")
local layout    	= require("engine.libs.htmllayout")

----------------------------------------------------------------------------------
local function elementbutton( g, style, xml )

	-- TODO: Need to make these default style settings for buttons

	-- A button is inserted as an "empty" div which is expanded as elements are added.
	common.elementopen(g, style, xml)
	-- Need to add check for css style
	libstyle.setmargins(style, 0, 0, 0, 0)
	libstyle.setpadding(style, 8, 10, 8, 10)
	libstyle.setborders(style, 17, 5, 17, 5)
	
	layout.addbuttonobject( g, style, xml.xargs )
end

----------------------------------------------------------------------------------
local function elementbuttonclose( g, style )
	
	-- Push the size of the element into the button object
	local element 		= layout.getelement(style.elementid)
	local geom 			= layout.getgeom()
	local obj 			= geom.get( element.gid )

	element.width 		= obj.width
	element.height 		= obj.height

	geom.renew( element.gid, element.pos.left, element.pos.top, element.width, element.height )

	if(element.height > style.pstyle.linesize) then style.pstyle.linesize  = element.height end
end 

----------------------------------------------------------------------------------

return {
	opened 		= elementbutton,
	closed 		= elementbuttonclose,
}

----------------------------------------------------------------------------------