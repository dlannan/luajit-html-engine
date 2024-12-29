-- htmlgeom is the html geometry object used to generate element/cell information for layout_changed
-----------------------------------------------------------------------------------------------------------------------------------

local sapp      = require("sokol_app")
local utils 	= require("lua.utils")
local ffi 		= require("ffi")

-----------------------------------------------------------------------------------------------------------------------------------

local tinsert 			= table.insert 
local tremove 			= table.remove 

-- The render api is intended as a render interface that can be replaced
local render_api 		= {
	left 		= 0,
	top 		= 0,
}

local cached_data 		= {}

-----------------------------------------------------------------------------------------------------------------------------------

ffi.cdef [[
typedef struct {
    FONScontext* fons;
    float dpi_scale;
    int font_normal;
    int font_italic;
    int font_bold;
    int font_japanese;
    uint8_t font_normal_data[256 * 1024];
    uint8_t font_italic_data[256 * 1024];
    uint8_t font_bold_data[256 * 1024];
    uint8_t font_japanese_data[2 * 1024 * 1024];
} state_t;
]]

local state = ffi.new("state_t")

-----------------------------------------------------------------------------------------------------------------------------------

local function getRGBAColor( hexColor )

	return {
		a 	= bit.rshift(bit.band(hexColor, 0xFF000000), 24) / 255.0,
		b 	= bit.rshift(bit.band(hexColor, 0xFF0000), 16) / 255.0,
		g 	= bit.rshift(bit.band(hexColor, 0xFF00), 8) / 255.0,
		r 	= bit.band(hexColor, 0xFF) / 255.0,
	}
end

-----------------------------------------------------------------------------------------------------------------------------------
-- Setup the rendering context - renderCtx. 
--   NOTE: This may change - renderCtx islikely to become something else.

