local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------
-- Table is a bit of a complex one. 
--   Setup some states so that this table instance, can collect its head, body and 
--   rows within the body. On close it can then provide correct initial layout and 
--   position and sizes

-- default table style width expands to 100%. 
-- default table height is lineheight x rows + head
return  {
	opened 		= function (g, style, attribs) 
		style.margin 		= libstyle.getmargin(style, libstyle.TEXT_CONST.NONE, 0)
		style.pstyle.linesize = common.getlineheight(style)
		common.elementopen(g, style, attribs)
	end,
	closed 		= function( g, style )
		-- Update table dimensions	
		common.elementclose(g, style)
	end,
}

----------------------------------------------------------------------------------