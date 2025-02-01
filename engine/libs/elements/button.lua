local common    	= require("engine.libs.elements-common")
local libstyle  	= require("engine.libs.elements-style")
local layout    	= require("engine.libs.htmllayout")

----------------------------------------------------------------------------------
local function elementbutton( g, style, xml )

	-- TODO: Need to make these default style settings for buttons

	-- Need to add check for css style
	libstyle.setmargins(style, 0, 0, 0, 0)
	libstyle.setpadding(style, 8, 10, 8, 10)
	libstyle.setborders(style, 17, 5, 17, 5)

	-- A button is inserted as an "empty" div which is expanded as elements are added.
	common.elementopen(g, style, xml)

	layout.addbuttonobject( g, style, xml.xargs )
end

----------------------------------------------------------------------------------
local function elementbuttonclose( g, style )
	
	-- Push the size of the element into the button object
	local element 		= layout.getelement(style.elementid)
	local obj 			= layout.getelementdim( element.id )

	element.width 		= obj.maxX - obj.minX
	element.height 		= obj.maxY - obj.minY
print("button: ", element.width, element.height)
	layout.updateelement(element.id, element)
	if(element.height > style.pstyle.linesize) then style.pstyle.linesize  = element.height end
end 

----------------------------------------------------------------------------------

return {
	opened 		= elementbutton,
	closed 		= elementbuttonclose,
}

----------------------------------------------------------------------------------