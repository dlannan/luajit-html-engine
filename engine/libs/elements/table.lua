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
	opened 		= function( g, style, xml )

		-- Need to add check for css style
		-- libstyle.setmargins(style, 0, 0, 0, 0)
		-- libstyle.setpadding(style, 8, 0, 8, 0)
		-- libstyle.setborders(style, 17, 5, 17, 5)
		-- libstyle.checkmargins( g, style )

		-- Make a table stack. This stores rows that contain td widths for post update
		-- style.display = style.display or "table"
		common.elementopen(g, style, xml)

	end,
	closed 		= function( g, style, xml)

	-- -- This is used for changes in layout - like tables and divs where styles and contraints might
	-- --   need to adjust the table based on specific criteria (like column sizes in tables)
	-- -- TODO: There is surely a nicer way to handle this in the layout manager

	-- 	local telement 		= layout.getelement(xml.eid)
	-- 	local geomobj 		= layout.getelementdim( telement.id )

	-- 	-- Calculate largest colums ( just iterate rowes and collect max width for each th/td )
	-- 	local cols = {}
	-- 	for k,v in pairs(xml) do
	-- 		if(type(k) == "number" and type(v) == "table") then
	-- 			local idx = 1
	-- 			for kc, vc in pairs(v) do 
	-- 				if(type(kc) == "number" and type(vc) == "table") then
	-- 					if(vc.eid) then 
	-- 						local childelement = layout.getelement(vc.eid)
	-- 						cols[idx] = cols[idx] or 0 
	-- 						if(childelement.width > cols[idx]) then cols[idx] = childelement.width end
	-- 						idx = idx + 1
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end

	-- 	-- Reset cursor to match this current table node position (top left)
	-- 	g.cursor = { left = telement.pos.left, top = telement.pos.top }

	-- 	local function doelement( cursor, c, idx )
	-- 		local element 		= layout.getelement(c.eid)
	-- 		local dim 			= layout.getelementdim( element.id )

	-- 		element.width 		= cols[idx]
	-- 		element.pos.left 	= cursor.left
	-- 		element.pos.top 	= cursor.top
			
	-- 		layout.updateelement(element.id, element)
	-- 		return cols[idx]
	-- 	end

	-- 	local function dotext( cursor, te, pe, idx )

	-- 		local element 		= layout.getelement(te.eid)
	-- 		local dim 			= layout.getelementdim( element.id )

	-- 		local off 			= 0
	-- 		local pelement 		= layout.getelement(pe.eid)
	-- 		if(pelement.etype == "th") then 
	-- 			off = cols[idx]/2 - (dim.maxX - dim.minX)/2
	-- 		end

	-- 		element.pos.left 	= cursor.left + off
	-- 		element.pos.top 	= cursor.top
	-- 		layout.updateelement(element.id, element)
	-- 	end

	-- 	local height = g.cursor.top
	-- 	for k,v in pairs(xml) do
	-- 		if(type(k) == "number" and type(v) == "table") then
	-- 			local idx = 1
	-- 			--local relement 		= layout.getelement(v.eid)
	-- 			for kc, vc in pairs(v) do 
	-- 				if(type(kc) == "number" and type(vc) == "table") then
	-- 					local width = doelement( g.cursor, vc, idx)
	-- 					if(vc[1] and vc[1].label == "text") then 
	-- 						dotext( g.cursor, vc[1], vc, idx ) 
	-- 					end
	-- 					idx = idx + 1
	-- 					g.cursor.left 	= g.cursor.left + width
	-- 				end
	-- 			end

	-- 			-- cursor.top = cursor.top + xml.style.linesize end
	-- 			common.stepline( g, xml.style)
	-- 		end
	-- 	end

		common.elementclose(g, style, xml)		
	end,
}

----------------------------------------------------------------------------------