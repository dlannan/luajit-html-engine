local ffi       = require("ffi")
local duk 		= require("duktape")
local cbor      = require("luajit-cbor") -- any CBOR decoder

local slib      = require("sokol_libs") -- Needed for timing
local utils     = require("lua.utils")

local tinsert 	= table.insert

local htmle     = require("engine.libs.htmlelements")
local htmlr 	= require("engine.libs.htmlrenderer") 

-- This should be set on register
local browser   = nil 

----------------------------------------------------------------------------------
-- dom is maintained in Luajit 
--   TODO: This will become more complex, and allow for partial updates and such.

local dom       = require("engine.libs.htmldom")

----------------------------------------------------------------------------------
-- Id generator - TODO: will improve with a hash or something
dom.generateNodeId = function() 
    dom.nodeid = dom.nodeid + 1
    return dom.nodeid 
end

----------------------------------------------------------------------------------

dom.markDirty = function(parent)
    if(parent) then 
        parent.dirty = true 
    end 
end

----------------------------------------------------------------------------------
-- Utils for dom 
dom = require("projects.browser.jsapi.lj_dom_utils")

-- Init the Node interface
dom = require("projects.browser.jsapi.lj_dom_node")
-- Init the Element interface
dom = require("projects.browser.jsapi.lj_dom_element")

----------------------------------------------------------------------------------
-- Called from JS via FFI/C binding
function luaReceiveDom(buf, len)
    local data = ffi.string(buf, len)
    local luaDom = cbor.decode(data)
    -- dom.loadxml(luaDom) -- use your existing loader
end

----------------------------------------------------------------------------------
-- Called for just updating a node (rather than whole dom)
function luaReceiveDomUpdate(buf, len)
    local data = ffi.string(buf, len)
    local nodeUpdate = cbor.decode(data)
    -- dom.updateNode(nodeUpdate) -- your custom partial updater
end

-- --------------------------------------------------------------------------------------

function luaReceiveDom_cb(ctx) 
    
    local str = ffi.string(duk.duk_get_buffer_data(ctx, -1, nil))
    local slen = duk.duk_get_length(ctx, -2)
    duk.duk_pop(ctx)
	return 0 
end
-- --------------------------------------------------------------------------------------

function luaReceiveDomUpdate_cb(ctx) 

    local str = ffi.string(duk.duk_get_buffer_data(ctx, -1, nil))
    local slen = duk.duk_get_length(ctx, -2)
    luaReceiveDomUpdate(str, slen)
	return 0 
end

----------------------------------------------------------------------------------

local function dumpCBOR(data, luaDom)

    for i = 1, #data do
        io.write(string.format("%02X ", data:byte(i)))
    end
    print("------------- Dump ----------------")
    print(utils.tdump(luaDom))
    print("------------- EndDump -------------")
end

----------------------------------------------------------------------------------

local function loadDomFromDuktape_cb(ctx)

    local size_ptr = ffi.new("size_t[1]")
    local ptr = duk.duk_get_buffer_data(ctx, -1, size_ptr)
    local len = size_ptr[0]
    -- print(len)    

    if(len > 0) then 
        local data = ffi.string(ptr, len)
        local luaDom = cbor.decode(data)
        -- dumpCBOR(data, luaDom)
        htmlr.loadcbor(browser, luaDom)
    end
    return 0
end

----------------------------------------------------------------------------------
-- Assume `ctx` is your Duktape context
local function loadDomFromDuktape(ctx)
    duk.duk_get_global_string(ctx, "exportDomAsCbor")
    local err = duk.duk_pcall(ctx, 0)
    if(err ~= 0) then 
        local outstr = ffi.string(duk.duk_to_string(ctx, -1))
        print(string.format("[Duktape] \texportDomAsCbor() Error %d : %s", err, outstr))
    -- else 
    -- 	print(string.format("[Duktape] \tResult : %d", duk.duk_get_int(ctx, -1)))
        return
    end
    loadDomFromDuktape_cb(ctx)
    -- duk.duk_pop(ctx)
end

-- --------------------------------------------------------------------------------------

local function load_url_cb( url )

    local req = browser.requests[url]
    if(req) then 
        local ctx   = browser.jsctx 
        local reqid = req.id

        local urldata = ""
        local fh = io.open(url, "rb")
        if(fh) then 
            urldata = fh:read("*a")
            fh:close()
        end

        -- print("REQUEST ID: ", reqid)
        -- print("LOAD URL: ", urldata)

        local callfuncstr = string.format("_lj_xhr_callback_%d", reqid)
        duk.duk_get_global_string(ctx, callfuncstr)
        duk.duk_push_string(ctx, urldata)
        local err = duk.duk_pcall(ctx, 1)
        if( err ~= 0 ) then 
            print(err)
            local errorstr = ffi.string(duk.duk_to_string(ctx, -1))
            print(string.format("[Duktape] Error: %d %s", err, errorstr))
        end
        duk.duk_pop(ctx)
        browser.requests[url] = nil
    end
