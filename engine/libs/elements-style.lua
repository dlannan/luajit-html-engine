local rapi 		    = require("engine.libs.htmlrender-api")
local layout        = require("engine.libs.htmllayout")
local styleprops    = require("engine.libs.styles.cssprop-handlers")

local utils 		= require("lua.utils")

local tinsert		= table.insert 
local tremove 		= table.remove

----------------------------------------------------------------------------------

local FONT_SIZES = {

	h1		= 24.0,
	h2 		= 20.0,
	h3 		= 16.0,
	h4 		= 14.0,
	h5 		= 12.0,
	h6 		= 10.0,

	p 		= 14.0,
	normal	= 12.0,
	blockquote = 12.0,
}

----------------------------------------------------------------------------------

local TEXT_CONST = {

	NONE 		= 0,
	TAB 		= FONT_SIZES.p * 2.0,

	MARGINS 	= 1.0 / 1.1875,
	HEADINGS 	= 1.0 / 1.8,
	BLOCK		= 0.8,
}

----------------------------------------------------------------------------------

local TEXT_ALIGN = {

    LEFT        = 1,
    CENTER      = 2, 
    RIGHT       = 4,
    TOP         = 8,
    MIDDLE      = 16,
    BOTTOM      = 32,
}

----------------------------------------------------------------------------------
-- Layout display types
local DISPLAY_TYPES = {
	inline 			= 1,
	inlineblock		= 2,
	block			= 3,
	none			= 4,
	table			= 5,
	flex			= 6,
	grid			= 7,
}

----------------------------------------------------------------------------------
-- These tags force an inline to break. 
-- They should always break the line _before_ the element is processed.
local DEFAULT_DISPLAY = {
	html 	  = "block",
	body 	  = "block",
	div       = "block",
	p         = "block",
	span      = "inline",
	button    = "inline-block",
	br        = "inline",  -- with special behavior
	table     = "table",
	tr        = "table-row",
	td        = "table-cell",
	th        = "table-cell",
	ul        = "block",
	li        = "list-item",
	img       = "inline-block",
	section   = "block",
	header    = "block",
	footer    = "block",
	h1        = "block",
	h2        = "block",
	h3        = "block",
	h4        = "block",
	h5        = "block",
	h6        = "block",
	blockquote = "block",
	pre        = "block",
	form       = "block",
	hr         = "block",
	-- etc.
}

----------------------------------------------------------------------------------
-- example categories
local DisplayCategory = {
	BLOCK = 1,
	INLINE = 2,
	INLINE_BLOCK = 3,
	TABLE = 4,
	TABLE_ROW = 5,
	TABLE_CELL = 6,
}
  
----------------------------------------------------------------------------------

local DISPLAY_MAP = {
	div     = 'block',
	p       = 'block',
	span    = 'inline',
	button  = 'inline-block',
	table   = 'table',
	tr      = 'table-row',
	td      = 'table-cell',
	th      = 'table-cell',
	br      = 'inline',
	ul      = 'block',
	li      = 'list-item',
	img     = 'inline-block',
}

----------------------------------------------------------------------------------

local DISPLAY_CATEGORY_MAP = {
	["block"]         = DisplayCategory.BLOCK,
	["inline"]        = DisplayCategory.INLINE,
	["inline-block"]  = DisplayCategory.INLINE_BLOCK,
	["table"]         = DisplayCategory.TABLE,
	["table-row"]     = DisplayCategory.TABLE_ROW,
	["table-cell"]    = DisplayCategory.TABLE_CELL,
	["none"]          = DisplayCategory.NONE, -- optional
}
  
local function categorize_display(display_string)
	return DISPLAY_CATEGORY_MAP[display_string] or DisplayCategory.INLINE  -- fallback default
end

----------------------------------------------------------------------------------

local defaultlinesize 	= FONT_SIZES.normal
local defaultheight 	= FONT_SIZES.normal

----------------------------------------------------------------------------------

