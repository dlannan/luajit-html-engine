local common    	= require("engine.libs.elements-common")
local libstyle  	= require("engine.libs.elements-style")
local layout    	= require("engine.libs.htmllayout")

local utils 		= require("lua.utils")

----------------------------------------------------------------------------------
-- Lists - ul and ol should use this

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )

		if(style.list) then 
			style.margin.left 	=  style.margin.left + style.pstyle.list.depth * style.textsize
			if(style.list.ltype == "ordered") then 
				style.pstyle.list.index = style.pstyle.list.index + 1
			end
		end		
		common.stepline(g, style)
		common.elementopen(g, style, xml)
	end,
	closed 		= function( g, style, xml )
		common.elementclose(g, style, xml)
	end,
}
----------------------------------------------------------------------------------