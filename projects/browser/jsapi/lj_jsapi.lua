local ffi       = require("ffi")
local cbor      = require("luajit-cbor") -- any CBOR decoder
local duk 		= require("duktape")

local slib      = require("sokol_libs") -- Needed for timing
local utils     = require("lua.utils")

local tinsert 	= table.insert

-- This should be set on register
local browser   = nil 

-- --------------------------------------------------------------------------------------

function duck_checkerr(jsctx, err)

	local msg = duk.duk_to_string(jsctx, -1)
	print(string.format("[DukTape] Fatal Error: %s", ffi.string(msg) ))
end

-- --------------------------------------------------------------------------------------

function core_eval_func(ctx) 
    local code = ffi.string(duk.duk_get_pointer(ctx, -1))
    duk.duk_eval_raw(ctx, code, #code, 0)
    return 1
end

-- --------------------------------------------------------------------------------------

local function duk_eval_string( ctx, codestr, filename )
	
	local errors = 1
	-- print("------>>", filename)
	duk.duk_push_string(ctx, filename)
	local flags = bit.bor( 1, bit.bor( duk.DUK_COMPILE_SAFE, bit.bor(duk.DUK_COMPILE_NOSOURCE, duk.DUK_COMPILE_STRLEN ) ) )
	local err = duk.duk_compile_raw(ctx, codestr, 0, flags )
	if( err ~= 0 ) then 
		print(string.format("[Duktape] Compile failed. Filename: %s", filename))
		print(string.format("[Duktape] %s", ffi.string(duk.duk_to_string(ctx, -1))))
	else
		errors = 0
	end
	return errors
end

-- --------------------------------------------------------------------------------------

local function duk_safe_eval( ctx, str, filename )

	filename = filename or "string."
	local err = duk_eval_string(ctx, str, filename)
	if(err ~= 0) then 
		-- Note error for compile should be caught in duk_eval_string
		return err 
	else 
		err = duk.duk_pcall(ctx, 0)
		if(err ~= 0) then 
			local outstr = ffi.string(duk.duk_to_string(ctx, -1))
			print(string.format("[Duktape] In file: %s", filename))
			print(string.format("[Duktape] \tError %d : %s", err, outstr))
		-- else 
		-- 	print(string.format("[Duktape] \tResult : %d", duk.duk_get_int(ctx, -1)))
		end
	end
	duk.duk_pop(ctx)
	return err
end

-- --------------------------------------------------------------------------------------

local function duk_compile_filename( ctx, filename )
	local fh = io.open(filename, "rb")
	if(fh) then 
		local fbuffer = fh:read("*a")
		fh:close()
		return duk_safe_eval( ctx, fbuffer, filename)
	else 
		print(string.format("[DukTape] Cannot open file: %s", filename ))
		return nil
	end
end

-- --------------------------------------------------------------------------------------

local function native_invoke_function(ctx, funcname) 
    duk.duk_get_global_string(ctx, funcname)
	duk.duk_push_null(ctx);
	duk.duk_put_global_string(ctx, funcname)
    duk.duk_call(ctx, 0)
	duk.duk_pop(ctx)
    return 0
end

-- --------------------------------------------------------------------------------------

function shim_done(ctx) 

	local time = duk.duk_get_number(ctx, 0)
	browser.timeoffset = time - slib.stm_ms(slib.stm_now())
	browser.ready = true
	return 0 
end

-- --------------------------------------------------------------------------------------

function new_timer( ctx )

	local id = duk.duk_get_int(ctx, 0)
	local time = (duk.duk_get_number(ctx, 1) - browser.timeoffset)
	local delay = duk.duk_get_uint(ctx, 2)
	local rep = duk.duk_get_boolean(ctx, 3)
	-- print(id, time, delay, rep)
	browser.timers[id] = { id = id, time = time, delay = delay, rep = rep } 
	browser.timers_count = browser.timers_count + 1
	return 0
end

-- --------------------------------------------------------------------------------------

function delete_timer( ctx )
	local id = duk.duk_get_int(ctx, 0)
	browser.timers[id] = nil 
	browser.timers_count = browser.timers_count - 1
	return 0
end 

-- --------------------------------------------------------------------------------------

function repeat_timer( ctx )
	local id = duk.duk_get_int(ctx, 0)
	local time = (duk.duk_get_number(ctx, 1) - browser.timeoffset)
	browser.timers[id].time = time 
	return 0
end 

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

----------------------------------------------------------------------------------
-- Register the functions to duktape so the dom and nodes can be recieved as cbor
local function register_jsapi(ctx, _browser)

    browser = _browser

	-- Needed to map in a DOM so the JS structures match expected hierarchies
	duk.duk_push_c_function(ctx, shim_done, 1)
	duk.duk_put_global_string(ctx, "lj_shimdone")

	-- Timer related functions
	duk.duk_push_c_function(ctx, new_timer, 4)
	duk.duk_put_global_string(ctx, "lj_newtimer")

	duk.duk_push_c_function(ctx, delete_timer, 1)
	duk.duk_put_global_string(ctx, "lj_deltimer")

	duk.duk_push_c_function(ctx, repeat_timer, 2)
	duk.duk_put_global_string(ctx, "lj_reptimer")

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

----------------------------------------------------------------------------------

return {
    register                = register_jsapi,
    loaddom                 = loadDomFromDuktape,

    duk_compile_filename    = duk_compile_filename,
    duk_safe_eval           = duk_safe_eval,
}

----------------------------------------------------------------------------------