-- htmlgeom is the html geometry object used to generate element/cell information for layout_changed
-----------------------------------------------------------------------------------------------------------------------------------

local sapp      = require("sokol_app")
local stb 		= require("stb")
local utils 	= require("lua.utils")
local ffi 		= require("ffi")

-----------------------------------------------------------------------------------------------------------------------------------

local tinsert 			= table.insert 
local tremove 			= table.remove 

-----------------------------------------------------------------------------------------------------------------------------------

ffi.cdef [[
typedef struct {
    FONScontext* fons;
    float dpi_scale;
} state_t;
]]

-----------------------------------------------------------------------------------------------------------------------------------
-- The render api is intended as a render interface that can be replaced
local render_api 		= {
	left 		= 0,
	top 		= 0,
}

local cached_data 		= {}

-----------------------------------------------------------------------------------------------------------------------------------

local state 			= ffi.new("state_t")
local linear_sampler 	= ffi.new("sg_sampler[1]")

-----------------------------------------------------------------------------------------------------------------------------------
-- Helper methods

local defaultalign 		= bit.bor(fs.FONS_ALIGN_LEFT, fs.FONS_ALIGN_TOP)
local defaultcolor 		= { r=0, g=0, b=0, a=255.0 }

local function getRGBAColor( hexColor )

	return {
		a 	= bit.rshift(bit.band(hexColor, 0xFF000000), 24) / 255.0,
		b 	= bit.rshift(bit.band(hexColor, 0xFF0000), 16) / 255.0,
		g 	= bit.rshift(bit.band(hexColor, 0xFF00), 8) / 255.0,
		r 	= bit.band(hexColor, 0xFF) / 255.0,
	}
end

-----------------------------------------------------------------------------------------------------------------------------------

local lines = ffi.new("sgp_line[4]")
local function drawRect( x, y, w, h )

    sgp.sgp_push_transform()
	lines[0].a.x = x
	lines[0].a.y = y 
	lines[0].b.x = x + w
	lines[0].b.y = y 

	lines[1].a.x = x + w
	lines[1].a.y = y
	lines[1].b.x = x + w
	lines[1].b.y = y + h

	lines[2].a.x = x + w
	lines[2].a.y = y + h
	lines[2].b.x = x 
	lines[2].b.y = y + h

	lines[3].a.x = x
	lines[3].a.y = y + h 
	lines[3].b.x = x 
	lines[3].b.y = y 

    sgp.sgp_draw_lines(lines, 4)
    sgp.sgp_pop_transform()
end

-----------------------------------------------------------------------------------------------------------------------------------

local function drawQuad(x, y, w, h)

    sgl.sgl_begin_quads()
    sgl.sgl_v2f_c3b( x, y,  255, 255, 0)
    sgl.sgl_v2f_c3b(  x+w, y,  0, 255, 0)
    sgl.sgl_v2f_c3b(  x+w,  y+h,  0, 0, 255)
    sgl.sgl_v2f_c3b( x,  y+h,  255, 0, 0)
	sgl.sgl_end()
end

-----------------------------------------------------------------------------------------------------------------------------------

local function colorRect(x, y, w, h, color)
	color = color or { r = 1.0, g = 0.0, b = 1.0, a = 1.0 }
	sgp.sgp_push_transform()
	sgp.sgp_set_color(color.r * 0.00390625, color.g * 0.00390625, color.b * 0.00390625, color.a * 0.00390625)
	sgp.sgp_draw_filled_rect(x, y, w, h)
	sgp.sgp_pop_transform()
end 

