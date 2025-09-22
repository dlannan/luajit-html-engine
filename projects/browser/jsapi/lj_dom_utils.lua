
local ffi       = require("ffi")
local duk 		= require("duktape")

local dom       = require("engine.libs.htmldom")
    
----------------------------------------------------------------------------------

dom.dumpTree = function(nodeId, indent)
    indent = indent or ""
    local node = dom.getNodeById(nodeId)
    if not node then
        print(indent .. "[nil node]")
        return
    end
    if(node) then 
        print(indent .. "<" .. tostring(node.label) .. "> id=" .. tostring(node.id))
    end
    for _, child in ipairs(node or {}) do
        dom.dumpTree(child.id, indent .. "  ")
    end
end

----------------------------------------------------------------------------------

return dom

----------------------------------------------------------------------------------