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
		libstyle.setmargins(style, 0, 0, 0, 0)
		libstyle.setpadding(style, 8, 0, 8, 0)
		libstyle.setborders(style, 17, 5, 17, 5)

		-- Make a table stack. This stores rows that contain td widths for post update
		common.elementopen(g, style, xml)
	end,
	closed 		= function( g, style, xml)

	-- -- This is used for changes in layout - like tables and divs where styles and contraints might
	-- --   need to adjust the table based on specific criteria (like column sizes in tables)
	-- layout 		= function(g, xml)

		local geom 			= layout.getgeom()
		local element 		= layout.getelement(xml.eid)
		local geomobj 		= geom.get( element.gid )

		-- Calculate largest colums ( just iterate rowes and collect max width for each th/td )
		local cols = {}
		for k,v in pairs(xml) do
			if(type(k) == "number" and type(v) == "table") then
				local idx = 1
				for kc, vc in pairs(v) do 
					if(type(kc) == "number" and type(vc) == "table") then
						if(vc.eid) then 
							local childelement = layout.getelement(vc.eid)
							cols[idx] = cols[idx] or 0 
							if(childelement.width > cols[idx]) then cols[idx] = childelement.width end
							idx = idx + 1
						end
					end
				end
			end
		end

		-- Reset cursor to match this current table node position
		local cursor = { left = geomobj.left, top = geomobj.top }

		local function doelement( cursor, c, idx )
			local element 		= layout.getelement(c.eid)
			local dim 			= geom[element.gid]
			dim.width = cols[idx]
			element.width = cols[idx]
			geom.renew( element.gid, cursor.left, cursor.top, dim.width, dim.height )
			geom.update(element.gid)
			cursor.left 	= cursor.left + element.width
		end

		local function dotext( cursor, te, pe )

			local element 		= layout.getelement(te.eid)
			local render 		= layout.getrenderobj(te.eid)
			local dim 			= geom[element.gid]
			element.pos.left 	= cursor.left
			element.pos.top 	= cursor.top
			geom.renew( element.gid, cursor.left, cursor.top, dim.width, dim.height )
			geom.update(element.gid)
		end

		for k,v in pairs(xml) do
			if(type(k) == "number" and type(v) == "table") then
				local idx = 1
				local relement 		= layout.getelement(v.eid)
				for kc, vc in pairs(v) do 
					if(type(kc) == "number" and type(vc) == "table") then
						if(vc[1].label == "text") then 
							dotext( cursor, vc[1], vc ) 
						end
						doelement( cursor, vc, idx)
						idx = idx + 1
					end
				end
				cursor.left = geomobj.left
				cursor.top = cursor.top + xml.style.linesize
				-- common.stepline( { cursor = cursor, frame = xml.g.frame }, xml.style)
			end
		end

		local element 		= layout.getelement(xml.eid)
		local geom 			= layout.getgeom()
		local obj 			= geom.get( element.gid )

		element.width 		= obj.width
		element.height 		= obj.height

		geom.renew( element.gid, element.pos.left, element.pos.top, element.width, element.height )
		common.elementclose(g, style, xml)		
	end,
}

----------------------------------------------------------------------------------