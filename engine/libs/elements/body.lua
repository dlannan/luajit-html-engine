local common = require("engine.libs.elements-common")

----------------------------------------------------------------------------------

return {
	opened 		= function(g, style, xml) 
		common.elementopen(g, style, xml)
	end,
	closed 		= common.defaultclose,
}

----------------------------------------------------------------------------------