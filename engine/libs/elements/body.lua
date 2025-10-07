local common = require("engine.libs.elements-common")

----------------------------------------------------------------------------------

return {
	opened 		= function( g, style, xml )
		common.elementopen( g, style, xml )
		--style.display = style.display or "block"
	end,
	closed 		= common.elementclose,
}

----------------------------------------------------------------------------------