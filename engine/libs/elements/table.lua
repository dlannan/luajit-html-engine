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
return {
	opened 		= function( g, style, attribs )
		-- Make a table stack. This stores rows that contain td widths for post update
		common.elementopen(g, style, attribs)
	end,
	closed 		= function( g, style)

		local geom = layout.getgeom()
		-- local tablenode = htmldom.getelement(style.elementid)
		-- -- print(utils.tdump(tablenode))

		-- -- Calculate largest colums ( just iterate rowes and collect max width for each th/td )
		-- local cols = {}
		-- for i,v in ipairs(tablenode.children) do
		-- 	for idx, c in ipairs(v.children) do 
		-- 		local element = layout.getelement(c.eid)
		-- 		cols[idx] = cols[idx] or 0 
		-- 		if(element.width > cols[idx]) then cols[idx] = element.width end
		-- 	end
		-- end

		-- for i,v in ipairs(tablenode.children) do
		-- 	for idx, c in ipairs(v.children) do 
		-- 		local element 		= layout.getelement(c.eid)
		-- 		local dim 			= geom.get( element.gid )
		-- 		dim.width = cols[idx]
		-- 	end
		-- end

		-- htmldom.refreshnodes( tablenode )
		--layout.recalctable(g, style)

		local element 		= layout.getelement(style.elementid)
		local geom 			= layout.getgeom()
		local obj 			= geom.get( element.gid )

		element.width 		= obj.width
		element.height 		= obj.height

		geom.renew( element.gid, element.pos.left, element.pos.top, element.width, element.height )
		common.defaultclose(g, style)
	end,
}

----------------------------------------------------------------------------------