-----------------------------------------------------------------------------------------------------------------------------------
-- Makes a button type rect - can have sharp corners or curved.
local pbuffer 	= {}
local function colorBorderedRect( x, y, w, h, color, cr )

	local hw = w * 0.5
	local hh = h * 0.5
    sgp.sgp_push_transform()
    sgp.sgp_translate(x + hw, y + hh)
    sgp.sgp_set_color(color.r * 0.00390625, color.g * 0.00390625, color.b * 0.00390625, color.a * 0.00390625)

	local pbuffid = string.format("%d_%d_%d_%d_%d", x, y, w, h, cr)
	local points_buffer = pbuffer[pbuffid] 
	
	if(points_buffer == nil) then 
		local div = 1.0 / 4
		if(cr > 16) then div = 8 end

		points_buffer = ffi.new("sgp_vec2[?]", 28 * 3 + 1)
		local idx = 0
		local sx, sy = 0, 0
		points_buffer[idx] = { x=sx, y=sy }

		local n90 = math.pi * 0.5
		local step = math.pi * 0.5 * div
		-- Top right corner
		local crclist = {
			{ hw - cr, hh - cr, 1, 1, 0, n90, step },
			{ - hw + cr, hh - cr, -1, 1, n90, 0, -step },
			{ - hw + cr, - hh + cr, -1, -1, 0, n90, step},
			{ hw - cr, - hh + cr, 1, -1, n90, 0, -step },
		}

		local theta = 0
		
		for cnrs = 1, 4 do 
			local crc = crclist[cnrs]
			for theta = crc[5], crc[6], crc[7] do 
				points_buffer[idx] = { x = crc[1] + crc[3] * cr*math.cos(theta), y= crc[2] + crc[4] * cr*math.sin(theta)}
				idx = idx + 1
				if (idx % 3 == 1) then 
					points_buffer[idx] = { x=sx, y=sy }
					idx = idx + 1
				end
			end
		end
		theta = 0
		local crc = crclist[1]
		points_buffer[idx] = { x = crc[1] + crc[3] * cr*math.cos(theta), y= crc[2] + crc[4] * cr*math.sin(theta)}

		pbuffer[pbuffid] = points_buffer
	end

	sgp.sgp_draw_filled_triangles_strip(points_buffer, 28 * 3 + 1)
	sgp.sgp_pop_transform()
end

-----------------------------------------------------------------------------------------------------------------------------------

