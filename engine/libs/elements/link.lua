
----------------------------------------------------------------------------------

return  {
	opened 		= function(g, style, xml)
		style.notextprocess   = true
		style.cssprocess 	  = true
		-- Save link args and add to css styles list
	end,
	closed 		= function() end ,
}

----------------------------------------------------------------------------------