----------------------------------------------------------------------------------

return {

    closed_handler = function(g, style, element, dim, pdim)

        local pstyle 		= style.pstyle 
        local pwidth 		= pstyle.maxwidth or pstyle.width   

        -- TODO: This goes in a style check/runner
        if(pdim and pstyle and style.etype == "text") then 

            if(pstyle["text-align"] == "center") then 
                dim.left = dim.left + pwidth / 2 - element.width / 2
                element.pos.left = element.pos.left + pwidth / 2
            elseif(pstyle["text-align"] == "right") then
                dim.left = dim.left + pwidth - element.width
                element.pos.left = element.pos.left + pwidth - element.width
            end
        end
    end 
}

----------------------------------------------------------------------------------
