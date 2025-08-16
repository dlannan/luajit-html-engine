local ffi       = require("ffi")
local duk 		= require("duktape")
local cbor      = require("luajit-cbor") -- any CBOR decoder

local slib      = require("sokol_libs") -- Needed for timing
local utils     = require("lua.utils")

local tinsert 	= table.insert

-- This should be set on register
local browser   = nil 

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
        -- dom.loadxml(luaDom) -- reuse your existing loader
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

function load_url_cb( resp )

    local url = ffi.string(resp.path)
    local req = browser.requests[url]
    if(req) then 
        local ctx = req.ctx 

        duk.duk_get_global_string(ctx, "_lj_xhr_object")
        duk.duk_get_prop_string(ctx, 0, "_requestId")
        local reqid = tonumber(duk.duk_to_int(ctx, -1))

        local urldata = ffi.string(resp.buffer.ptr, resp.buffer.size)
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
    end
end   

-- --------------------------------------------------------------------------------------

local MAX_FILE_SIZE = 1024 * 1024 * 4 -- 4MB

function load_url( ctx )

    local reqid         = #browser.requests

    duk.duk_require_object(ctx, -2)
    duk.duk_require_function(ctx, -1)

    -- Store the callback!
    duk.duk_dup(ctx, -1)
    local callfuncstr = string.format("_lj_xhr_callback_%d", reqid)
    duk.duk_put_global_string(ctx, callfuncstr)
    -- Store the xhr obj!
    duk.duk_dup(ctx, -2)
    duk.duk_put_global_string(ctx, "_lj_xhr_object")

    duk.duk_get_prop_string(ctx, -2, "_method")
	local method = ffi.string(duk.duk_to_string(ctx, -1)) -- gets from prop
    duk.duk_get_prop_string(ctx, -3, "_url")
	local url = ffi.string(duk.duk_to_string(ctx, -1))
    -- print(method, url)

    -- start loading a file into a statically allocated buffer:
	local req 			= ffi.new("sfetch_request_t[1]")
	req[0].path 		= url 
	req[0].callback 	= load_url_cb
	req[0].buffer.ptr 	= ffi.new("char[?]", MAX_FILE_SIZE)
	req[0].buffer.size 	= MAX_FILE_SIZE

    slib.sfetch_send(req)

	local newreq = { id =  reqid, url = url, method = method, ctx = ctx }
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
	duk.duk_put_global_string(ctx, "lj_loaddom"); 
end
  
-- --------------------------------------------------------------------------------------

return {
    register_bridge     = register_bridge,
}

-- --------------------------------------------------------------------------------------
