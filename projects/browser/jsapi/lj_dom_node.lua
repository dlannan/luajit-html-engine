local ffi       = require("ffi")
local duk 		= require("duktape")

local dom       = require("engine.libs.htmldom")
    
----------------------------------------------------------------------------------

dom.createNode = function(ctx)
    local nodeName = duk.duk_to_string(ctx, 0) 
    local node = {
        label = ffi.string(nodeName) or "unknown",
        xarg = {},
        id = dom.generateNodeId(),
        -- other metadata
    }
    dom.elookup[node.id] = node
    duk.duk_push_int(ctx, node.id)
    return 1
end

----------------------------------------------------------------------------------

dom.getNodeById = function( id )
    return dom.elookup[id] or nil
end

----------------------------------------------------------------------------------

dom.appendChild = function( ctx )

    local parentId = duk.duk_get_int(ctx, 0)
    local childId = duk.duk_get_int(ctx, 1)

    local parent = dom.getNodeById(parentId)
    local child = dom.getNodeById(childId)

    if(parent == nil or child == nil) then 
        return 0
    end

    -- update Lua DOM structure

    if child.label == "text" then 
        table.insert(parent, #parent+1, child[1])
    else 
        table.insert(parent, #parent+1, child)
    end
    -- print("Adding Child: "..parent.label.."  "..parent.id.." -> "..child.label.."  "..child.id)

    -- mark render nodes dirty, update scenegraph etc
    dom.markDirty(parent)

    return 0
end

----------------------------------------------------------------------------------

dom.removeChild = function(ctx)

    local parentId = duk.duk_get_int(ctx, 0)
    local childId = duk.duk_get_int(ctx, 1)

    local parent = dom.getNodeById(parentId)

    -- update Lua DOM structure
    for id = #parent, 1, -1 do
        if(parent[id] == childId) then 
            table.remove(parent, id)
            break
        end
    end 
    
    -- mark render nodes dirty, update scenegraph etc
    dom.markDirty(parent)
    return 0
end

----------------------------------------------------------------------------------

return dom

----------------------------------------------------------------------------------