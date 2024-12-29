----------------------------------------------------------------------------------

local tinsert 	= table.insert
local tremove 	= table.remove

require("scripts.utils.copy")
local GM 		= require("scripts.libs.htmlgeom")
local rapi 		= require("scripts.libs.htmlrender-api")

-- Set this to show the geom outlines. Doesnt support scrolling at the moment.
local enableDebug 			= 1
local enableDebugElements 	= nil

----------------------------------------------------------------------------------
-- A html render tree  -- created during first pass
local render 		= {}
-- A html layout tree  -- created during passing of render tree - this should be rasterised
local layout 		= {}

-- A mapping of elements - using id's. This allows for referential structuring so we can 
--   easily replicate operations on a dom using it.
local elements		= {}

local geom 			= nil

local tcolor = { r=0.0, b=0.0, g=0.0, a=1.0 }

----------------------------------------------------------------------------------

local child_flags = imgui.WINDOWFLAGS_NOTITLEBAR
child_flags = bit.bor(child_flags, imgui.WINDOWFLAGS_NOMOVE)
child_flags = bit.bor(child_flags, imgui.WINDOWFLAGS_NORESIZE)

----------------------------------------------------------------------------------

function table_print(tt, indent, done)
	done = done or {}
	indent = indent or 0
	if type(tt) == "table" then
		for key, value in pairs (tt) do
			io.write(string.rep (" ", indent)) -- indent it
			if type (value) == "table" and not done [value] then
				done [value] = true
				io.write(string.format("[%s] => table\n", tostring (key)));
				io.write(string.rep (" ", indent+4)) -- indent it
				io.write("(\n");
				table_print (value, indent + 7, done)
				io.write(string.rep (" ", indent+4)) -- indent it
				io.write(")\n");
			else
				io.write(string.format("[%s] => %s\n",
				tostring (key), tostring(value)))
			end
		end
	else
		io.write(tt .. "\n")
	end
end

----------------------------------------------------------------------------------

local function getparent( style )

	local pid = nil 
	if(style.pstyle and style.pstyle.elementid) then 
		local eid 			= elements[style.pstyle.elementid]
		if(eid) then 
			local pelement 	= geom[eid.gid]
			pid = pelement.gid or nil
		end
	end
	return pid
end 

----------------------------------------------------------------------------------

local function getgeometry( )

	return geom
end 

----------------------------------------------------------------------------------
local function getelement(eid)

	return elements[eid] or nil
end

----------------------------------------------------------------------------------

local function updateelement( eid, element )
	elements[eid] = element 
end
----------------------------------------------------------------------------------
-- TODO: this need to be changed to use element geometry instead of cursor.
local function rendertext( g, v )

	local text 		= v.text
	local style 	= v.style
	if(type(text) ~= "string") then return end 
	local ele = getelement( v.eid )

	-- This pushes a font!
	g.ctx.ctx.setstyle(style)
	rapi.set_cursor_pos(ele.pos.left, ele.pos.top)
	rapi.set_window_font_scale(style.textsize/g.ctx.ctx.fontsize)
	rapi.text( text, ele.width + g.cursor.left + g.frame.left )
	-- Always do this when using fontface
	g.ctx.ctx.unsetstyle()
end 

----------------------------------------------------------------------------------

local function renderbutton( g, v )

	local text 		= v.text
	local style 	= v.style
	local ele = getelement( v.eid )
	rapi.set_cursor_pos(ele.pos.left, ele.pos.top)
	imgui.begin_child(tostring(v.eid), ele.width, ele.height)
	g.ctx.ctx.setstyle(style)
	local changed, pressed = rapi.button(v.text or "", ele.width, ele.height )
	if changed then 
		-- self.counter = self.counter + 1
	end
	g.ctx.ctx.unsetstyle()
	imgui.end_child()
end 

----------------------------------------------------------------------------------

local function renderinputtext( g, v )

	local text 		= v.text
	local style 	= v.style
	local ele = getelement( v.eid )

	rapi.set_cursor_pos(ele.pos.left, ele.pos.top)
	imgui.begin_child(tostring(v.eid), ele.width, ele.height)
	g.ctx.ctx.setstyle(style)
	local changed, value = rapi.input_text( ele.attr.value or "", "Label" )
	if(changed) then 
		print(changed, value)
		ele.attr.value = value
	end
	g.ctx.ctx.unsetstyle()
	imgui.end_child()
end 

----------------------------------------------------------------------------------

