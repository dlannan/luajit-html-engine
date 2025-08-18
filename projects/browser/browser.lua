
package.path    = package.path..";../../?.lua"
local dirtools  = require("tools.vfs.dirtools").init("luajit%-html%-engine")

--_G.SOKOL_DLL    = "sokol_debug_dll"
local sapp      = require("sokol_app")

-- TODO: See if we can improve the use of these. The main problem being decoupling of modules.
sgp             = require("sokol_gp")
sg              = sgp
sgl 			= sgp
fs 				= sgp

-- --------------------------------------------------------------------------------------

local slib      = require("sokol_libs") -- Warn - always after gfx!!

local hmm       = require("hmm")
local hutils    = require("hmm_utils")

local duk 		= require("duktape")
local events 	= require("projects.browser.events")
local ljdom 	= require("projects.browser.jsapi.lj_dom")
local jsapi 	= require("projects.browser.jsapi.lj_jsapi")

local htmlr 	= require("engine.libs.htmlrenderer") 
local rapi 		= require("engine.libs.htmlrender-api")

local utils     = require("utils")
local cron 		= require("cron")
local ffi       = require("ffi")

local pprint 	= require("pprint")

local tinsert 	= table.insert

-- --------------------------------------------------------------------------------------

ffi.cdef[[
	void Sleep(uint32_t ms);
]]

-- --------------------------------------------------------------------------------------

-- Each render line is effectively a render layer. Thus the order things are rendered here 
-- control how objects are layered on screen. They can be dynamically shifted.
--  TODO: Layers will be single surfaces and textures within Defold for hi perf.
local bgcolor 	= { r=0.5, g=0.2, b=0.3, a=1.0 }
local tcolor 	= { r=0.0, b=1.0, g=0.0, a=1.0 }
local vcolor 	= { r=1.0, b=0.0, g=0.0, a=1.0 }

-- --------------------------------------------------------------------------------------

local browser = {
	requests 	= {},
	messages 	= {},
	timers 		= {},
	timers_count = 0,
}

-- --------------------------------------------------------------------------------------

function runTimers()

	if(browser.timers_count < 1) then return end

	local time = slib.stm_ms(slib.stm_now())
	for idx, tmr in pairs(browser.timers) do 
		if( tmr and time > tmr.time ) then 
			browser.send_message( "main", "js_eval", {
				cmd = [[updateTimer(]]..tmr.id..[[);]],
			})
		end 
	end
end	

-- --------------------------------------------------------------------------------------

browser.send_message = function( src, dst, msg )

	tinsert(browser.messages, { src = src, dst = dst, msg = msg })
end

-- --------------------------------------------------------------------------------------

browser.init = function (self)

	slib.stm_setup()

	self.buttons = { 0,0,0 }
	self.renderCtx = {}

	self.actions = {}
	self.mouse = {
		x = 0,
		y = 0,
		wheel = 0,
		buttons = {},
	}

	rapi.setup(self)
	local w         = sapp.sapp_widthf()
    local h        	= sapp.sapp_heightf()
	htmlr.rendersize(w/2, h/1.2)

	local filename = "projects/browser/data/html/sample01.html"
	-- local filename = "projects/browser/data/html/tests/css-simple01.html"
	-- local filename = "projects/browser/data/html/tests/css-fonts01.html"
	-- local filename = "projects/browser/data/html/tests/css-selectors-element.html"
	-- local filename = "projects/browser/data/html/tests/css-selectors-id.html"
	-- local filename = "projects/browser/data/html/tests/css-selectors-class.html"
	-- local filename = "projects/browser/data/html/tests/css-selectors-multi.html"
	htmlr.load(self, filename)

	-- Toggle the visual profiler on hot reload.
	self.profile = true

	-- setup js interpreter
	browser.jsctx = duk.duk_create_heap(nil,nil,nil,nil,duck_checkerr)
	ljdom.register_bridge(browser.jsctx, browser)
	jsapi.register(browser.jsctx, browser)

	-- Inject the DOM stub JS before jQuery
	local err = jsapi.duk_compile_filename(browser.jsctx, "projects/browser/data/js/cbor.min.js")
	local err = jsapi.duk_compile_filename(browser.jsctx, "projects/browser/data/js/shims/luajit.js")
	
	local err = jsapi.duk_compile_filename(browser.jsctx, "projects/browser/data/js/errordebug.js")
	local err = jsapi.duk_compile_filename(browser.jsctx, "projects/browser/data/js/shims/dom.js")
	local err = jsapi.duk_compile_filename(browser.jsctx, "projects/browser/data/js/shims/timers.js")
	local err = jsapi.duk_compile_filename(browser.jsctx, "projects/browser/data/js/shims/xhr.js")
	
	local err = jsapi.duk_compile_filename(browser.jsctx, "projects/browser/data/js/zepto.js")

	-- local err = jsapi.duk_compile_filename(browser.jsctx, "projects/browser/data/js/jquery.min.js")
	-- local err = jsapi.duk_compile_filename(browser.jsctx, "projects/browser/data/js/startmin.js")
	-- local err = jsapi.duk_compile_filename(browser.jsctx, "projects/browser/data/js/mandel.js")

	browser.send_message( "main", "js_eval", {
		cmd = [[
var div = document.createElement("div");
div.innerHTML = "Hello!";
div.setAttribute("id", "some_element");
document.body.appendChild(div);
print("Div added to fake DOM");

var root = $('#some_element')[0];
dumpDOM(root);  
print($.camelCase('hello-there')); 
]],
	} )

	browser.send_message( "main", "js_eval", {
		cmd = [[
$.get('projects/browser/data/html/tests/css-simple01.html', function(err, status, xhr) {
	print(status);
	//print(xhr.responseText);

	// print(JSON.stringify(document));
    lj_loaddom(CBOR.encode(document.documentElement));
});		
]],
	} )

	-- browser.send_message( "main", "duk_exec", {
	-- 	cmd = jsapi.loaddom,
	-- } )