local function defaultmargin( style ) 

	return { 
		top 	= style.textsize * TEXT_CONST.MARGINS, 
		bottom 	= style.textsize * TEXT_CONST.MARGINS,
		left 	= 2,
		right 	= 2,
	}
end 

----------------------------------------------------------------------------------

local function defaultpadding( style ) 

	return { 
		top 	= 0, 
		bottom 	= 0,
		left 	= 0,
		right 	= 0,
	}
end 

----------------------------------------------------------------------------------

local function defaultborder( style ) 

	return { 
		top 	= 0, 
		bottom 	= 0,
		left 	= 0,
		right 	= 0,
	}
end 

----------------------------------------------------------------------------------

local defaultstyle = { 
	textsize    = FONT_SIZES.normal, 
	linesize    = FONT_SIZES.normal, 
	maxlinesize = 0, 
	width       = 0, 
	height      = 0,
}

defaultstyle.margin      = defaultmargin(defaultstyle)
defaultstyle.padding     = defaultpadding(defaultstyle)
defaultstyle.border      = defaultborder(defaultstyle)

----------------------------------------------------------------------------------

local function getmargin( style, topbottom, sides )

	local fr = topbottom or 0
	local fs = sides or 0
	return { 
		top 	= style.textsize * fr, 
		bottom 	= style.textsize * fr,
		left 	= fs, right = fs 
	}
end

----------------------------------------------------------------------------------

local function extendmargin( style, topbottom, sides )

	local fr = topbottom or 0
	local fs = sides or 0
	local mgn = style.margin or defaultstyle.margin
	return { 
		top 	= mgn.top + style.textsize * fr, 
		bottom 	= mgn.bottom + style.textsize * fr,
		left 	= mgn.left + fs, right = mgn.right + fs 
	}
end

----------------------------------------------------------------------------------

local function style_setmargins( style, left, top, right, bottom)
	style.margin.top 		= top
	style.margin.bottom 	= bottom
	style.margin.left 		= left
	style.margin.right 		= right
end

----------------------------------------------------------------------------------

local function gettextsize( g, style, text )
    
	local fontface 	= g.ctx.getstyle(style)
	local fontscale = style.textsize/g.ctx.fontsize
	local wrapwidth = (g.frame.width - g.cursor.left - style.margin.right) / (g.ctx.fontsize )
	local w, h 		= rapi.text_getsize(text, fontscale, fontface, wrapwidth)

	style.width 	= w * g.ctx.fontsize
	style.height 	= h * g.ctx.fontsize
	return w, h
end

----------------------------------------------------------------------------------

local function style_setpadding( style, left, top, right, bottom)
	style.padding.top 		= top
	style.padding.bottom 	= bottom
	style.padding.left 		= left
	style.padding.right 	= right
end

----------------------------------------------------------------------------------

local function style_setborders( style, left, top, right, bottom)
	style.border.top 		= top
	style.border.bottom 	= bottom
	style.border.left 		= left
	style.border.right 		= right
end

----------------------------------------------------------------------------------

local function style_settextalignment( style, align)
    style.text_align        = align or TEXT_ALIGN.LEFT
end

----------------------------------------------------------------------------------

local function style_defaultbutton( style )

	style_setmargins(style, 0, 0, 0, 0)
	style_setpadding(style, 4, 1, 4, 1)
	style_setborders(style, 2, 1, 2, 1)
	style["border-radius"] = style["border-radius"] or 3
end

----------------------------------------------------------------------------------

local function checkmargins( g, style )

	-- Check if previous margin is big enough for this style otherwise add difference.
	local margin 	= style.margin
	if g.cursor.element_top then 
		local prev_margin = g.cursor.top - g.cursor.element_top
		if prev_margin < margin.top then 
			g.cursor.top = g.cursor.top + (margin.top - prev_margin)
		end
		g.cursor.element_top = nil
	else 
		g.cursor.top = g.cursor.top + margin.top
	end

	if g.cursor.element_left then 
		local prev_margin = g.cursor.left - g.cursor.element_left
		if prev_margin < margin.left then 
			g.cursor.left = g.cursor.left + (margin.left - prev_margin)
		end
	else 
		g.cursor.left = g.cursor.left + margin.left
	end
