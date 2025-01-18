----------------------------------------------------------------------------------

return {

    open_handler = function(g, style, element, dim, pdim)

        -- TODO: Support the different weight settings (number ones)
        local weight = style["font-weight"]
        if(weight == "bold") then 
            style.fontweight = 1
        elseif(weight == "normal") then 
            style.fontweight = 0
        elseif(weight == "italic") then 
            style.fontstyle = 1
        end
    end 
}

----------------------------------------------------------------------------------