local function renderimage( g, v )

	local text 		= v.text
	local style 	= v.style
	local ele = getelement( v.eid )

	rapi.set_cursor_pos(ele.pos.left, ele.pos.top)
	rapi.image_add( style.imgid, ele.width, ele.height ) 
end 

----------------------------------------------------------------------------------
local bgcolor		= { r=1, g=1, b=1, a=1 }
local brdrcolor 	= { r=0, g=0, b=0, a=1 }
local margincolor 	= { r=0, g=0, b=1, a=1 }

local function renderelement( g, ele ) 

	-- local ele = getelement( v.eid )
	-- g.gcairo:RenderBox( ele.pos.left, ele.pos.top, ele.width, ele.height, 0, bgcolor, brdrcolor )
	--print("TG:", tg.left, tg.top, tg.width, tg.height)
	rapi.draw_rect( ele.pos.left, ele.pos.top, ele.width, ele.height, 0x000033ff) -- , brdrcolor )

	g.ctx.ctx.setstyle(style)
	rapi.set_cursor_pos(tg.left, tg.top)
	rapi.set_window_font_scale( 0.5 )
	rapi.text( tostring(tg.gid) )
	g.ctx.ctx.unsetstyle()
end	

local function rendergeom( g, tg ) 

	-- local ele = getelement( v.eid )
	-- g.gcairo:RenderBox( ele.pos.left, ele.pos.top, ele.width, ele.height, 0, bgcolor, brdrcolor )
	-- print("TG:", tg.gid, tg.left, tg.top, tg.width, tg.height)
	local posx, posy = tg.left + g.ctx.ctx.window.x, tg.top + g.ctx.ctx.window.y
	rapi.draw_rect( posx, posy, tg.width, tg.height, 0xffff0000) -- , brdrcolor )
	--g.gcairo:RenderText( tostring(tg.gid), tg.left, tg.top, 16, tcolor )
end	
----------------------------------------------------------------------------------

local function dolayout( )

end

----------------------------------------------------------------------------------

local function doraster( )

	for k, v in ipairs( render ) do 

		local g = { ctx = v.ctx, cursor=v.cursor, frame = v.frame }
		if( v.etype == "inputtext" ) then 
			renderinputtext(g, v)
		end 
		if( v.etype == "button" ) then 
			renderbutton(g, v)
		end 
		if( v.etype == "text" ) then 
			rendertext(g, v)
		end
		if( v.etype == "img" ) then 
			renderimage(g, v)
		end
	end

	if( enableDebug ) then 

		if( enableDebugElements ) then 
			-- Just dump all the element layouts as boxes
			for k, v in pairs( elements ) do 

				local g = { ctx = v.ctx, cursor=v.cursor, frame = v.frame }
				-- Render a box around all elements 
				renderelement( g, v)
			end 
		end 

		local ele = elements[1]
		local html = geom.geometries[1]
		local g = { ctx = ele.ctx, cursor=ele.cursor, frame = ele.frame }
		for k, v in ipairs(geom.geometries) do 
			rendergeom( g, v )
		end
	end
	-- geom.dump()
end

----------------------------------------------------------------------------------
-- Gen new geom layout every frame?!! (for now - this will be cached later)
geom 		= GM.create(frame, cursor)

local function init(frame, cursor) 
	render 		= {}
	layout 		= {}
	elements 	= {}
	geom.clear()
end 

local function finish() 

	-- Dump the layout tree 
	-- table_print(render)
	
	-- upon completion of building render tree, run layout pass 
	dolayout()
	doraster()
end

----------------------------------------------------------------------------------
-- Try to replicate css properties here. 
local function addelement( g, style, attribs )

	local element = {}
	element.ctx 		= g
	element.etype 		= style.etype
	element.border 		= { width = 0, height = 0 }
	element.background 	= { color = style.background or "#aaaaaa" }
	element.margin 		= { top = style.margin.top or 0, bottom = style.margin.bottom or 0, left = style.margin.left or 0, right = style.margin.right or 0 }
	element.pos 		= { top = g.cursor.top, left = g.cursor.left }
	element.width 		= tonumber(style.width or 0)
	element.height 		= tonumber(style.height or 0)
	element.id 			= #elements + 1

	if(attribs) then 
		element.attr = deepcopy(attribs) 
		if(attribs.width and tonumber(attribs.width) > element.width) then element.width = tonumber(attribs.width) end
		if(attribs.height and tonumber(attribs.height) > element.height) then element.height = tonumber(attribs.height) end
	end 

	local pid = getparent(style)
	element.gid 		= geom.add( style.etype, pid, 
				element.pos.left, 
				element.pos.top, 
				element.width, 
				element.height )
	geom.update( element.gid )
	
	style.elementid 	= element.id
	tinsert(elements, element)
	return element
