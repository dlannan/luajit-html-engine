local ffi       = require("ffi")
local duk 		= require("duktape")

----------------------------------------------------------------------------------

init_dom    = function(DOM) 
    
----------------------------------------------------------------------------------

DOM.createElement = function(ctx)
    local tagName = ffi.string(duk.duk_to_string(ctx, 0))
    local el = {
        tagName = string.upper(tagName),
        attributes = {},
        style = {},
        classList = {},
        children = {},
        parent = nil,
        id = DOM.generateNodeId(),
        -- eventListeners = {},
        -- etc.
    }
    DOM.nodes[el.id] = el
    duk.duk_push_int(ctx, el.id)
    return 1
end

----------------------------------------------------------------------------------

DOM.setAttribute = function(ctx)
    local id = duk.duk_get_int(ctx, 0)
    local name = ffi.string(duk.duk_to_string(ctx, 1))
    local value = ffi.string(duk.duk_to_string(ctx, 2))
    local el = DOM.getNodeById(id)
    if el then
        el.attributes[name] = value
        DOM.markDirty(el)
    end
    return 0
end

----------------------------------------------------------------------------------

DOM.getAttribute = function(ctx)
    local id = duk.duk_get_int(ctx, 0)
    local name = ffi.string(duk.duk_to_string(ctx, 1))
    duk.duk_push_string(ctx, tostring(el and el.attributes[name] or nil))
    return 1
end

----------------------------------------------------------------------------------

DOM.classListAdd = function(ctx)
    local id = duk.duk_get_int(ctx, 0)
    local className = ffi.string(duk.duk_to_string(ctx, 1))
    if el and not el.classList[className] then
        el.classList[className] = true
        DOM.markDirty(el)
    end
    return 0 
end

----------------------------------------------------------------------------------

DOM.classListRemove = function(ctx)
    local id = duk.duk_get_int(ctx, 0)
    local className = ffi.string(duk.duk_to_string(ctx, 1))
    local el = DOM.getNodeById(id)
    if el and el.classList[className] then
        el.classList[className] = nil
        DOM.markDirty(el)
    end
    return 0 
end

----------------------------------------------------------------------------------

end 

return init_dom

----------------------------------------------------------------------------------