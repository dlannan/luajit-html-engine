local ffi       = require("ffi")
local duk 		= require("duktape")

local dom       = require("engine.libs.htmldom")

----------------------------------------------------------------------------------

dom.createElement = function(ctx)
    local tagStr = duk.duk_to_string(ctx, 0)
    local label = ffi.string(tagStr)
    local el = {
        label = string.lower(label) or "unknown",
        -- attributes = {},
        -- style = {},
        -- classList = {},
        xarg = {},
        id = dom.generateNodeId(),
        -- eventListeners = {},
        -- etc.
    }
    dom.elookup[el.id] = el
    duk.duk_push_int(ctx, el.id)
    return 1
end

----------------------------------------------------------------------------------

dom.getTextContent = function(ctx)
    local id = duk.duk_get_int(ctx, 0)
    local el = dom.getNodeById(id)
    if el and type(el[1]) == "string" then
        duk.duk_push_string(ctx, tostring(el[1] or ""))
    else 
        duk.duk_push_string(ctx, "")
    end
    return 1
end

----------------------------------------------------------------------------------

dom.setTextContent = function(ctx)
    local id = duk.duk_get_int(ctx, 0)
    local text = ffi.string(duk.duk_to_string(ctx, 1))
    if #text == 0 then return 0 end
    local el = dom.getNodeById(id)
    if el then
        -- Clear all children
        for i = #el, 1, -1 do
            table.remove(el, i)
        end        
        el[1] = text or ""
    end
    return 0
end

----------------------------------------------------------------------------------

dom.setAttribute = function(ctx)
    local id = duk.duk_get_int(ctx, 0)
    local name = ffi.string(duk.duk_to_string(ctx, 1))
    local value = ffi.string(duk.duk_to_string(ctx, 2))
    local el = dom.getNodeById(id)
    if el then
        el.xarg[name] = value
        dom.markDirty(el)
    end
    return 0
end

----------------------------------------------------------------------------------

dom.getAttribute = function(ctx)
    local id = duk.duk_get_int(ctx, 0)
    local name = ffi.string(duk.duk_to_string(ctx, 1))
    duk.duk_push_string(ctx, tostring(el.xarg[name] or ""))
    return 1
end

----------------------------------------------------------------------------------

dom.classListAdd = function(ctx)
    local id = duk.duk_get_int(ctx, 0)
    local className = ffi.string(duk.duk_to_string(ctx, 1))
    
    if el then 
        local classAttr = el.xarg.class or ""
        local classes = {}
        for word in classAttr:gmatch("%S+") do
            classes[word] = true
        end
        if not classes[className] then
            el.xarg.class = classAttr .. (classAttr ~= "" and " " or "") .. className
        end
        dom.markDirty(el)
    end
    return 0 
end

----------------------------------------------------------------------------------

dom.classListRemove = function(ctx)
    local id = duk.duk_get_int(ctx, 0)
    local className = ffi.string(duk.duk_to_string(ctx, 1))
    local el = DOM.getNodeById(id)
    if el then
        local classAttr = el.xarg.class or ""
        local result = {}
        for word in classAttr:gmatch("%S+") do
            if word ~= className then
              table.insert(result, word)
            end
        end
        el.xarg.class = table.concat(result, " ")
        dom.markDirty(el)
    end
    return 0 
end

----------------------------------------------------------------------------------

return dom 

----------------------------------------------------------------------------------