local common    	= require("engine.libs.elements-common")
local libstyle  	= require("engine.libs.elements-style")
local layout    	= require("engine.libs.htmllayout")

local utils 		= require("lua.utils")

----------------------------------------------------------------------------------
-- Lists - ul and ol should use this

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )
		local plist = style.pstyle.list
		local depth = 0
		if(plist) then depth = plist.depth end
		style.list 			= { ltype = "unordered", index = "•", depth = depth + 1 }
		style.linesize 		= style.textsize
		style.margin 		= libstyle.getmargin(style, libstyle.TEXT_CONST.NONE, 0)
		common.elementopen(g, style, xml)
	end,
	closed 		= function( g, style, xml )
		common.elementclose(g, style)	
	end,
}
----------------------------------------------------------------------------------