end   

-- --------------------------------------------------------------------------------------

function load_url( ctx )

    local reqid         = utils.tcount(browser.requests)

    duk.duk_require_object(ctx, -2)
    duk.duk_require_function(ctx, -1)

    -- Store the callback!
    duk.duk_dup(ctx, -1)
    local callfuncstr = string.format("_lj_xhr_callback_%d", reqid)
    duk.duk_put_global_string(ctx, callfuncstr)

    duk.duk_get_prop_string(ctx, -2, "_method")
	local method = ffi.string(duk.duk_to_string(ctx, -1)) -- gets from prop
    duk.duk_get_prop_string(ctx, -3, "_url")
	local url = ffi.string(duk.duk_to_string(ctx, -1))
    -- print(method, url)

	local newreq = { id =  reqid, url = url, method = method, sent = false }
	browser.requests[url] = newreq

	duk.duk_push_int(ctx, reqid)
	return 1
end 

-- --------------------------------------------------------------------------------------

function native_print(ctx) 
	local outstr = ffi.string(duk.duk_to_string(ctx, -1))
	print(string.format("[JS] %s", outstr))
	return 0 
end

-- --------------------------------------------------------------------------------------

function reset_dom(ctx)
    
    dom.reset()
    return 0
end

-- --------------------------------------------------------------------------------------

function load_dom_and_render(ctx)

    -- local dom = require("engine.libs.htmldom")
    htmle.reset()
    dom.root = dom.elookup[1]
    utils.savedata("temp_dom.lua", utils.tdump(dom.root)) 
    htmlr.loaddata(browser, dom.root)
    return 0
end

-- --------------------------------------------------------------------------------------
-- register these in duktape
local function register_bridge(ctx, _browser)

    browser = _browser

	duk.duk_push_c_function(ctx, native_print, 1)
	duk.duk_put_global_string(ctx, "print"); 

	-- Url load and fetch commands -- incoming obj is the xhr req object
	duk.duk_push_c_function(ctx, load_url, 2)
	duk.duk_put_global_string(ctx, "lj_loadurl") 

	duk.duk_push_c_function(ctx, luaReceiveDom_cb, 2)
	duk.duk_put_global_string(ctx, "lj_receiveDom")

	duk.duk_push_c_function(ctx, luaReceiveDomUpdate_cb, 2)
	duk.duk_put_global_string(ctx, "lj_receiveDomUpdate")

	duk.duk_push_c_function(ctx, loadDomFromDuktape_cb, 1)
	duk.duk_put_global_string(ctx, "lj_loaddom")

    duk.duk_push_c_function(ctx, load_dom_and_render, 0)
    duk.duk_put_global_string(ctx, "lj_renderdom")

    duk.duk_push_c_function(ctx, reset_dom, 0)
    duk.duk_put_global_string(ctx, "lj_resetdom")
    
    -- dom Node Specific interface
    duk.duk_push_c_function(ctx, dom.createNode, 1 )
    duk.duk_put_global_string(ctx, "dt_createNode"); 

    duk.duk_push_c_function(ctx, dom.appendChild, 2 )
    duk.duk_put_global_string(ctx, "dt_appendChild"); 

    duk.duk_push_c_function(ctx, dom.removeChild, 2 )
    duk.duk_put_global_string(ctx, "dt_removeChild"); 
    
    --dom Element Specific Interface
    duk.duk_push_c_function(ctx, dom.createElement, 1)
    duk.duk_put_global_string(ctx, "dt_createElement")

    duk.duk_push_c_function(ctx, dom.setTextContent, 2)
    duk.duk_put_global_string(ctx, "dt_setTextContent")
    
    duk.duk_push_c_function(ctx, dom.getTextContent, 1)
    duk.duk_put_global_string(ctx, "dt_getTextContent")

    duk.duk_push_c_function(ctx, dom.setAttribute, 3)
    duk.duk_put_global_string(ctx, "dt_setAttribute")
    
    duk.duk_push_c_function(ctx, dom.getAttribute, 2)
    duk.duk_put_global_string(ctx, "dt_getAttribute")
    
    duk.duk_push_c_function(ctx, dom.classListAdd, 2)
    duk.duk_put_global_string(ctx, "dt_classListAdd")
    
    duk.duk_push_c_function(ctx, dom.classListRemove, 2)
    duk.duk_put_global_string(ctx, "dt_classListRemove")    
    
end
  
-- --------------------------------------------------------------------------------------

return {
    register_bridge     = register_bridge,
    load_url_cb         = load_url_cb,

    dump_tree           = dom.dumpTree,

    get_slot            = get_slot,
    slot_count          = slot_count, 
    slot_available      = slot_available,
}

-- --------------------------------------------------------------------------------------
