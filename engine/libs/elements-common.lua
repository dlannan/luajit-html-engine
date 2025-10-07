local libstyle  	= require("engine.libs.elements-style")
local layout        = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

local function elementopen( g, style, xml )

	libstyle.open(g, style, xml)
	libstyle.handle_display(g, style, xml)	

	local element 		= layout.addelement( g, style, xml.xarg )
	
    -- style.peid          = style.elementid
	style.elementid 	= element.id
	xml.eid 			= element.id
	element.cursor_top 	= g.cursor.top

	return element
end 

----------------------------------------------------------------------------------

local function elementclose( g, style, xml )

	libstyle.close(g, style, xml)
	if(style["background-color"]) then 
		layout.addbackground( g, style, xml )
	end
end 

----------------------------------------------------------------------------------
-- 
local function textopened( g, style, xml )

	-- remove any newlines or tabs from text!
	local text = xml.xarg["text"] or ""
	text = string.gsub(text, "[\n\r\t]", "")
	
	style.etype = "text"
	text = libstyle.getformatted(g, style, text )
	libstyle.gettextsize(g, style, text ) 
	local element 	= elementopen( g, style, xml )	

	if(style.linesize < style.height) then style.linesize = style.height end 
	
	layout.addtextobject( g, style, text )		
end

----------------------------------------------------------------------------------

local function textclosed(g, style, xml)

	g.cursor.left 	= g.cursor.left + style.width 
	elementclose(g, style)

	if(style.height + style.margin.bottom > style.pstyle.linesize) then 
		style.pstyle.linesize  = style.height
		g.cursor.element_top = g.cursor.top + style.height 
	end	
end 

----------------------------------------------------------------------------------

local function textnone( g, style, text )

end 

----------------------------------------------------------------------------------

local function getlineheight( style ) 

	local lh =  style.textsize
	if(style.height > lh) then lh = style.height end 
	return lh
end

----------------------------------------------------------------------------------

local function stepline( g, style )
	-- Step a line
	--style = style or libstyle.defaultstyle

	g.cursor.top 	= g.cursor.top + style.linesize
	-- Add in the collated margin from the bottom
	g.cursor.element_top = g.cursor.top
	g.cursor.top 	= g.cursor.top + style.margin.bottom

	-- Return to leftmost + parent margin
	g.cursor.left 	= g.frame.left + style.margin.left
	g.cursor.element_left = g.cursor.left
end 

----------------------------------------------------------------------------------
-- Default close always end the line of elements back to the leftmost start position
local function defaultclose( g, style )
	
	elementclose(g, style)	
	--stepline(g, style)
end	

----------------------------------------------------------------------------------

local function closenone( g, style )

end	

----------------------------------------------------------------------------------
local function elementbutton( g, style, xml )

	-- TODO: Need to make these default style settings for buttons

	-- Need to add check for css style
	libstyle.defaultbutton(style)

	-- A button is inserted as an "empty" div which is expanded as elements are added.
	local element = elementopen(g, style, xml)
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

	elementclose(g, style, xml)
end 

----------------------------------------------------------------------------------

return {
    elementopen     	= elementopen,
    elementclose    	= elementclose,
	elementbutton 		= elementbutton,
	elementbuttonclose 	= elementbuttonclose,
    textopened     		= textopened,
	textclosed 			= textclosed,
    defaultclose    	= defaultclose,
    closenone       	= closenone,

    stepline        	= stepline,
    getlineheight   	= getlineheight,
}

----------------------------------------------------------------------------------