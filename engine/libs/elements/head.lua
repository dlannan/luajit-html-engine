
----------------------------------------------------------------------------------

return {
	opened 		= function(g, style, xml)
		-- Dont create graphics objects in the head
		style.nographics = true
	end,
	closed 		= function() end ,
}

----------------------------------------------------------------------------------
