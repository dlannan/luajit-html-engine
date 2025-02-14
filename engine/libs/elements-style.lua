local rapi 		    = require("engine.libs.htmlrender-api")
local layout        = require("engine.libs.htmllayout")
local styleprops    = require("engine.libs.styles.cssprop-handlers")

local utils 		= require("lua.utils")

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

return {

    FONT_SIZES              = FONT_SIZES,
    TEXT_CONST              = TEXT_CONST,
    TEXT_ALIGN              = TEXT_ALIGN,

	defaultstyle			= defaultstyle,
	 
    defaultmargin           = defaultmargin,
    defaultpadding          = defaultpadding,
    defaultborder           = defaultborder, 

	defaultlinesize			= defaultlinesize,
	defaultheight 			= defaultheight,

	defaultbutton			= style_defaultbutton,

    getmargin               = getmargin,
    setmargins              = style_setmargins,
    gettextsize             = gettextsize,
    setpadding              = style_setpadding,
    setborders              = style_setborders,
    checkmargins            = checkmargins,

	applyspacing		 	= applyspacing,
	applypadding			= applypadding,

    close                   = styleclose,
    open                    = styleopen,
}

----------------------------------------------------------------------------------
