local libstyle  	= require("engine.libs.elements-style")
local layout        = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

local function elementopen( g, style, xml )

	libstyle.open(g, style, xml)
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
	libstyle.gettextsize(g, style, text ) 
	local element 	= elementopen( g, style, xml )	

	if(style.linesize < style.height) then style.linesize = style.height end 
	
	layout.addtextobject( g, style, text )	
	-- if parent is th, then check alignment or if style.text_align is set 
	-- elementclose(g, style)
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
	g.cursor.left 	= g.frame.left
	g.cursor.element_left = g.cursor.left
end 

----------------------------------------------------------------------------------
-- Default close always end the line of elements back to the leftmost start position
local function defaultclose( g, style )
	
	elementclose(g, style)	
	stepline(g, style)
end	

local function closenone( g, style )

end	

----------------------------------------------------------------------------------

return {
    elementopen     = elementopen,
    elementclose    = elementclose,
    textopened     	= textopened,
	textclosed 		= textclosed,
    defaultclose    = defaultclose,
    closenone       = closenone,

    stepline        = stepline,
    getlineheight   = getlineheight,
}

----------------------------------------------------------------------------------