render_api.setup = function(self)
	local fontsizebase = 10.0
	local fontsize = 1.0

	self.renderCtx.fonts = {}
	self.renderCtx.window = { x = 50, y = 50 }

	local fonsdesc = ffi.new("sfons_desc_t[1]")
	fonsdesc[0].width 	= 512 
	fonsdesc[0].height 	= 512 

	-- TODO: Make font management much simpler (need a font manager)
	state.fons = fs.sfons_create(fonsdesc)
	
	local regular_data = utils.loaddata("projects/browser/data/fonts/LiberationSerif-Regular.ttf")
	self.renderCtx.fonts["Regular"] = fs.fonsAddFontMem(state.fons, "sans", ffi.cast("unsigned char *", regular_data), #regular_data, false)
	local bold_data = utils.loaddata("projects/browser/data/fonts/LiberationSerif-Bold.ttf")
	self.renderCtx.fonts["Bold"] = 	fs.fonsAddFontMem(state.fons, "sans-bold", ffi.cast("unsigned char *", bold_data), #bold_data, false)
	local italic_data = utils.loaddata("projects/browser/data/fonts/LiberationSerif-Italic.ttf")
	self.renderCtx.fonts["Italic"] = fs.fonsAddFontMem(state.fons, "sans-italic", ffi.cast("unsigned char *", italic_data), #italic_data, false)
	local bolditalic_data = utils.loaddata("projects/browser/data/fonts/LiberationSerif-BoldItalic.ttf")
	self.renderCtx.fonts["BoldItalic"] = fs.fonsAddFontMem(state.fons, "sans-bolditalic", ffi.cast("unsigned char *", bolditalic_data), #bolditalic_data, false)

	self.renderCtx.fontsize = fontsizebase
	self.renderCtx.getstyle = function( style )
		local fontface = style.fontface or "Regular"
		if(style.fontweight == 1) then fontface = "Bold" end 
		if(style.fontstyle == 1) then fontface = "Italic" end 
		if(style.fontstyle == 1 and style.fontweight == 1) then fontface = "BoldItalic" end 
		return self.renderCtx.fonts[fontface]
	end 	
	self.renderCtx.setstyle = function( style )
		local fontface = self.renderCtx.getstyle(style)
		fs.fonsSetFont(state.fons, fontface)
	end 
	self.renderCtx.unsetstyle = function()
	end 

	self.renderCtx.fsctx = fsctx
	-- imgui.set_style_color(imgui.ImGuiCol_WindowBg, 1.00, 1.00, 1.00, 1.00)
	-- imgui.set_style_color(imgui.ImGuiCol_Text, 0.0, 0.0, 0.0, 1.00)
	-- imgui.set_style_color(imgui.ImGuiCol_TextDisabled, 0.60, 0.60, 0.60, 1.00)
	-- imgui.set_style_color(imgui.ImGuiCol_FrameBg, 0.93, 0.93, 0.96, 1.00)
end 

-----------------------------------------------------------------------------------------------------------------------------------

render_api.shutdown = function(self)
	fs.sfons_destroy(self.renderCtx.fsctx)
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Prepare the window frame for rendering to (per frame)
render_api.start = function( self )

	local w        = sapp.sapp_widthf()
    local h        = sapp.sapp_heightf()

	render_api.left = 0
	render_api.top  = 0

	fs.fonsClearState(state.fons)
		


	-- imgui.set_mouse_input(
	-- 	self.mouse.x,
	-- 	h - self.mouse.y,
	-- 	self.mouse.buttons[LEFT_MOUSE] or 0,
	-- 	self.mouse.buttons[MIDDLE_MOUSE] or 0,
	-- 	self.mouse.buttons[RIGHT_MOUSE] or 0,
	-- 	self.mouse.wheel
	-- )
		
	-- local flags = imgui.WINDOWFLAGS_NOTITLEBAR
	-- --	flags = bit.bor(flags, imgui.WINDOWFLAGS_NOBACKGROUND)
	-- flags = bit.bor(flags, imgui.WINDOWFLAGS_NORESIZE)
	-- flags = bit.bor(flags, imgui.WINDOWFLAGS_NOMOVE)

	-- imgui.set_display_size(w, h)

	-- imgui.set_next_window_size(w/2, h/1.2 )
	-- imgui.set_next_window_pos( self.renderCtx.window.x, self.renderCtx.window.y )

	-- imgui.begin_window("Main", true, flags )
end

-----------------------------------------------------------------------------------------------------------------------------------
-- Complete the window frame for rendering to (per frame) and then apply input updates
render_api.finish = function( self )
	
	-- imgui.end_window()
	fs.sfons_flush(state.fons)

    -- -- render pass
    -- local pass      = ffi.new("sg_pass[1]")
    -- pass[0].action.colors[0].load_action = sg.SG_LOADACTION_CLEAR
	-- pass[0].action.colors[0].clear_value.r = 0.3
	-- pass[0].action.colors[0].clear_value.g = 0.3
	-- pass[0].action.colors[0].clear_value.b = 0.32
	-- pass[0].action.colors[0].clear_value.r = 1.0
	-- pass[0].swapchain = slib.sglue_swapchain()
    -- sg.sg_begin_pass(pass)
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Get the size of the text - returns width, and height
local fontHeight = ffi.new("float[1]", {0.0})
render_api.text_getsize = function( text, fontscale, fontface, wrap_size )

	local ptr = ffi.cast("const char *", ffi.string(text))
	local w = fs.fonsTextBounds(state.fons, 0, 0, ptr, nil, nil)
	fs.fonsVertMetrics(state.fons, nil, nil, fontHeight)
	local h = fontHeight[0]
	
	if(w > wrap_size) then 
		local lines = math.floor(w / wrap_size) + 1
		w = wrap_size
		h = lines * h 
	end 
	print(text, w, h, wrap_size)
	return w, h
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Set the scale of the text for the next text render
render_api.set_window_font_scale = function( fontscale)

	fs.fonsSetSize(state.fons, fontscale)
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Set the cursor position for new rendering widget
render_api.set_cursor_pos = function( left, top )

	render_api.left = left 
	render_api.top = top
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Render text using the specified interface
render_api.text = function( text, wrapwidth )

	-- print( render_api.left, render_api.top, text )
	fs.fonsDrawText(state.fons, render_api.left, render_api.top, text, nil)
end


-----------------------------------------------------------------------------------------------------------------------------------
--  Render text using the specified interface
render_api.text_colored = function( text, r, g, b, a)

	fs.fonsSetColor(state.fons, fs.sfons_rgba(r, g, b, a))
	fs.fonsDrawText(state.fons, render_api.left, render_api.top, text, nil)
end
-----------------------------------------------------------------------------------------------------------------------------------
--  Render buttons using the specified interface
render_api.button = function( text, w, h )

	-- imgui.button( text, w, h ) 
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Render input text field
render_api.input_text = function( text, label )

	-- No labels by default
	label = label or ""
	-- return imgui.input_text( label, text ) 
end


-----------------------------------------------------------------------------------------------------------------------------------
--  load images using the specified interface
render_api.image_load = function( filename )

	local cachedid = cached_data[filename]
	if(cachedid) then return cachedid end
	-- local loadeddata = sys.load_resource(filename)
	-- cachedid = imgui.image_load_data(filename, loadeddata, #loadeddata) 
	-- cached_data[filename] = cachedid
	return cachedid
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Render images using the specified interface
render_api.image_add = function( imgid, w, h  )

	-- imgui.image_add( imgid, w, h ) 
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Draw rectangles

local function drawRect( x, y, w, h )

    sgp.sgp_push_transform()
	local lines = ffi.new("sgp_line[4]",{
		{{ x, y }, { x + w, y }},
		{{ x + w, y }, { x + w, y + h}},
		{{ x + h, y + h }, { x, y + h }},
		{{ x, y + h }, { x, y }}
	})
    sgp.sgp_draw_lines(lines, 4)
    sgp.sgp_pop_transform()
end

render_api.draw_rect = function( x, y, w, h, color )

	local c = getRGBAColor(color)
	-- print( c.r, c.g, c.b, c.a )
	sgp.sgp_set_color( c.r, c.g, c.b, c.a )
    drawRect(x, y, tonumber(w), tonumber(h))
	print( string.format("%03d %03d %03d %03d  %04x", x, y, w, h, color) )
end

-----------------------------------------------------------------------------------------------------------------------------------

return render_api

-----------------------------------------------------------------------------------------------------------------------------------
