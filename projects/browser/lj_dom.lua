local ffi       = require("ffi")
local duk 		= require("duktape")

-- --------------------------------------------------------------------------------------

ffi.cdef[[
typedef uint32_t u32;
typedef struct { u32 type; u32 parent; u32 firstChild; u32 nextSibling; u32 elemIndex; } Node;
typedef struct { u32 nodeIndex; u32 propStart; u32 propCount; } Element;
typedef struct { u32 nameIdx; u32 valueIdx; } Property;
]]

-- --------------------------------------------------------------------------------------

-- capacity (grow as you need)
local CAP = 16384

-- allocate arrays of structs
local Nodes         = ffi.new("Node[?]", CAP)
local Elements      = ffi.new("Element[?]", CAP)
local Properties    = ffi.new("Property[?]", CAP)

-- --------------------------------------------------------------------------------------
-- string tables (simple Lua tables, map index -> string)
local strings = { }
local function add_string(s)
    local i = #strings + 1
    strings[i] = s
    return i
end

-- --------------------------------------------------------------------------------------
-- simple allocators
local nextNode = 1
local nextElem = 1
local nextProp = 1

-- --------------------------------------------------------------------------------------
-- helper: create element node
local function create_element(tag)
    local nid = nextNode; nextNode = nextNode + 1
    local eid = nextElem; nextElem = nextElem + 1

    Nodes[nid].type = 1 -- ELEMENT_NODE
    Nodes[nid].parent = 0
    Nodes[nid].firstChild = 0
    Nodes[nid].nextSibling = 0
    Nodes[nid].elemIndex = eid

    Elements[eid].nodeIndex = nid
    Elements[eid].propStart = nextProp
    Elements[eid].propCount = 0

    -- store tag name in strings and as property  (optional)
    local tagIdx = add_string(tag or "")
    -- for convenience keep tag name as prop 0 (you can choose a stable mapping)
    Properties[nextProp].nameIdx = add_string("tagName"); Properties[nextProp].valueIdx = tagIdx; nextProp = nextProp + 1
    Elements[eid].propCount = Elements[eid].propCount + 1

    return nid
end

-- --------------------------------------------------------------------------------------
-- helper: append child (link in the node arrays)
local function append_child(parentId, childId)
    -- remove child from old parent if any (simple)
    local oldParent = Nodes[childId].parent
    if oldParent ~= 0 then
        -- unlink from siblings (naive: scan)
        local pfirst = Nodes[oldParent].firstChild
        if pfirst == childId then
        Nodes[oldParent].firstChild = Nodes[childId].nextSibling
        else
        local x = pfirst
        while x ~= 0 and Nodes[x].nextSibling ~= childId do x = Nodes[x].nextSibling end
        if x ~= 0 then Nodes[x].nextSibling = Nodes[childId].nextSibling end
        end
    end

    -- prepend to parent's child list for simplicity
    Nodes[childId].parent = parentId
    Nodes[childId].nextSibling = Nodes[parentId].firstChild
    Nodes[parentId].firstChild = childId
end

-- --------------------------------------------------------------------------------------
-- helper: remove child (link in the node arrays)
local function remove_child(parentId, childId)
    -- remove child from old parent if any (simple)
    local oldParent = Nodes[childId].parent
    if oldParent ~= 0 then
        -- unlink from siblings (naive: scan)
        local pfirst = Nodes[oldParent].firstChild
        if pfirst == childId then
        Nodes[oldParent].firstChild = Nodes[childId].nextSibling
        else
        local x = pfirst
        while x ~= 0 and Nodes[x].nextSibling ~= childId do x = Nodes[x].nextSibling end
        if x ~= 0 then Nodes[x].nextSibling = Nodes[childId].nextSibling end
        end
    end

    -- prepend to parent's child list for simplicity
    Nodes[childId].parent = nil
    Nodes[childId].nextSibling = nil
end

-- --------------------------------------------------------------------------------------
-- helper: get first child
local function get_first_child(nodeId) return Nodes[nodeId].firstChild end
local function get_next_sibling(nodeId) return Nodes[nodeId].nextSibling end
local function get_tag(nodeId)
    local eid = Nodes[nodeId].elemIndex
    if eid == 0 then return nil end
    local ps = Elements[eid].propStart
    local pc = Elements[eid].propCount
    for i = 0, pc-1 do
        local prop = Properties[ps + i]
        if strings[prop.nameIdx] == "tagName" then
        return strings[prop.valueIdx]
        end
    end
    return nil
end

-- --------------------------------------------------------------------------------------
-- attribute access (simple linear search)
local function get_attribute(nodeId, name)
    local eid = Nodes[nodeId].elemIndex
    if eid == 0 then return nil end
    local ps = Elements[eid].propStart
    local pc = Elements[eid].propCount
    for i = 0, pc-1 do
        local prop = Properties[ps + i]
        if strings[prop.nameIdx] == name then
        return strings[prop.valueIdx]
        end
    end
    return nil
end