end 

----------------------------------------------------------------------------------

local function addtextobject( g, style, text )

	local stylecopy = deepcopy(style)

	-- Try to treat _all_ output as text + style. Style here means a css objects type
	--    like border, background, size, margin etc
	local renderobj = { 
		ctx 	= g,
		etype 	= style.etype,
		eid 	= style.elementid,
		style 	= stylecopy, 
		text 	= text,
		cursor 	= { top = g.cursor.top, left = g.cursor.left },
		frame  	= { top = g.frame.top, left = g.frame.left },
	}

	local pid = getparent(style)
	-- if(pid) then print(text, style.width, pid, style.pstyle.etype) end
	renderobj.gid 		= geom.add( style.etype, pid, g.cursor.left, g.cursor.top, style.width, style.height )
	geom.update( renderobj.gid )
		
	-- Render objects are queued in order of the output data with the correct styles
	tinsert(render, renderobj)
end 


----------------------------------------------------------------------------------
-- Button objects when created are empty and only margin sized.
local function addbuttonobject( g, style, attribs )

	local stylecopy = deepcopy(style)
	
	-- Try to treat _all_ output as text + style. Style here means a css objects type
	--    like border, background, size, margin etc
	local renderobj = { 
		ctx 	= g, 
		etype 	= "button",
		eid 	= style.elementid,
		style 	= stylecopy, 
		cursor 	= { top = g.cursor.top, left = g.cursor.left },
		frame  	= { top = g.frame.top, left = g.frame.left },
	}

	-- Input buttons already have text if set in value 
	if( style.etype == "input" and attribs.value ) then 
		renderobj.text = attribs.value
	end
	
	local pid = getparent(style)
	renderobj.gid 		= geom.add( style.etype, pid, g.cursor.left, g.cursor.top, style.width, style.height )
	geom.update( renderobj.gid )
	
	-- Render obejcts are queued in order of the output data with the correct styles
	tinsert(render, renderobj)
end 


----------------------------------------------------------------------------------
-- Input text objects when created are a minimum size and filled during render
local function addinputtextobject( g, style, attribs )

	local stylecopy = deepcopy(style)

	-- Try to treat _all_ output as text + style. Style here means a css objects type
	--    like border, background, size, margin etc
	local renderobj = { 
		ctx 	= g, 
		etype 	= "inputtext",
		eid 	= style.elementid,
		style 	= stylecopy, 
		cursor 	= { top = g.cursor.top, left = g.cursor.left },
		frame  	= { top = g.frame.top, left = g.frame.left },
	}
	
	local pid = getparent(style)
	renderobj.gid 		= geom.add( renderobj.etype, pid, g.cursor.left, g.cursor.top, style.width, style.height )
	geom.update( renderobj.gid )

	-- Render obejcts are queued in order of the output data with the correct styles
	tinsert(render, renderobj)
end 

----------------------------------------------------------------------------------

local function addimageobject( g, style )

	local stylecopy = deepcopy(style)

	-- Try to treat _all_ output as text + style. Style here means a css objects type
	--    like border, background, size, margin etc
	local renderobj = { 
		ctx 	= g, 
		etype 	= style.etype,
		eid 	= style.elementid,
		style 	= stylecopy, 
		cursor 	= { top = g.cursor.top, left = g.cursor.left },
		frame  	= { top = g.frame.top, left = g.frame.left },
	}

	local pid = getparent(style)
	renderobj.gid 		= geom.add( style.etype, pid, g.cursor.left, g.cursor.top, style.width, style.height )
	geom.update( renderobj.gid )

	-- Render obejcts are queued in order of the output data with the correct styles
	tinsert(render, renderobj)
end 
----------------------------------------------------------------------------------

local function addlayout( layout )

	local layoutobj = deepcopy(layout)
	tinsert(layout, layoutobj)
end 

----------------------------------------------------------------------------------

return {

	init 			= init,
	finish 			= finish,

	addelement		= addelement,
	getelement		= getelement,
	updateelement	= updateelement,
	
	addtextobject 	= addtextobject,
	addbuttonobject	= addbuttonobject,
	addinputtextobject = addinputtextobject,
	addimageobject	= addimageobject,
	
	addlayout 		= addlayout,

	getgeom 		= getgeometry,
}

----------------------------------------------------------------------------------
