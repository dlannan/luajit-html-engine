----------------------------------------------------------------------------------

local tinsert 	= table.insert
local tremove 	= table.remove

require("engine.utils.copy")
local rapi 		= require("engine.libs.htmlrender-api")
local csscolors = require("engine.libs.styles.csscolors")

local utils 	= require("lua.utils")

local events 	= require("projects.browser.events")
local ltreelib 	= require("engine.utils.layouttree")

-- Set this to show the geom outlines. Doesnt support scrolling at the moment.
local enableDebug 			= nil
local enableDebugElements 	= nil

----------------------------------------------------------------------------------
-- A html render tree  -- created during first pass
local render 		= {}
local render_lookup = {}

-- A html layout tree  -- created during passing of render tree - this should be rasterised
local layout 		= {}

-- A mapping of elements - using id's. This allows for referential structuring so we can 
--   easily replicate operations on a dom using it.
-- This is a list not a table, because we want the insertion order (i think?)
local elements		= {}

-- Helpers for fast hash lookups (works well up to about 50-100K elements)
local element_nodes = {} -- ltree node lookups by element id
local element_ids 	= {} -- element data from element id itself.

-- A table stack for currently processing tables
local tables		= {}

--local geom 			= nil
local ltree 		= ltreelib.new()

local tcolor = { r=0.0, b=0.0, g=0.0, a=1.0 }

----------------------------------------------------------------------------------
-- Resset everything

function reset() 
	render 			= {}
	render_lookup 	= {}
	-- layout 			= {}
	elements		= {}
	element_nodes 	= {} -- ltree node lookups by element id
	-- element_ids 	= {} -- element data from element id itself.
	-- tables			= {}
	ltree 			= ltreelib.new()
	tcolor = { r=0.0, b=0.0, g=0.0, a=1.0 }
end	

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
		pid = element_ids[style.pstyle.elementid].id
	end
	return pid
end 

----------------------------------------------------------------------------------

local function getgeometry( )

	return ltree
end 

----------------------------------------------------------------------------------

local function getrenderobj( eid )
	local rid = render_lookup[eid] or nil
	return render[rid] or nil
end

----------------------------------------------------------------------------------
local function getelement(eid)

	return element_ids[eid] or nil
end

----------------------------------------------------------------------------------

local function getelementdim(eid)
	local node = element_nodes[eid]
	if(node == nil) then return nil end
	return node.aabb
end

----------------------------------------------------------------------------------

local function updateelement( eid, element )
	-- Need to propagate the update to parents in tree
	local node = element_nodes[eid]
	local newaabb = ltreelib.createAABB(
		element.pos.left, 
		element.pos.top, 
		element.pos.left + element.width,  
		element.pos.top + element.height
	)
	ltree:update(node, newaabb)
end

----------------------------------------------------------------------------------
-- TODO: this need to be changed to use element geometry instead of cursor.
local function rendertext( g, v )

	local text 		= v.text
	local style 	= v.style

	if(type(text) ~= "string") then return end 

	local ele 	= getelement( v.eid )
-- if(text == "Company") then print(v.etype, v.eid) end

	-- This pushes a font!
	g.ctx.ctx.setstyle(style)
	rapi.set_cursor_pos(ele.pos.left, ele.pos.top)
	rapi.set_window_font_scale(style.textsize/g.ctx.ctx.fontsize)
	rapi.set_text_color(style["color"])
	local underline = bit.band(style.fontstyle or 0, 2) == 2
	local strikethrough = bit.band(style.fontstyle or 0, 4) == 4
	rapi.text( text, ele.width + g.frame.left, style["text-align"], underline, strikethrough )
	-- Always do this when using fontface
	g.ctx.ctx.unsetstyle()
end 

----------------------------------------------------------------------------------

local function renderbutton( g, v )

	local text 		= v.text
	local style 	= v.style
	local cnr 		= style["border-radius"] or 0
	local ele = getelement( v.eid )
	rapi.set_cursor_pos(ele.pos.left, ele.pos.top)
	-- imgui.begin_child(tostring(v.eid), ele.width, ele.height)
	g.ctx.ctx.setstyle(style)
	local color = csscolors.buttoncolor
	local changed, pressed = rapi.button(v.text or "", ele.width, ele.height, color, cnr )
	if changed then 
		-- self.counter = self.counter + 1
	end
	g.ctx.ctx.unsetstyle()
	-- imgui.end_child()
end 

----------------------------------------------------------------------------------

