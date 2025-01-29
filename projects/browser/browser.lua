
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

local htmlr 	= require("engine.libs.htmlrenderer") 
local rapi 		= require("engine.libs.htmlrender-api")

local utils     = require("utils")
local ffi       = require("ffi")


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

local browser = {}

local function duk_eval_string( ctx, src)  
	return duk.duk_eval_raw(ctx, src, #src,  
				bit.bor(duk.DUK_COMPILE_EVAL, 
					bit.bor( duk.DUK_COMPILE_NOSOURCE, 
						bit.bor( duk.DUK_COMPILE_STRLEN, duk.DUK_COMPILE_NOFILENAME) ) ) )
end


local function duk_compile_filename( ctx, filename )
	return duk.duk_compile_raw(ctx, filename, 0, bit.bor(1, 
						bit.bor( duk.DUK_COMPILE_NOSOURCE, duk.DUK_COMPILE_STRLEN) ) )
end

-- --------------------------------------------------------------------------------------

function native_print(ctx) 
	print(string.format("%s", ffi.string(duk.duk_to_string(ctx, 0))))
	return 0 
end

-- --------------------------------------------------------------------------------------

browser.init = function (self)

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
	local jsctx = duk.duk_create_heap(nil,nil,nil,nil,nil)
	duk.duk_push_c_function(jsctx, native_print, 1)
	local err = duk_compile_filename(jsctx, "projects/browser/data/js/jquery.min.js")
	print(string.format("Error: %d", err))
	local err = duk_compile_filename(jsctx, "projects/browser/data/js/startmin.js")
	print(string.format("Error: %d", err))
	duk.duk_destroy_heap(jsctx)	

end

-- --------------------------------------------------------------------------------------

browser.final = function(self)
end

-- --------------------------------------------------------------------------------------

browser.update = function(self, dt)

	rapi.start(self)
	htmlr.render( { left=50, top=50.0 } )
	rapi.finish(self)
	events.process()
end

-- --------------------------------------------------------------------------------------

browser.on_message = function(self, message_id, message, sender)
	-- Add message-handling code here
	-- Remove this function if not needed
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
end

-- --------------------------------------------------------------------------------------

local function input(event) 

	browser:on_input(event)
end

-- --------------------------------------------------------------------------------------
local tick =0
local function frame()

    -- Get current window size.
    local w         = sapp.sapp_widthf()
    local h         = sapp.sapp_heightf()
    local t         = (sapp.sapp_frame_duration() * 60.0)
    local ratio = w/h
	tick = tick + 1

	-- if(tick % 60 == 0) then print(t) end

    -- Begin recording draw commands for a frame buffer of size (width, height).
    sgp.sgp_begin(w, h)
    -- Set frame buffer drawing region to (0,0,width,height).
    sgp.sgp_viewport(0, 0, w, h)
    -- Set drawing coordinate space to (left=-ratio, right=ratio, top=1, bottom=-1).
    --sgp.sgp_project(-ratio, ratio, 1.0, -1.0)
    sgl.sgl_defaults()
    sgl.sgl_matrix_mode_projection()
    sgl.sgl_ortho(0.0, w, h, 0.0, -1.0, 1.0)

    -- Clear the frame buffer.
    sgp.sgp_set_color(0.1, 0.1, 0.1, 1.0)
    sgp.sgp_clear()

    -- -- Draw an animated rectangle that rotates and changes its colors.
    -- local time = tonumber(sapp.sapp_frame_count()) * sapp.sapp_frame_duration()
    -- local r = math.sin(time)*0.5+0.5
    -- local g = math.cos(time)*0.5+0.5
    -- sgp.sgp_set_color(r, g, 0.3, 1.0)
    -- sgp.sgp_rotate_at(time, 0.0, 0.0)
    -- sgp.sgp_draw_filled_rect(-0.5, -0.5, 1.0, 1.0)

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

	-- Give up some idle time - TODO: this is shitty. will remove
	ffi.C.Sleep(10)
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
