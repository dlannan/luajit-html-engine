
local ffi       = require("ffi")
local duk 		= require("duktape")

----------------------------------------------------------------------------------

init_dom    = function(DOM) 
    
----------------------------------------------------------------------------------

DOM.dumpTree = function(nodeId, indent)
    indent = indent or ""
    local node = DOM.getNodeById(nodeId)
    if not node then
        print(indent .. "[nil node]")
        return
    end
    if(node.tagName) then 
        print(indent .. "<" .. tostring(node.tagName) .. "> id=" .. tostring(node.id))
    else 
        print(indent .. "<" .. tostring(node.nodeName) .. "> id=" .. tostring(node.id))
    end
    for _, child in ipairs(node.children or {}) do
        DOM.dumpTree(child.id, indent .. "  ")
    end
end

----------------------------------------------------------------------------------

end 

return init_dom

----------------------------------------------------------------------------------