end 

----------------------------------------------------------------------------------

local function applypadding( g, style, element )
	g.cursor.left = g.cursor.left + style.padding.left + style.border.left
	g.cursor.top = g.cursor.top + style.padding.top + style.border.top
end

----------------------------------------------------------------------------------

local function applyspacing( g, style, element )
	element.width = element.width + style.padding.left + style.padding.right 
	element.height = element.height + style.padding.top + style.padding.bottom
	g.cursor.top = g.cursor.top - style.padding.top - style.border.top
	g.cursor.left = g.cursor.left + style.padding.right + style.padding.left
end

----------------------------------------------------------------------------------

local function styleopen( g, style, xml )

    -- TODO: This is a little slow, would prefer direct prop events/handler calls. 
    --       Future work will remove this.
    for k,v in pairs(style) do 
        local sprop = styleprops[k]
        if(sprop and sprop.open_handler ) then 
            --- dostyle prop handling here. 
            sprop.open_handler( g, style, xml )
        end
    end
end

----------------------------------------------------------------------------------

local function styleclose( g, style, xml )

    local element 		= layout.getelement(style.elementid)
	local dim 			= layout.getelementdim(element.id)
    local pdim 			= layout.getelementdim(element.pid)

    for k,v in pairs(style) do 
        local sprop = styleprops[k]
        if( sprop and sprop.closed_handler ) then 
            --- dostyle prop handling here. 
            sprop.closed_handler( g, style, element, dim, pdim )
        end
    end

	-- print(element.etype, dim.left, dim.top, dim.width, dim.height)
	element.pos.left = dim.minX
	element.pos.top = dim.minY
	element.width = dim.maxX-dim.minX
	element.height = dim.maxY - dim.minY
	layout.updateelement(element.id, element)
end

----------------------------------------------------------------------------------

local function styleinput( style )
	style_setmargins(style, 0, 0, 0, 0)
	style_setpadding(style, 4, 2, 4, 2)
	style_setborders(style, 1, 1, 1, 1)
end	

----------------------------------------------------------------------------------

local function getformatted(g, style, text)

	if text and style.list then 
		if(style.list.ltype == "ordered") then 
			text = string.format("%s.  %s", tostring(style.list.index), text) 
		elseif(style.list.ltype == "unordered") then 
			text = string.format("%s  %s", tostring(style.list.index), text) 
		end
	end
	return text
end

----------------------------------------------------------------------------------

local function newlinebox(g, style)

	g.cursor.top 	= g.cursor.top + style.linesize
	-- Add in the collated margin from the bottom
	g.cursor.element_top = g.cursor.top
	g.cursor.top 	= g.cursor.top + style.margin.bottom

	-- Return to leftmost + parent margin
	g.cursor.left 	= g.frame.left + style.margin.left
	g.cursor.element_left = g.cursor.left
end 

----------------------------------------------------------------------------------

