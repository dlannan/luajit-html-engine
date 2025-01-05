
----------------------------------------------------------------------------------

return {
	opened 		= function(g, style, attribs)
		-- Dont create graphics objects in the head
		style.nographics = true
	end,
	closed 		= function() end ,
}

----------------------------------------------------------------------------------
