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

		-- Get the correct text size for the button
		local w, h = layout.gettextsize(g, style, attribs.value or "") 
	
		if(atype == "button" or atype == "submit") then 
			style.width = style.width + 16
			style.height = style.height + 8
			common.elementbutton(g, style, xml)
		else 
		
			libstyle.setmargins(style, 0, 0, 0, 0)
			libstyle.setpadding(style, 8, 4, 8, 4)
			libstyle.setborders(style, 1, 1, 1, 1)

			style.height = h * g.ctx.fontsize + style.padding.top + style.padding.bottom
			style.width = 8.0 * g.ctx.fontsize
			
			-- A button is inserted as an "empty" div which is expanded as elements are added.		
			local element = common.elementopen(g, style, xml)
			if(atype == "text") then 
				layout.addinputtextobject( g, style, attribs )
			end
		end
	end, 
	
	closed 		= elementbuttonclose,
}

----------------------------------------------------------------------------------