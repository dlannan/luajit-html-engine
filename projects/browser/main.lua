
local tcolor = { r=0.0, b=1.0, g=0.0, a=1.0 }
local vcolor = { r=1.0, b=0.0, g=0.0, a=1.0 }

local xmlp 	= require("scripts.libs.xmlparser") 
local htmlr = require("scripts.libs.htmlrenderer") 
local rapi 	= require("scripts.libs.htmlrender-api")

local LEFT_MOUSE = hash("mouse_button_left")
local MIDDLE_MOUSE = hash("mouse_button_middle")
local RIGHT_MOUSE = hash("mouse_button_right")
local WHEEL_UP = hash("mouse_wheel_up")
local WHEEL_DOWN = hash("mouse_wheel_down")
local TEXT = hash("text")
local KEY_SHIFT = hash("key_shift")
local KEY_CTRL = hash("key_ctrl")
local KEY_ALT = hash("key_alt")
local KEY_SUPER = hash("key_super")

-- order MUST match enums in ImGuiKey_
local IMGUI_KEYS = {
	"key_tab",
	"key_left",
	"key_right",
	"key_up",
	"key_down",
	"key_pageup",
	"key_pagedown",
	"key_home",
	"key_end",
	"key_insert",
	"key_delete",
	"key_backspace",
	"key_space",
	"key_enter",
	"key_esc",
	"key_numpad_enter",
	"key_a",
	"key_c",
	"key_v",
	"key_x",
	"key_y",
	"key_z",
}

-- map action_id (key) to ImGuiKey_ enums
local IMGUI_KEYMAP = {}
for i=1,#IMGUI_KEYS do
	local key = IMGUI_KEYS[i]
	IMGUI_KEYMAP[hash(key)] = i - 1
end


function init(self)
	-- Add initialization code here
	-- Remove this function if not needed
	msg.post(".", "acquire_input_focus")
	self.buttons = { 0,0,0 }

	imgui.set_ini_filename()
	
	local filename = "/data/html/sample02-forms.html"
	--local filename = "/data/html/sample02-forms.html"
	local xml = sys.load_resource(filename)
	self.xmldoc = xmlp.parse(xml)
	-- xmlp.dumpxml(self.xmldoc)
	
	-- Override some of the modes for sliders and exploders
	-- CAIRO_UI.EXPLODER_MODE = "outExpo"
	-- CAIRO_UI.SLIDER_MODE = "outBounce"	
	
	self.actions = {}
	self.mouse = {
		x = 0,
		y = 0,
		wheel = 0,
		buttons = {},
	}
	self.renderCtx = {
		fontids = {},
	}

	rapi.setup(self)
	local w, h = window.get_size()
	htmlr.rendersize(w/2, h/1.2)

	-- Toggle the visual profiler on hot reload.
	self.profile = true
	profiler.enable_ui(self.profile)
end

function final(self)
end

-- Each render line is effectively a render layer. Thus the order things are rendered here 
-- control how objects are layered on screen. They can be dynamically shifted.
--  TODO: Layers will be single surfaces and textures within Defold for hi perf.
local bgcolor = { r=0.5, g=0.2, b=0.3, a=1.0 }

function update(self, dt)

	local w, h = window.get_size()
	imgui.set_display_size(w, h)

	rapi.start(self)
	htmlr.renderxml( self.renderCtx, self.xmldoc, { left=10, top=10.0 } )
	rapi.finish(self)
end

function on_message(self, message_id, message, sender)
	-- Add message-handling code here
	-- Remove this function if not needed
end

function on_input(self, action_id, action)
	if action_id == LEFT_MOUSE or action_id == MIDDLE_MOUSE or action_id == RIGHT_MOUSE then
		if action.pressed then
			self.mouse.buttons[action_id] = 1
		elseif action.released then
			self.mouse.buttons[action_id] = 0
		end
	elseif action_id == WHEEL_UP then
		self.mouse.wheel = action.value
	elseif action_id == WHEEL_DOWN then
		self.mouse.wheel = -action.value
	elseif action_id == TEXT then
		imgui.add_input_character(action.text)
	elseif action_id == KEY_SHIFT then
		if action.pressed or action.released then
			imgui.set_key_modifier_shift(action.pressed == true)
		end
	elseif action_id == KEY_CTRL then
		if action.pressed or action.released then
			imgui.set_key_modifier_ctrl(action.pressed == true)
		end
	elseif action_id == KEY_ALT then
		if action.pressed or action.released then
			imgui.set_key_modifier_alt(action.pressed == true)
		end
	elseif action_id == KEY_SUPER then
		if action.pressed or action.released then
			imgui.set_key_modifier_super(action.pressed == true)
		end
	else
		if action.pressed or action.released then
			local key = IMGUI_KEYMAP[action_id]
			if(key) then 
				imgui.set_key_down(key, action.pressed == true)
			end
		end
	end

	if not action_id then
		self.mouse.x = action.screen_x
		self.mouse.y = action.screen_y
	end

	-- -- Check some keys - 1, 2, 3 for profiling
	-- if(action.released) then 
	-- 	if action_id == hash("zero") then
	-- 		self.profile = not self.profile
	-- 		profiler.enable_ui(self.profile)
	-- 	end 
	-- 	if action_id == hash("one") then
	-- 		profiler.set_ui_mode(profiler.MODE_RUN)
	-- 	end 
	-- 	if action_id == hash("two") then
	-- 		profiler.set_ui_mode(profiler.MODE_PAUSE)
	-- 	end
	-- 	if action_id == hash("three") then
	-- 		profiler.set_ui_mode(profiler.MODE_RECORD)
	-- 	end
	-- end
end

function on_reload(self)
	-- Toggle the visual profiler on hot reload.
	profiler.enable_ui(true)
end