local destrect = ffi.new("sgp_rect")
local src_images 	= {}
local function texRect(imageid, x, y, w, h, color)
	color = color or { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
	sgp.sgp_push_transform()
	sgp.sgp_set_color(color.r, color.g, color.b, color.a)
	destrect.x = x 
	destrect.y = y 
	destrect.w = w 
	destrect.h = h
	sgp.sgp_set_image(0, imageid)
	sgp.sgp_set_sampler(0, linear_sampler);

	sgp.sgp_draw_textured_rect(0, destrect, src_images[imageid].rect)
	sgp.sgp_reset_image(0)
	sgp.sgp_reset_sampler(0)
	sgp.sgp_pop_transform()
end 

-----------------------------------------------------------------------------------------------------------------------------------

local function load_image( filename) 
    local width = ffi.new("int[1]", {0})
	local height = ffi.new("int[1]", {0})
	local channels = ffi.new("int[1]", {0})

    local data = stb.stbi_load(filename, width, height, channels, 4)
    local img = ffi.new("sg_image")
    if (data == nil) then  return img end

    local image_desc = ffi.new("sg_image_desc[1]")
    image_desc[0].width = width[0]
    image_desc[0].height = height[0]
    image_desc[0].data.subimage[0][0].ptr = data;
    image_desc[0].data.subimage[0][0].size = (width[0] * height[0] * 4)
    local img = sg.sg_make_image(image_desc)
    stb.stbi_image_free(data)
    return img, width[0], height[0]
end

-----------------------------------------------------------------------------------------------------------------------------------

local fontHeight = ffi.new("float[1]", {0.0})
local function getTextSize( text )
	local ptr = ffi.cast("const char *", ffi.string(text))
	local w = fs.fonsTextBounds(state.fons, 0, 0, ptr, nil, nil) / render_api.fontsize
	fs.fonsVertMetrics(state.fons, nil, nil, fontHeight)
	local h = fontHeight[0] / render_api.fontsize
	return w, h
end

-----------------------------------------------------------------------------------------------------------------------------------

local lineCache = {}
local function calcMultiLines(x, y, textw, texth, wrapwidth, text )
	
	local id = string.format("%s %d",text, wrapwidth)
	if(lineCache[id]) then return lineCache[id] end

	-- Wrapping involves not clipping the text. So first split the text into a number of parts 
	-- separated by spaces (words). Save in a cache, so we dont do this too much.
	local parts = {}
	local words = utils.csplit(text, " ")
	local sw, sh = getTextSize(" ")
	local cw, ch = 0, 0, 0 -- Track width and height
	local parttext = ""
	for i,w in ipairs(words) do 
		local ww, wh = getTextSize(w)
		if(x + cw + ww > wrapwidth) then
			tinsert( parts, { x=0, y=ch, text=parttext } )
			parttext = ""
			cw = 0
			ch = ch + wh
		end
		cw = cw + ww + sw 
		parttext = string.format("%s%s ", parttext, w)
	end

	if(#parttext > 0) then 
		tinsert( parts, { x=0, y=ch, text=parttext } )
	end

	lineCache[id] = parts
	return parts
end

-----------------------------------------------------------------------------------------------------------------------------------
-- Setup the rendering context - renderCtx. 
--   NOTE: This may change - renderCtx islikely to become something else.

render_api.setup = function(self)

	state.dpi_scale = sapp.sapp_dpi_scale()
	render_api.fontsize = state.dpi_scale
	render_api.window = { x = 0, y = 0 }

	self.renderCtx.fonts = {}
	self.renderCtx.window = render_api.window

	local fonsdesc = ffi.new("sfons_desc_t[1]")
	fonsdesc[0].width 	= 512 
	fonsdesc[0].height 	= 512 

	-- TODO: Make font management much simpler (need a font manager)
	state.fons = fs.sfons_create(fonsdesc)
	
	self.renderCtx.fonts["Regular"] 	= fs.fonsAddFont(state.fons, "sans", "projects/browser/data/fonts/LiberationSerif-Regular.ttf")
	self.renderCtx.fonts["Bold"] 		= fs.fonsAddFont(state.fons, "sans-bold", "projects/browser/data/fonts/LiberationSerif-Bold.ttf")
	self.renderCtx.fonts["Italic"] 		= fs.fonsAddFont(state.fons, "sans-italic", "projects/browser/data/fonts/LiberationSerif-Italic.ttf")
	self.renderCtx.fonts["BoldItalic"] 	= fs.fonsAddFont(state.fons, "sans-bolditalic", "projects/browser/data/fonts/LiberationSerif-BoldItalic.ttf")

	self.renderCtx.fontsize = render_api.fontsize

	self.renderCtx.getstyle = function( style )

		local fontface = style.fontface or "Regular"
		if(fontface == "Regular") then 
			if(style.fontweight == 1) then fontface = "Bold" end 
			if(style.fontstyle == 1) then fontface = "Italic" end 
			if(style.fontstyle == 1 and style.fontweight == 1) then fontface = "BoldItalic" end 
		end
		return self.renderCtx.fonts[fontface]
	end 	

	self.renderCtx.setstyle = function( style )
		local fontface = self.renderCtx.getstyle(style)
		fs.fonsSetFont(state.fons, fontface)
	end 

	self.renderCtx.unsetstyle = function()
	end 

	self.renderCtx.add_font = function(fontname, fontfilename )

		local fontloaded = fs.fonsAddFont(state.fons, fontname, fontfilename)
		assert(fontloaded > -1)
		self.renderCtx.fonts[fontname] = fontloaded
	end

	self.renderCtx.fsctx = fsctx
	-- imgui.set_style_color(imgui.ImGuiCol_WindowBg, 1.00, 1.00, 1.00, 1.00)
	-- imgui.set_style_color(imgui.ImGuiCol_Text, 0.0, 0.0, 0.0, 1.00)
	-- imgui.set_style_color(imgui.ImGuiCol_TextDisabled, 0.60, 0.60, 0.60, 1.00)
	-- imgui.set_style_color(imgui.ImGuiCol_FrameBg, 0.93, 0.93, 0.96, 1.00)
	fs.fonsSetAlign(state.fons, bit.bor(fs.FONS_ALIGN_LEFT, fs.FONS_ALIGN_TOP))

    -- create linear sampler
    local linear_sampler_desc = ffi.new("sg_sampler_desc[1]")
    linear_sampler_desc[0].min_filter = sg.SG_FILTER_LINEAR
    linear_sampler_desc[0].mag_filter = sg.SG_FILTER_LINEAR
    linear_sampler_desc[0].wrap_u = sg.SG_WRAP_CLAMP_TO_EDGE
    linear_sampler_desc[0].wrap_v = sg.SG_WRAP_CLAMP_TO_EDGE
    linear_sampler = sg.sg_make_sampler(linear_sampler_desc)
    if (sg.sg_query_sampler_state(linear_sampler) ~= sg.SG_RESOURCESTATE_VALID) then 
        print("failed to create linear sampler")
        exit(-1)
	end
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
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Get the size of the text - returns width, and height
render_api.text_getsize = function( text, fontscale, fontface, wrap_size )

	fs.fonsSetSize(state.fons, fontscale * render_api.fontsize)
	fs.fonsSetFont(state.fons, fontface)
	local w, h = getTextSize(text)
	
	if(w > wrap_size) then 
		local lines = math.floor(w / wrap_size) + 1
		w = wrap_size
		h = lines * h 
	end 
	return w , h 
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Set the scale of the text for the next text render
render_api.set_window_font_scale = function( fontscale)

	fs.fonsSetSize(state.fons, fontscale * render_api.fontsize)
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Set the cursor position for new rendering widget
render_api.set_cursor_pos = function( left, top )

	render_api.left = left 
	render_api.top = top
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Render text using the specified interface
render_api.text = function( text, wrapwidth, align )

	align = align or "left"
	render_api.set_text_align(align)
	local x, y = render_api.left + render_api.window.x, render_api.top + render_api.window.y
	local w, h = getTextSize(text)

	-- If align is center then text is positionsed by its middle. Add half text width!
	if(align == "center") then x = x + w/2 end

	if(w > wrapwidth) then 
		local parts  = calcMultiLines(x, y, w, h, wrapwidth, text)
		--fs.fonsSetAlign(state.fons, bit.bor(fs.FONS_ALIGN_LEFT, fs.FONS_ALIGN_TOP))
		for i,p in ipairs(parts) do 
			-- Alignment needs to be done by the css/style
			fs.fonsDrawText(state.fons, x + p.x, y + p.y, p.text, nil)
		end
	else
		-- Alignment needs to be done by the css/style
		--fs.fonsSetAlign(state.fons, bit.bor(fs.FONS_ALIGN_LEFT, fs.FONS_ALIGN_TOP))
		fs.fonsDrawText(state.fons, x, y, text, nil)
	end
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Set the text alignment of the following text
render_api.set_text_align = function( align )

	if(align == "center") then 
		align = bit.bor(fs.FONS_ALIGN_CENTER, fs.FONS_ALIGN_TOP)
	elseif(alight == "right") then 
		align = bit.bor(fs.FONS_ALIGN_RIGHT, fs.FONS_ALIGN_TOP)
	else 
		align = bit.bor(fs.FONS_ALIGN_LEFT, fs.FONS_ALIGN_TOP)
	end

	fs.fonsSetAlign(state.fons, align)
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Set the color of the following text
render_api.set_text_color = function( color )
	color = color or defaultcolor
	fs.fonsSetColor(state.fons, fs.sfons_rgba(color.r, color.g, color.b, color.a))
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Render text using the specified interface
render_api.text_colored = function( text, r, g, b, a)

	local x, y = render_api.left + render_api.window.x, render_api.top + render_api.window.y
	fs.fonsSetColor(state.fons, fs.sfons_rgba(r, g, b, a))
	fs.fonsDrawText(state.fons, x, y, text, nil)
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Render buttons using the specified interface
render_api.button = function( text, w, h, color, cnr )

	local cnr = cnr or 0
	local x, y = render_api.left + render_api.window.x, render_api.top + render_api.window.y
	-- imgui.button( text, w, h ) 
	colorBorderedRect( x, y, tonumber(w), tonumber(h), color, cnr)
	-- colorRect( x, y, tonumber(w), tonumber(h), color)
	fs.fonsDrawText(state.fons, x, y, text, nil)
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
	cachedid, w, h = load_image(filename) 
	local srcrect = ffi.new("sgp_rect", { 0, 0, w, h })
	src_images[cachedid] = { rect = srcrect }
	cached_data[filename] = cachedid
	return cachedid
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Render images using the specified interface
render_api.image_add = function( imgid, w, h  )

	-- imgui.image_add( imgid, w, h ) 
	local x, y = render_api.left + render_api.window.x, render_api.top + render_api.window.y
	texRect(imgid, x, y, w, h)
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Draw rectangles

render_api.draw_rect = function( x, y, w, h, color )

	local c = color or defaultcolor
	if(type(c) == "number") then c = getRGBAColor(color) end
	-- print( c.r, c.g, c.b, c.a )
	sgp.sgp_set_color( c.r, c.g, c.b, c.a )
    drawRect(x, y, tonumber(w), tonumber(h))
	-- print( string.format("%03d %03d %03d %03d  %04x", x, y, w, h, color) )
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Draw rectangles filled

render_api.draw_rect_filled = function( x, y, w, h, color )

	local c = color or defaultcolor
	if(type(c) == "number") then c = getRGBAColor(color) end
	-- print( c.r, c.g, c.b, c.a )
	sgp.sgp_set_color( c.r, c.g, c.b, c.a )
    colorRect(x, y, tonumber(w), tonumber(h), color)
	-- print( string.format("%03d %03d %03d %03d  %04x", x, y, w, h, color) )
end

-----------------------------------------------------------------------------------------------------------------------------------

return render_api

-----------------------------------------------------------------------------------------------------------------------------------