end

-- --------------------------------------------------------------------------------------

browser.final = function(self)
	duk.duk_destroy_heap(jsctx)	
end

-- --------------------------------------------------------------------------------------

browser.update = function(self, dt)

	rapi.start(self)
	htmlr.render( { left=50, top=50.0 } )
	rapi.finish(self)
	events.process()
end

-- --------------------------------------------------------------------------------------

browser.check_requests = function(self)

	for k,v in pairs(self.requests) do 
		ljdom.load_url_cb(v.url)
	end
end

-- --------------------------------------------------------------------------------------

browser.check_messages = function(self)

	-- Update timers in duktape.
	-- native_invoke_function(browser.jsctx, "runTimers" )
	runTimers()

	for k,msg in ipairs(browser.messages) do 
		if(msg.dst == "js_eval") then 
			-- print(msg.msg.cmd)
			local err = jsapi.duk_safe_eval(browser.jsctx, msg.msg.cmd)
		elseif(msg.dst == "duk_exec") then 
			local err = msg.msg.cmd(browser.jsctx)
		end
	end 
	browser.messages = {}
end

-- --------------------------------------------------------------------------------------
-- Handle incoming input events from mouse/keyboard/touch etc

browser.on_input = function(self, event)

	events.add_event(event)
    -- const float dpi_scale = _snuklear.desc.dpi_scale;

	-- if action_id == LEFT_MOUSE or action_id == MIDDLE_MOUSE or action_id == RIGHT_MOUSE then
	-- 	if action.pressed then
	-- 		self.mouse.buttons[action_id] = 1
	-- 	elseif action.released then
	-- 		self.mouse.buttons[action_id] = 0
	-- 	end
	-- elseif action_id == WHEEL_UP then
	-- 	self.mouse.wheel = action.value
	-- elseif action_id == WHEEL_DOWN then
	-- 	self.mouse.wheel = -action.value
	-- elseif action_id == TEXT then
	-- 	imgui.add_input_character(action.text)
	-- elseif action_id == KEY_SHIFT then
	-- 	if action.pressed or action.released then
	-- 		imgui.set_key_modifier_shift(action.pressed == true)
	-- 	end
	-- elseif action_id == KEY_CTRL then
	-- 	if action.pressed or action.released then
	-- 		imgui.set_key_modifier_ctrl(action.pressed == true)
	-- 	end
	-- elseif action_id == KEY_ALT then
	-- 	if action.pressed or action.released then
	-- 		imgui.set_key_modifier_alt(action.pressed == true)
	-- 	end
	-- elseif action_id == KEY_SUPER then
	-- 	if action.pressed or action.released then
	-- 		imgui.set_key_modifier_super(action.pressed == true)
	-- 	end
	-- else
	-- 	if action.pressed or action.released then
	-- 		local key = IMGUI_KEYMAP[action_id]
	-- 		if(key) then 
	-- 			imgui.set_key_down(key, action.pressed == true)
	-- 		end
	-- 	end
	-- end

	-- if not action_id then
	-- 	self.mouse.x = action.screen_x
	-- 	self.mouse.y = action.screen_y
	-- end