local function renderinputtext( g, v )

	local text 		= v.text
	local style 	= v.style
	local cnr 		= style["border-radius"] or 0
	local ele = getelement( v.eid )

	rapi.set_cursor_pos(ele.pos.left, ele.pos.top)
	-- imgui.begin_child(tostring(v.eid), ele.width, ele.height)
	g.ctx.ctx.setstyle(style)
	local color = style.color or { r = 0.0, g = 0.0, b = 0.0, a = 1.0 }
	local changed, value = rapi.input_text( ele.attr.value or "",  ele.width, ele.height, color, cnr )
	if(changed) then 
		-- print(changed, value)
		ele.attr.value = value
	end
	g.ctx.ctx.unsetstyle()
	-- imgui.end_child()
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

local function renderrectfilled( g, v)
	local ele = getelement( v.eid )
	local geomobj = element_nodes[ele.id].aabb
	local posx, posy =  geomobj.minX + g.ctx.ctx.window.x,  geomobj.minY + g.ctx.ctx.window.y
	local width, height = geomobj.maxX - geomobj.minX, geomobj.maxY - geomobj.minY
	rapi.draw_rect_filled( posx, posy, width, height, v.bgcolor)
end

----------------------------------------------------------------------------------
local bgcolor		= { r=1, g=1, b=1, a=1 }
local brdrcolor 	= { r=0, g=0, b=0, a=1 }
local margincolor 	= { r=0, g=0, b=1, a=1 }
local debugrender 	= { r=0, g=0.2, b=1, a=1 }

local function renderelement( g, ele ) 

	-- local ele = getelement( v.eid )
	-- g.gcairo:RenderBox( ele.pos.left, ele.pos.top, ele.width, ele.height, 0, bgcolor, brdrcolor )
	--print("TG:", tg.left, tg.top, tg.width, tg.height)
	rapi.draw_rect( ele.pos.left, ele.pos.top, ele.width, ele.height, debugrender) -- , brdrcolor )

	-- g.ctx.ctx.setstyle(style)
	-- rapi.set_cursor_pos(tg.left, tg.top)
	-- rapi.set_window_font_scale( 0.5 )
	-- rapi.text( tostring(tg.gid) )
	-- g.ctx.ctx.unsetstyle()
end	

----------------------------------------------------------------------------------

local function rendergeom( node, g ) 

	-- local ele = getelement( v.eid )
	-- g.gcairo:RenderBox( ele.pos.left, ele.pos.top, ele.width, ele.height, 0, bgcolor, brdrcolor )
	-- print("TG:", tg.gid, tg.left, tg.top, tg.width, tg.height)
	local posx, posy = node.aabb.minX + g.ctx.ctx.window.x, node.aabb.minY + g.ctx.ctx.window.y
	local width, height = node.aabb.maxX - node.aabb.minX, node.aabb.maxY - node.aabb.minY
	rapi.draw_rect( posx, posy, width, height, 0xffff0000) -- , brdrcolor )
	--g.gcairo:RenderText( tostring(tg.gid), tg.left, tg.top, 16, tcolor )
end	

----------------------------------------------------------------------------------

local function doraster( )

	if(utils.tcount(elements) == 0) then return end

	-- Process backgrounds first - this will need to be z-index ordered at some stage
	local g = { ctx = elements[1].ctx, cursor=elements[1].cursor, frame = elements[1].frame }
	for k, v in ipairs( render ) do 
		if(v.bgcolor) then 
			-- print(v.etype, v.bgcolor.r, v.bgcolor.g, v.bgcolor.b, v.width, v.height)
			if(v.etype ~= "p") then renderrectfilled(g, v) end
		end
	end

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

		local g = { ctx = elements[1].ctx, cursor=elements[1].cursor, frame = elements[1].frame }
		ltreelib.traverse( ltree.root, rendergeom, nil, g)
	end
end

-- --------------------------------------------------------------------------------------

