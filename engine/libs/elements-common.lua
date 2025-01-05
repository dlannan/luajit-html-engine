local libstyle  	= require("engine.libs.elements-style")
local layout        = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

local function elementopen( g, style, attribs )

	local element 		= layout.addelement( g, style, attribs )
	style.elementid 	= element.id
	element.cursor_top 	= g.cursor.top
	--g.cursor.left = g.cursor.left + element.margin.left
	return element
end 

----------------------------------------------------------------------------------

local function elementclose( g, style )

	local element 		= layout.getelement(style.elementid)
	local geom 			= layout.getgeom()
	local dim 			= geom[element.gid]

	-- print(element.etype, dim.left, dim.top, dim.width, dim.height)
	geom.renew( element.gid, dim.left, dim.top, dim.width, dim.height )
end 


----------------------------------------------------------------------------------
-- 
local function textdefault( g, style, attribs, text )

	-- remove any newlines or tabs from text!
	text = string.gsub(text, "[\n\r\t]", "")
	
	style.etype = "text"
	libstyle.gettextsize(g, style, text) 
	local element 	= layout.addelement( g, style, attribs )	

	if(style.linesize < style.height) then style.linesize = style.height end 
	
	layout.addtextobject( g, style, text )	
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
    textdefault     = textdefault,
    defaultclose    = defaultclose,
    closenone       = closenone,

    stepline        = stepline,
    getlineheight   = getlineheight,
}

----------------------------------------------------------------------------------