-- --------------------------------------------------------------------------------------
local function set_attribute(nodeId, name, value)
    local eid = Nodes[nodeId].elemIndex
    if eid == 0 then return end
    local ps = Elements[eid].propStart
    local pc = Elements[eid].propCount
    for i = 0, pc-1 do
        local prop = Properties[ps + i]
        if strings[prop.nameIdx] == name then
        Properties[ps + i].valueIdx = add_string(value)
        return
        end
    end
    -- add new property at end (naive, no packing)
    Properties[nextProp].nameIdx = add_string(name)
    Properties[nextProp].valueIdx = add_string(value)
    Elements[eid].propCount = Elements[eid].propCount + 1
    nextProp = nextProp + 1
end

-- --------------------------------------------------------------------------------------
-- cast helpers (you must keep the cast results alive)
local function wrap_c(fn, nargs)
    local cfn = ffi.cast("duk_c_function", fn)
    return cfn
end
  
-- --------------------------------------------------------------------------------------
-- example bridged functions: signature duk_context *ctx, returns number of returns
local function js_get_first_child(ctx)
    -- arg 0: nodeId
    local id = tonumber(duk.duk_require_int(ctx, 0))
    local c = get_first_child(id)
    duk.duk_push_int(ctx, c)
    return 1
end

-- --------------------------------------------------------------------------------------
-- 
local function js_append_child(ctx)
    -- arg 0: nodeId
    local id = tonumber(duk.duk_require_int(ctx, 0))
    local child_id = tonumber(duk.duk_require_int(ctx, 1))
    append_child(id, child_id)
    return 0
end
  
-- --------------------------------------------------------------------------------------
-- 
local function js_remove_child(ctx)
    -- arg 0: nodeId
    -- arg 1: childId
    local id = tonumber(duk.duk_require_int(ctx, 0))
    local child_id = tonumber(duk.duk_require_int(ctx, 1))
    remove_child(id, child_id)
    return 0
end

-- --------------------------------------------------------------------------------------
local function js_get_next_sibling(ctx)
    local id = tonumber(duk.duk_require_int(ctx, 0))
    local c = get_next_sibling(id)
    duk.duk_push_int(ctx, c)
    return 1
end
  
-- --------------------------------------------------------------------------------------
local function js_get_tag(ctx)
    local id = tonumber(duk.duk_require_int(ctx, 0))
    local s = get_tag(id) or ""
    duk.duk_push_string(ctx, s)
    return 1
end
  
-- --------------------------------------------------------------------------------------
local function js_get_attr(ctx)
    local id = tonumber(duk.duk_require_int(ctx, 0))
    local name = ffi.string(duk.duk_require_lstring(ctx, 1, nil))
    local v = get_attribute(id, name) or ""
    duk.duk_push_string(ctx, v)
    return 1
end
  
-- --------------------------------------------------------------------------------------
local function js_set_attr(ctx)
    local id = tonumber(duk.duk_require_int(ctx, 0))
    local name = ffi.string(duk.duk_require_lstring(ctx, 1, nil))
    local val = ffi.string(duk.duk_require_lstring(ctx, 2, nil))
    set_attribute(id, name, val)
    return 0
end
  
-- --------------------------------------------------------------------------------------
-- createElement that returns new node id
local function js_create_element(ctx)
    local tag = ffi.string(duk.duk_require_lstring(ctx, 0, nil))
    local id = create_element(tag)
    duk.duk_push_int(ctx, id)
    return 1
end
  
-- --------------------------------------------------------------------------------------
-- register these in duktape
local function register_bridge(jsctx)
    -- remember to keep casted functions in Lua globals to avoid GC
    cb_get_first_child = ffi.cast("duk_c_function", js_get_first_child)
    cb_get_next_sibling = ffi.cast("duk_c_function", js_get_next_sibling)
    cb_get_tag = ffi.cast("duk_c_function", js_get_tag)
    cb_get_attr = ffi.cast("duk_c_function", js_get_attr)
    cb_set_attr = ffi.cast("duk_c_function", js_set_attr)
    cb_create_element = ffi.cast("duk_c_function", js_create_element)
    cb_append_child = ffi.cast("duk_c_function", js_append_child)
    cb_remove_child = ffi.cast("duk_c_function", js_remove_child)

    duk.duk_push_c_function(jsctx, cb_get_first_child, 1)
    duk.duk_put_global_string(jsctx, "getFirstChild")

    duk.duk_push_c_function(jsctx, cb_get_next_sibling, 1)
    duk.duk_put_global_string(jsctx, "getNextSibling")

    duk.duk_push_c_function(jsctx, cb_get_tag, 1)
    duk.duk_put_global_string(jsctx, "getTag")

    duk.duk_push_c_function(jsctx, cb_get_attr, 2)
    duk.duk_put_global_string(jsctx, "getAttr")

    duk.duk_push_c_function(jsctx, cb_set_attr, 3)
    duk.duk_put_global_string(jsctx, "setAttr")

    duk.duk_push_c_function(jsctx, cb_create_element, 1)
    duk.duk_put_global_string(jsctx, "createElementNative")

    duk.duk_push_c_function(jsctx, cb_append_child, 2)
    duk.duk_put_global_string(jsctx, "appendChildNative")

    duk.duk_push_c_function(jsctx, cb_remove_child, 2)
    duk.duk_put_global_string(jsctx, "removeChildNative")    
end
  
-- --------------------------------------------------------------------------------------

return {
    register_bridge     = register_bridge,
}

-- --------------------------------------------------------------------------------------
