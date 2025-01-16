local common    	= require("engine.libs.elements-common")
local libstyle  	= require("engine.libs.elements-style")
local layout    	= require("engine.libs.htmllayout")

local utils 		= require("lua.utils")

----------------------------------------------------------------------------------
-- Table is a bit of a complex one. 
--   Setup some states so that this table instance, can collect its head, body and 
--   rows within the body. On close it can then provide correct initial layout and 
--   position and sizes

-- default table style width expands to only the size of the maximum text in the rows.
-- default table height is lineheight x rows + head

-- It looks like this will operate almost like a div. All that needs to happen is
--   rows height needs to be populated through the rows.
--   and td & th widths need to be recalculated based on the biggest for each column
--      which can be stored anyway.

local stored_g = {}

return {
	opened 		= function( g, style, attribs )
		-- Make a table stack. This stores rows that contain td widths for post update
		common.elementopen(g, style, attribs)
		stored_g[style.elementid] = { 
			cursor = { left = g.cursor.left, top = g.cursor.top }, 
			frame = { left = g.frame.left, top = g.frame.top, width = g.frame.width, height = g.frame.height },
		}
	end,
	closed 		= function( g, style, tablenode)

		local geom = layout.getgeom()
		-- -- print(utils.tdump(tablenode))

		-- -- -- Calculate largest colums ( just iterate rowes and collect max width for each th/td )
		-- local cols = {}
		-- for i,v in ipairs(tablenode.children) do
		-- 	for idx, c in ipairs(v.children) do 
		-- 		local element = layout.getelement(c.eid)
		-- 		cols[idx] = cols[idx] or 0 
		-- 		if(element.width > cols[idx]) then cols[idx] = element.width end
		-- 	end
		-- end

		-- local local_g = stored_g[style.elementid]
		-- local cursor = local_g.cursor
		-- local startleft = cursor.left

		-- local function doelement( cursor, c, idx )
		-- 	local element 		= layout.getelement(c.eid)
		-- 	local dim 			= geom[element.gid]
		-- 	dim.width = cols[idx]
		-- 	element.width = cols[idx]
		-- 	geom.renew( element.gid, cursor.left, cursor.top, dim.width, dim.height )
		-- 	geom.update(element.gid)
		-- 	cursor.left 	= cursor.left + element.width
		-- end

		-- local function dotext( cursor, te )
		-- 	local element 		= layout.getelement(te.eid)
		-- 	local render 		= layout.getrenderobj(te.eid)
		-- 	local dim 			= geom[element.gid]
		-- 	element.pos.left 	= cursor.left 
		-- 	element.pos.top 	= cursor.top
		-- 	geom.renew( element.gid, cursor.left, cursor.top, dim.width, dim.height )
		-- 	geom.update(element.gid)
		-- 	-- render.cursor.left 	= cursor.left 
		-- 	-- render.cursor.top 	= cursor.top
		-- end

		-- for i,v in ipairs(tablenode.children) do
		-- 	local relement 		= layout.getelement(v.eid)
		-- 	for idx, c in ipairs(v.children) do 
		-- 		if(c.children) then dotext( cursor, c.children[1] ) end
		-- 		doelement( cursor, c, idx)
		-- 	end
		-- 	common.stepline( { cursor = cursor, frame = local_g.frame }, style)
		-- end

		local element 		= layout.getelement(style.elementid)
		local obj 			= geom.get( element.gid )

		element.width 		= obj.width
		element.height 		= obj.height
		g.cursor.top = g.cursor.top + obj.height / 2

		geom.renew( element.gid, element.pos.left, element.pos.top, element.width, element.height )
		common.elementclose(g, style)
	end,
}

----------------------------------------------------------------------------------