end

-- --------------------------------------------------------------------------------------

browser.on_reload = function(self)
end

-- --------------------------------------------------------------------------------------

local function update_fetch()
	if(browser.ready == nil or browser.jsctx == nil) then return end

	browser:check_messages()
	browser:check_requests()
end

-- --------------------------------------------------------------------------------------

local function init()

    local desc = ffi.new("sg_desc[1]")
    desc[0].environment = slib.sglue_environment()
    desc[0].logger.func = slib.slog_func
    desc[0].disable_validation = false
    sg.sg_setup( desc )
    print("Sokol Is Valid: "..tostring(sg.sg_isvalid()))

    -- Initialize Sokol GP, adjust the size of command buffers for your own use.
    local sgpdesc = ffi.new("sgp_desc[1]")
    ffi.fill(sgpdesc, ffi.sizeof("sgp_desc"))
    sgp.sgp_setup(sgpdesc)
    print("Sokol GP Is Valid: ".. tostring(sgp.sgp_is_valid()))

	local sgldesc = ffi.new("sgl_desc_t[1]")
	sgl.sgl_setup(sgldesc)

	browser:init()
	browser.tick_fetch = cron.every(0.2, update_fetch)
end

-- --------------------------------------------------------------------------------------

local function input(event) 

	browser:on_input(event)
end

-- --------------------------------------------------------------------------------------
local SixtyHz = 1.0/60.0

local function frame()

    -- Get current window size.
    local w         = sapp.sapp_widthf()
    local h         = sapp.sapp_heightf()
    local t         = sapp.sapp_frame_duration()

    -- Begin recording draw commands for a frame buffer of size (width, height).
    sgp.sgp_begin(w, h)
    -- Set frame buffer drawing region to (0,0,width,height).
    sgp.sgp_viewport(0, 0, w, h)
    -- Set drawing coordinate space to (left=-ratio, right=ratio, top=1, bottom=-1).
    sgl.sgl_defaults()
    sgl.sgl_matrix_mode_projection()
    sgl.sgl_ortho(0.0, w, h, 0.0, -1.0, 1.0)

    -- Clear the frame buffer.
    sgp.sgp_set_color(0.1, 0.1, 0.1, 1.0)
    sgp.sgp_clear()

	-- Must go here because the sokol 2d drawing happens within the rapi
	--  NOTE: This might be separated later with procs so we can have multiple render 
	--        processes running (making best use of cores and mp)

	browser:update(t)

    -- Begin a render pass.
    local pass      = ffi.new("sg_pass[1]")
    pass[0].swapchain = slib.sglue_swapchain()
	pass[0].action.colors[0].load_action = sg.SG_LOADACTION_CLEAR
	pass[0].action.colors[0].clear_value.r = 0.3
	pass[0].action.colors[0].clear_value.g = 0.3
	pass[0].action.colors[0].clear_value.b = 0.32
	pass[0].action.colors[0].clear_value.a = 1.0
    sg.sg_begin_pass(pass)

	-- Dispatch all draw commands to Sokol GFX.
    sgp.sgp_flush()
    -- Finish a draw command queue, clearing it.
    sgp.sgp_end()
	-- Render the draw queue
	sgl.sgl_draw()

    -- End render pass.
    sgp.sg_end_pass()
    -- Commit Sokol render.
    sg.sg_commit()

	browser.tick_fetch:update(t)

	-- Give up some idle time - TODO: this is shitty. will remove
	ffi.C.Sleep(1)
end

-- --------------------------------------------------------------------------------------

local function cleanup()

	browser:final()
    sgp.sgp_shutdown()
    sg.sg_shutdown()
end

-- --------------------------------------------------------------------------------------

local app_desc = ffi.new("sapp_desc[1]")
app_desc[0].init_cb     	= init
app_desc[0].frame_cb    	= frame
app_desc[0].cleanup_cb  	= cleanup
app_desc[0].event_cb		= input
app_desc[0].width       	= 1920
app_desc[0].height      	= 1080
app_desc[0].window_title 	= "Browser Prototype (Sokol GP)"
app_desc[0].fullscreen  	= false
app_desc[0].icon.sokol_default = true 
app_desc[0].logger.func = slib.slog_func 

sapp.sapp_run( app_desc )

-- --------------------------------------------------------------------------------------
