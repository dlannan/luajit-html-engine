----------------------------------------------------------------------------------
-- Fix colors later (with css etc)

require("scripts.utils.copy")

local tinsert 	= table.insert
local tremove 	= table.remove

local tcolor 	= { r=0.0, b=1.0, g=0.0, a=1.0 }

local htmle = require("scripts.libs.htmlelements")
local htmlelements 	= htmle.elements 
local FONT_SIZES 	= htmle.FONT_SIZES

----------------------------------------------------------------------------------

local cursor = { top = 0.0, left = 0.0 }
local frame = { focussed = nil, top = 0.0, left = 0.0, width = 0.0, height = 0.0 }

----------------------------------------------------------------------------------

local styleempty = { 
	textsize = FONT_SIZES.p, 
	linesize = FONT_SIZES.p * 1.5, 
	maxlinesize = 0, 
	width = 0, 
	height = 0 
}

local stylestack = {}
stylestack[1] = deepcopy(styleempty)


----------------------------------------------------------------------------------
local function stylenone(  )
	return deepcopy(styleempty)
end 

----------------------------------------------------------------------------------
local function xmlhandler( ctx, xml )

	local currstyle = stylestack[#stylestack]
	local style = deepcopy(currstyle)

	if(style.margin == nil) then style.margin = htmle.defaultmargin(style) end
	if(style.padding == nil) then style.padding = htmle.defaultpadding(style) end
	if(style.border == nil) then style.border = htmle.defaultborder(style) end
	local g = { ctx=ctx, cursor = cursor, frame = frame }

	-- Check element names 
	local label = nil
	if( xml.label ) then label = string.lower(xml.label) end
	if(label) then 
		style.etype = label
		local iselement = htmlelements[label]	
		if(iselement) then 
			-- Assign parent
			style.pstyle = currstyle

			iselement.opened( g, style, xml.xarg ) 
		end
		tinsert(stylestack, style)
	end 

	if(style.dontprocess == nil) then 
		for k,v in pairs(xml) do 

			-- Might be a string index
			if(type(k) == "number") then
				if( type(v) == "string") then
					if(string.find(v, "DOCTYPE") == nil) then
						local tstyle = deepcopy(style)
						tstyle.pstyle = style
						tinsert(stylestack, tstyle)
						htmle.addtextobject( g, tstyle, xml.arg, v )
						tremove( stylestack ) 
					end
				end

				if(type(v) == "table") then
					xmlhandler( ctx, v ) 
				end
			end
		end
	end 

	-- Check label to close the element
	if(label) then 
		local iselement = htmlelements[xml.label]
		if(iselement and iselement.closed) then iselement.closed( g, style ) end 
		tremove( stylestack ) 
	end
end 

local start = false 

----------------------------------------------------------------------------------
local function renderxml( ctx, xmldoc, position )

	frame.top 		= position.top or 0.0
	frame.left 		= position.left or 0.0
	cursor.top 		= frame.top
	cursor.left 	= frame.left
	cursor.element_top = nil

	if(htmle.dirty) then
		htmle.init(frame, cursor)
		xmlhandler( ctx, xmldoc )
		htmle.dirty = nil
	end 
	htmle.finish()
end

----------------------------------------------------------------------------------
local function rendersize( x, y )

	frame.width, frame.height 		= x, y
end

----------------------------------------------------------------------------------

return { 
	renderxml = renderxml,
	rendersize = rendersize,
	stylenone = stylenone,
}

----------------------------------------------------------------------------------
