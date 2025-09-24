local common    = require("engine.libs.elements-common")
local libstyle  = require("engine.libs.elements-style")
local layout    = require("engine.libs.htmllayout")

----------------------------------------------------------------------------------

return {
	opened 		= function (g, style, xml) 

        local attribs = xml.xarg
		local atype = attribs.type:lower()
		style.textsize 		= libstyle.FONT_SIZES.p
		style.linesize 		= common.getlineheight(style)

		if(atype == "button" or atype == "submit") then 
			common.elementbutton(g, style, xml)
		else 
			-- Get the correct text size for the button
			local w, h = libstyle.gettextsize(g, style, attribs.value or "") 
			local tw, th = libstyle.gettextsize(g, style, "w")
	
			-- Minimum width should be 20 chars * charwidth (will choose W).
			if(w < tw * 20) then w = tw * 20 end
			if(style.width < w) then style.width = w end
		
			-- libstyle.setmargins(style, 0, 0, 0, 0)
			-- libstyle.setpadding(style, 8, 4, 8, 4)
			-- libstyle.setborders(style, 1, 1, 1, 1)

			style.height = h * g.ctx.fontsize + style.padding.top + style.padding.bottom
			-- style.width = 8.0 * g.ctx.fontsize
			
			-- A button is inserted as an "empty" div which is expanded as elements are added.		
			local element = common.elementopen(g, style, xml)
			if(atype == "text") then 
				layout.addinputtextobject( g, style, attribs )
				g.cursor.left = g.cursor.left + style.width
			end
		end
	end, 
	
	closed 		= elementbuttonclose,
}

----------------------------------------------------------------------------------