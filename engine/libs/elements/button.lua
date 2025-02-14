local common    	= require("engine.libs.elements-common")
local libstyle  	= require("engine.libs.elements-style")
local layout    	= require("engine.libs.htmllayout")

----------------------------------------------------------------------------------
local function elementbutton( g, style, xml )

	-- TODO: Need to make these default style settings for buttons

	-- Need to add check for css style
	libstyle.defaultbutton(style)

	-- A button is inserted as an "empty" div which is expanded as elements are added.
	local element = common.elementopen(g, style, xml)
	libstyle.applypadding( g, style, element )

	layout.addbuttonobject( g, style, xml.xargs )
end

----------------------------------------------------------------------------------
local function elementbuttonclose( g, style )
	
	-- Push the size of the element into the button object
	local element 		= layout.getelement(style.elementid)
	local obj 			= layout.getelementdim( element.id )

	element.width 		= obj.maxX - obj.minX
	element.height 		= obj.maxY - obj.minY

	libstyle.applyspacing( g, style, element )

	layout.updateelement(element.id, element)
	if(element.height > style.pstyle.linesize) then style.pstyle.linesize  = element.height end

	common.elementclose(g, style, xml)
end 

----------------------------------------------------------------------------------

return {
	opened 		= elementbutton,
	closed 		= elementbuttonclose,
}

----------------------------------------------------------------------------------