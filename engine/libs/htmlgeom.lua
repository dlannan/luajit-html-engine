-- htmlgeom is the html geometry object used to generate element/cell information for layout_changed
-----------------------------------------------------------------------------------------------------------------------------------

local tinsert 		= table.insert 
local tremove 		= table.remove 

local MAX_WIDTH 	= 999999
local MAX_HEIGHT 	= 999999

-----------------------------------------------------------------------------------------------------------------------------------

local function printgeom( g )
	print("GID: ", g.gid, "PID:", g.pid, "LTWH", g.left, g.top, g.width, g.height)
end

-----------------------------------------------------------------------------------------------------------------------------------

local function updategeom( pg, tg )

	pg.left 	= tg.left 
	pg.top 		= tg.top
	pg.width 	= tg.width
	pg.height	= tg.height
	pg.right 	= tg.left + tg.width
	pg.bottom 	= tg.top + tg.height
end

-----------------------------------------------------------------------------------------------------------------------------------
local function mergegeom( tg, g )

	-- Dont merge self.. silly..
	if(g.gid == tg.gid) then return end 
	-- print("Merging ", g.gid, "  into ", tg.gid)
	-- printgeom(g) 
	-- printgeom(tg)

	local minleft = math.min(g.left, tg.left)
	local maxleft = math.max(g.left + g.width, tg.left + tg.width)
	local mintop = math.min( g.top, tg.top)
	local maxtop = math.max( g.top + g.height, tg.top + tg.height)

	tg.left = minleft 
	tg.width = maxleft - minleft 
	tg.top = mintop 
	tg.height = maxtop - mintop
	
	tg.right = tg.left + tg.width 
	tg.bottom = tg.top + tg.height
	return tg 
end 

-----------------------------------------------------------------------------------------------------------------------------------

local geommanager 	= {}
local ppath 		= ""

geommanager.create 	= function( frame, cursor )

	-- The geom object you will work with
	local geom 				= {}
	
	-- All the geometries 
	geom.geometries 		= {}
	geom.geomid 			= 0

	geom.frame 				= frame 
	geom.cursor 			= cursor

	geom.get = function( geomid )
		if(geomid == nil) then return nil end -- silent fail check returns!
		local g = geom.geometries[geomid] or nil 
		return g
	end 
	
	geom.checkgeomchanges = function(pg, g )

		-- Only check first level children (we assume they are done, or will be done later)
		for k,v in ipairs(pg.childs) do 
			mergegeom( pg, geom.geometries[v] )
		end 
		mergegeom( pg, g )
	end 
	
	
	geom.traverseup = function ( g ) 

		if( g.pid ) then 
			local pg = geom.geometries[g.pid] or nil 
			if(pg == nil) then return end 

			-- Update parent if bounds of the child geom impact it
			geom.checkgeomchanges( pg, g )
			-- ppath = ppath..pg.gid.."-->"
			geom.traverseup(pg)
		else 
			-- print(ppath.."\n")
			-- ppath = ""
		end 
	end 

	geom.addchildtoparent = function( newgeom )

		if(newgeom.pid) then 
			local pg = geom.geometries[newgeom.pid] or nil 
			if(pg) then 
				tinsert(pg.childs, newgeom.gid)
			end
		end 
	end	
	
	-- Add a new geometry. If name is empty it will be generated, and if parent is empty then it is a root geom
	--   All other params will default to 0 if not set
	geom.add 	= function( name, parentid, left, top, width, height )

		geom.geomid 	= geom.geomid + 1
		if(name == nil) then name = "geom_"..geom.geomid end

		left 	= left or geom.frame.left
		top 	= top or geom.frame.top
		width 	= width or 0
		height 	= height or 0

		local newgeom = {
			left 	= left,
			top 	= top,
			width 	= width,
			height 	= height,
			right 	= left + width,		-- These are recalced when others are moved/changed
			bottom 	= top + height,

			gid 	= geom.geomid,
			pid 	= parentid,			-- allows loose referencing (weak refs) Fast geom traversals (up only needed)
			childs	= {},				-- children ids of this geom
		}

		geom.geometries[newgeom.gid] = newgeom 	
		geom.addchildtoparent(newgeom)
		return newgeom.gid
	end

	geom.remove 	= function( gid )

		local g = geom.geometries[gid] or nil 
		if(g == nil) then return nil end -- silent fail check returns!
		geom.geometries[gid] = nil
		return true
	end

	geom.clear		= function()

		for k,v in ipairs(geom.geometries) do 
			v = nil 
		end
		geom.geomid = 0
	end

	-- Takes a single geomid and updates all parents (travserses upwards) 
	geom.update 	= function( geomid ) 

		if(geomid == nil) then return nil end -- silent fail check returns!
		local g = geom.geometries[geomid] or nil 
		if(g == nil) then return nil end -- silent fail check returns!
		geom.traverseup( g )
	end
	
	-- Setting any of the params to nil will use current values
	-- A nil geomid will fail
	geom.renew 		= function( geomid, left, top, width, height )

		if(geomid == nil) then return nil end -- silent fail check returns!
		local g = geom.geometries[geomid] or nil 
		if(g == nil) then return nil end -- silent fail check returns!
		g.left		= left or g.left 
		g.top 		= top or g.top 
		g.width 	= width or g.width
		g.height 	= height or g.height 
		g.right 	= g.left + g.width 
		g.bottom 	= g.top + g.height

		-- Force a parent update - may need to resize!
		-- geom.traverseup( g )
		return true
	end

	-- Display the tree hierachy of the geometries
	geom.dump 		= function( startid, tabs ) 

		startid = startid or 1
		tabs = tabs or 1
		
		local thisgeom = geom.geometries[startid]
		if(thisgeom == nil) then return end
		
		print(string.rep("    ", tabs).."Id: ", thisgeom.gid, "Pid:", thisgeom.pid, "Width:", thisgeom.width or "")
		for k,v in ipairs(thisgeom.childs) do
			geom.dump( v, tabs+1 )
		end 
	end 
	
	setmetatable( geom, 
	{
		__index 	= function(t, k)
			return t.geometries[k]
		end, 
		__newindex 	= function( t, k, v )
			t.geometries[k] = v 
		end,
		__len 		= function( t )
			return table.length( t.geometries )
		end
	})

	return geom
end

-----------------------------------------------------------------------------------------------------------------------------------

return geommanager

-----------------------------------------------------------------------------------------------------------------------------------