function MouseMoved(ev) 

	--print(ev.pos.x, ev.pos.y)
	local results = ltree:queryPoint(ev.pos.x - layout.frame.left, ev.pos.y- layout.frame.top)
	--print("Results: ", #results)
end

-- --------------------------------------------------------------------------------------

local function init(frame, cursor) 

	layout 		= {
		frame 	= frame,
		cursor 	= cursor,
	}

	rapi.window.x 	= frame.left
	rapi.window.y 	= frame.top

	-- These are now all generated during load of xml objects. 
	--   New objects can be added at runtime too!
	-- render 		= {}
	-- elements 	= {}
	-- geom.clear()

	-- add some simple responders for events 
	events.clear_responders()
	events.add_responder( sg.SAPP_EVENTTYPE_MOUSE_MOVE, MouseMoved )
end 

-- --------------------------------------------------------------------------------------

local function drawall() 

	-- Dump the layout tree 
	-- table_print(render)
	
	-- upon completion of building render tree, run layout pass 
	doraster()
end

----------------------------------------------------------------------------------

local function addaabbnode( element, style )
	local zindex 		= style["z-index"] or 1

	local left 		= element.pos.left
	local top  		= element.pos.top
	local right 	= left + element.width
	local bottom 	= top + element.height
	
	local newaabb 	= ltreelib.createAABB(left, top, right, bottom)
	local node 		= ltreelib.createNode(newaabb, element, zindex)
	local parent 	= element_nodes[element.pid]
	ltree:add( node, parent )
	element_nodes[element.id] = node
end	

----------------------------------------------------------------------------------
-- Try to replicate css properties here. 
local function addelement( g, style, attribs )

	local element = {}
	element.ctx 		= g
	element.etype 		= style.etype
	element.background 	= { color = style.background or "#aaaaaa" }
	element.margin 		= { top = style.margin.top or 0, bottom = style.margin.bottom or 0, left = style.margin.left or 0, right = style.margin.right or 0 }
	element.padding		= { top = style.padding.top or 0, bottom = style.padding.bottom or 0, left = style.padding.left or 0, right = style.padding.right or 0 }
	element.border		= { top = style.border.top or 0, bottom = style.border.bottom or 0, left = style.border.left or 0, right = style.border.right or 0 }
	element.pos 		= { top = g.cursor.top, left = g.cursor.left }
	element.width 		= tonumber(style.width or 0)
	element.height 		= tonumber(style.height or 0)
	element.id 			= #elements + 1
	element.pid 		= getparent(style)

	if(attribs) then 
		element.attr = deepcopy(attribs) 
		if(attribs.width and tonumber(attribs.width) > element.width) then element.width = tonumber(attribs.width) end
		if(attribs.height and tonumber(attribs.height) > element.height) then element.height = tonumber(attribs.height) end
	end 

	addaabbnode(element, style)
	style.elementid 			= element.id
	tinsert(elements, element)
	element_ids[element.id] 	= element
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
	
	--addaabbnode(element_ids[renderobj.eid], stylecopy)

	-- Render objects are queued in order of the output data with the correct styles
	tinsert(render, renderobj)
	render_lookup[renderobj.eid] = #render
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
	
	-- Render obejcts are queued in order of the output data with the correct styles
	tinsert(render, renderobj)
	render_lookup[renderobj.eid] = #render
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
		text 	= attribs.value,
	}

	-- Render obejcts are queued in order of the output data with the correct styles
	tinsert(render, renderobj)
	render_lookup[renderobj.eid] = #render
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

	-- Render obejcts are queued in order of the output data with the correct styles
	tinsert(render, renderobj)
	render_lookup[renderobj.eid] = #render
end 


----------------------------------------------------------------------------------

local function addbackground( g, style, xml )

	local robj = render[render_lookup[style.elementid]]
	-- If element already has been added to geom, then just set its bgcolor)
	if(robj) then 
		robj.bgcolor = style["background-color"]
	else
		local stylecopy = deepcopy(style)

		-- Try to treat _all_ output as text + style. Style here means a css objects type
		--    like border, background, size, margin etc
		local renderobj = { 
			ctx 	= g, 
			etype 	= style.etype,
			eid 	= style.elementid,
			style 	= stylecopy, 
			bgcolor = style["background-color"],
			cursor 	= { top = g.cursor.top, left = g.cursor.left },
			frame  	= { top = g.frame.top, left = g.frame.left },
		}

		-- Render obejcts are queued in order of the output data with the correct styles
		tinsert(render, renderobj)
		render_lookup[renderobj.eid] = #render
	end
end 

----------------------------------------------------------------------------------

local function addlayout( layout )

	local layoutobj = deepcopy(layout)
	tinsert(layout, layoutobj)
end 

----------------------------------------------------------------------------------

local function ltreeprint() 
	ltree:print()
end

----------------------------------------------------------------------------------

return {

	init 			= init,
	drawall 		= drawall,
	reset 			= reset,

	getrenderobj 	= getrenderobj,

	addelement		= addelement,
	getelement		= getelement,
	getelementdim 	= getelementdim,
	updateelement	= updateelement,
	
	addtextobject 	= addtextobject,
	addbuttonobject	= addbuttonobject,
	addinputtextobject = addinputtextobject,
	addimageobject	= addimageobject,
	addbackground	= addbackground,

	addtablecolumn	= addtablecolumn,
	addtablerow 	= addtablerow,

	addlayout 		= addlayout,
	ltreeprint		= ltreeprint,

	getgeom 		= getgeometry,
	getparent 		= getparent,
}

----------------------------------------------------------------------------------