local function is_linebox_open( g )
	if( g.lineboxes == nil or #g.lineboxes == 0) then 
		return nil 
	else 
		return true 
	end 
end

----------------------------------------------------------------------------------

local function start_linebox( g, style )

	local lineboxes = g.lineboxes or {} -- Auto create a linebox stack 
	local newlinebox = { 
		elements = {}, 
		left 		= g.cursor.left, 
		top 		= g.cursor.top, 
		frameleft 	= g.frame.left, 
		linesize 	= style.linesize,
		display 	= style.display or "inline",
	}
	tinsert(lineboxes, newlinebox )
	g.lineboxes = lineboxes
end

----------------------------------------------------------------------------------
-- Pops the linebox from the linebox stack. Steps the line
local function flush_linebox(g, style)
	if not is_linebox_open(g) then
		return  -- nothing to flush, no line stepping needed
	end	
	
	local lbox = tremove(g.lineboxes)
	-- process_linebox(g, style, lbox) -- This recalcs linebox elements and updates layouts for each element

	g.cursor.top 	= g.cursor.top + lbox.linesize
	-- Add in the collated margin from the bottom
	g.cursor.element_top = g.cursor.top
	g.cursor.top 	= g.cursor.top + style.margin.bottom

	-- Return to leftmost + parent margin
	g.cursor.left 	= g.frame.left + style.margin.left
	g.cursor.element_left = g.cursor.left

	return lbox.display
end

----------------------------------------------------------------------------------

local function handle_display(g, style, xml)
    -- 1. Determine raw display value for this tag
    local label = xml.label
    local raw_display = DEFAULT_DISPLAY[label] or "inline"  -- fallback to inline

    -- 2. Check for CSS override in style
    if style.display then
        raw_display = style.display
		print(raw_display)
    end

    -- 3. Determine the **current context** / parent display
    local parent_display = style.pstyle.display  -- e.g. "block" or "inline"
    local parent_category = categorize_display(parent_display)
    local current_category = categorize_display(raw_display)

	-- print(label, raw_display, parent_category, current_category)

    -- 4. Handle transitions based on parent / preceding display
    -- (For example: if parent is inline but child is block, you need to flush etc.)
    if parent_category == DisplayCategory.INLINE then
        if current_category == DisplayCategory.BLOCK then
            -- inline → block: must flush the current linebox in the parent
            flush_linebox(g, style)
        end
    elseif parent_category == DisplayCategory.BLOCK then
        -- parent is block-level container
        if current_category == DisplayCategory.INLINE or current_category == DisplayCategory.INLINE_BLOCK then
            -- okay: inline children inside block
            -- maybe start a new linebox if none is open
            if not is_linebox_open(g) then
				start_linebox(g, style)
            end
        elseif current_category == DisplayCategory.BLOCK then
            -- block child inside block: ensure current linebox flushed
            if is_linebox_open(g) then
                flush_linebox(g, style)
            end
        elseif current_category == DisplayCategory.TABLE then
            -- block → table: treat table like a block for transition
            if is_linebox_open(g) then
                flush_linebox(g, style)
            end
        end
    end

	style.display = raw_display

    -- 6. Possibly set up layout state for this element
    -- e.g. if table, push a new layout context; if inline-block, set inline-block state, etc.
    -- setup_layout_for_display(g, style, xml)

    -- 7. Return if needed, or push style/context so child processors use it
    return style.display
end

	
----------------------------------------------------------------------------------

return {

    FONT_SIZES              = FONT_SIZES,
    TEXT_CONST              = TEXT_CONST,
    TEXT_ALIGN              = TEXT_ALIGN,

	DISPLAY_TYPES			= DISPLAY_TYPES,
	BLOCK_TAGS				= BLOCK_TAGS,
	DISPLAY_MAP				= DISPLAY_MAP,

	defaultstyle			= defaultstyle,
	 
    defaultmargin           = defaultmargin,
    defaultpadding          = defaultpadding,
    defaultborder           = defaultborder, 

	defaultlinesize			= defaultlinesize,
	defaultheight 			= defaultheight,

	defaultbutton			= style_defaultbutton,

    getmargin               = getmargin,
	extendmargin			= extendmargin,
    setmargins              = style_setmargins,
    gettextsize             = gettextsize,
    setpadding              = style_setpadding,
    setborders              = style_setborders,
    checkmargins            = checkmargins,

	getformatted 			= getformatted,

	applyspacing		 	= applyspacing,
	applypadding			= applypadding,

    close                   = styleclose,
    open                    = styleopen,

	styleinput				= styleinput,

	newlinebox				= newlinebox,
	handle_display			= handle_display,
}

----------------------------------------------------------------------------------
