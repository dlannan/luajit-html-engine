local ffi       = require("ffi")
local duk 		= require("duktape")

----------------------------------------------------------------------------------

init_dom    = function(DOM) 
    
----------------------------------------------------------------------------------

DOM.createNode = function(ctx)
    local nodeName = duk.duk_to_string(ctx, 0) 
    local node = {
        nodeName = ffi.string(nodeName) or "unknown",
        children = {},
        parent = nil,
        id = DOM.generateNodeId(),
        -- other metadata
    }
    DOM.nodes[node.id] = node
    duk.duk_push_int(ctx, node.id)
    return 1
end

----------------------------------------------------------------------------------

DOM.getNodeById = function( id )
    return DOM.nodes[id] or nil
end

----------------------------------------------------------------------------------

DOM.appendChild = function( ctx )

    local parentId = duk.duk_get_int(ctx, 0)
    local childId = duk.duk_get_int(ctx, 1)

    local parent = DOM.getNodeById(parentId)
    local child = DOM.getNodeById(childId)

    -- update Lua DOM structure
    table.insert(parent.children, child)
    child.parent = parent

    -- mark render nodes dirty, update scenegraph etc
    DOM.markDirty(parent)

    return 0
end

----------------------------------------------------------------------------------

DOM.removeChild = function(ctx)

    local parentId = duk.duk_get_int(ctx, 0)
    local childId = duk.duk_get_int(ctx, 1)

    local parent = DOM.getNodeById(parentId)
    local child = DOM.getNodeById(childId)

    -- update Lua DOM structure
    table.insert(parent.children, child)
    child.parent = parent

    -- mark render nodes dirty, update scenegraph etc
    DOM.markDirty(parent)
    return 0
end

end

----------------------------------------------------------------------------------
-- Init DOM
return init_dom

----------------------------------------------------------------------------------