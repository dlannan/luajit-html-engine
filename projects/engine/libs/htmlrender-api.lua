-- htmlgeom is the html geometry object used to generate element/cell information for layout_changed
-----------------------------------------------------------------------------------------------------------------------------------

local tinsert 		= table.insert 
local tremove 		= table.remove 

-- The render api is intended as a render interface that can be replaced
local render_api 		= {}

local cached_data 		= {}

-----------------------------------------------------------------------------------------------------------------------------------
-- Setup the rendering context - renderCtx. 
--   NOTE: This may change - renderCtx islikely to become something else.

render_api.setup = function(self)
	local fontsizebase = 30.0
	local fontsize = 1.0

	-- Load a default font 
	imgui.set_defaults()
	
	self.renderCtx.fonts = {}
	self.renderCtx.window = { x = 50, y = 50 }

	-- TODO: Make font management much simpler (need a font manager)
	local regular_data, error = sys.load_resource("/data/fonts/LiberationSerif-Regular.ttf")
	self.renderCtx.fonts["Regular"] = imgui.font_add_ttf_data(regular_data, #regular_data, fontsize, fontsizebase)
	local bold_data, error = sys.load_resource("/data/fonts/LiberationSerif-Bold.ttf")
	self.renderCtx.fonts["Bold"] = imgui.font_add_ttf_data(bold_data, #bold_data, fontsize, fontsizebase)
	local italic_data, error = sys.load_resource("/data/fonts/LiberationSerif-Italic.ttf")
	self.renderCtx.fonts["Italic"] = imgui.font_add_ttf_data(italic_data, #italic_data, fontsize, fontsizebase)
	local bolditalic_data, error = sys.load_resource("/data/fonts/LiberationSerif-BoldItalic.ttf")
	self.renderCtx.fonts["BoldItalic"] = imgui.font_add_ttf_data(bolditalic_data, #bolditalic_data, fontsize, fontsizebase)
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
		imgui.font_push(fontface)
	end 
	self.renderCtx.unsetstyle = function()
		imgui.font_pop()
	end 

	imgui.set_style_color(imgui.ImGuiCol_WindowBg, 1.00, 1.00, 1.00, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_Text, 0.0, 0.0, 0.0, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_TextDisabled, 0.60, 0.60, 0.60, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_FrameBg, 0.93, 0.93, 0.96, 1.00)

end 

-----------------------------------------------------------------------------------------------------------------------------------
--  Prepare the window frame for rendering to (per frame)
render_api.start = function( self )

	local w, h = window.get_size()
	imgui.set_mouse_input(
		self.mouse.x,
		h - self.mouse.y,
		self.mouse.buttons[LEFT_MOUSE] or 0,
		self.mouse.buttons[MIDDLE_MOUSE] or 0,
		self.mouse.buttons[RIGHT_MOUSE] or 0,
		self.mouse.wheel
	)
		
	local flags = imgui.WINDOWFLAGS_NOTITLEBAR
	--	flags = bit.bor(flags, imgui.WINDOWFLAGS_NOBACKGROUND)
	flags = bit.bor(flags, imgui.WINDOWFLAGS_NORESIZE)
	flags = bit.bor(flags, imgui.WINDOWFLAGS_NOMOVE)

	imgui.set_display_size(w, h)

	imgui.set_next_window_size(w/2, h/1.2 )
	imgui.set_next_window_pos( self.renderCtx.window.x, self.renderCtx.window.y )

	imgui.begin_window("Main", true, flags )
end

-----------------------------------------------------------------------------------------------------------------------------------
-- Complete the window frame for rendering to (per frame) and then apply input updates
render_api.finish = function( self )
	
	imgui.end_window()
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Get the size of the text - returns width, and height
render_api.text_getsize = function( text, fontscale, fontface, wrap_size )

	return imgui.text_getsize(text, fontscale, fontface, wrap_size)
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Set the scale of the text for the next text render
render_api.set_window_font_scale = function( fontscale)

	imgui.set_window_font_scale( fontscale )
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Set the cursor position for new rendering widget
render_api.set_cursor_pos = function( left, top )

	imgui.set_cursor_pos(left, top)
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Render text using the specified interface
render_api.text = function( text, wrapwidth )

	imgui.text( text, wrapwidth )
end


-----------------------------------------------------------------------------------------------------------------------------------
--  Render text using the specified interface
render_api.text_colored = function( text, r, g, b, a)

	imgui.text_colored( text, r, g, b, a )
end
-----------------------------------------------------------------------------------------------------------------------------------
--  Render buttons using the specified interface
render_api.button = function( text, w, h )

	imgui.button( text, w, h ) 
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Render input text field
render_api.input_text = function( text, label )

	-- No labels by default
	label = label or ""
	return imgui.input_text( label, text ) 
end


-----------------------------------------------------------------------------------------------------------------------------------
--  load images using the specified interface
render_api.image_load = function( filename )

	local cachedid = cached_data[filename]
	if(cachedid) then return cachedid end
	local loadeddata = sys.load_resource(filename)
	cachedid = imgui.image_load_data(filename, loadeddata, #loadeddata) 
	cached_data[filename] = cachedid
	return cachedid
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Render images using the specified interface
render_api.image_add = function( imgid, w, h  )

	imgui.image_add( imgid, w, h ) 
end

-----------------------------------------------------------------------------------------------------------------------------------
--  Draw rectangles
render_api.draw_rect = function( x, y, w, h, color )

	imgui.draw_rect( x, y, w, h, color) 
end

-----------------------------------------------------------------------------------------------------------------------------------

return render_api

-----------------------------------------------------------------------------------------------------------------------------------
