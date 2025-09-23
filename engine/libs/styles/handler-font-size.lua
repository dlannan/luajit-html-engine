----------------------------------------------------------------------------------

return {

    open_handler = function(g, style, element, dim, pdim)

        -- TODO: Support the different size mechansisms
        local size_str = style["font-size"]:match("^(%-?%d+%.?%d*)")
        style.textsize 	= tonumber(size_str)
    end 
}

----------------------------------------------------------------------------------
