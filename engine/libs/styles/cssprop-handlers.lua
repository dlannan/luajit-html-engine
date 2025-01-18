-- A list of the most common properties that I will implement that should result in a 
--  reasonably good coverage of general css for html rendering.

local css_properties = {
    -- Text and Fonts
    ["color"]            = require("engine.libs.styles.handler-color"),    -- Text color  - this is directly used in the rapi (might extract later)
    ["font-family"]      = require("engine.libs.styles.handler-font-family"),    -- Font family
    ["font-size"]        = require("engine.libs.styles.handler-font-size"),      -- Font size
    ["font-weight"]      = require("engine.libs.styles.handler-font-weight"),    -- Font weight (bold, normal, etc.)
    ["font-style"]       = require("engine.libs.styles.handler-font-style"),     -- Font style (italic, normal)
    ["line-height"]      = require("engine.libs.styles.handler-line-height"),    -- Line height
    ["text-align"]       = require("engine.libs.styles.handler-text-align"),     -- Text alignment (left, right, center)
    "text-decoration",-- Text decoration (underline, overline, none)
    "text-transform", -- Text transformation (uppercase, lowercase, capitalize)
    "letter-spacing", -- Space between letters
    "word-spacing",   -- Space between words
    "white-space",    -- White space handling (nowrap, normal, pre)
    
    -- Box Model
    "width",          -- Element width
    "height",         -- Element height
    "margin",         -- Margin space
    "padding",        -- Padding space
    "border",         -- Border style
    "border-width",   -- Border width
    "border-color",   -- Border color
    "border-radius",  -- Border radius (rounded corners)
    
    -- Background
    "background",     -- Background shorthand (color/image)
    "background-color", -- Background color
    "background-image", -- Background image URL
    "background-repeat", -- Repeat pattern (no-repeat, repeat-x, etc.)
    "background-size", -- Background size (cover, contain, etc.)
    
    -- Positioning and Layout
    "display",        -- Display type (block, inline, flex, etc.)
    "position",       -- Positioning method (static, relative, absolute, fixed)
    "top",            -- Position top offset
    "left",           -- Position left offset
    "right",          -- Position right offset
    "bottom",         -- Position bottom offset
    "z-index",        -- Stack order for elements
    "float",          -- Float (left, right)
    "clear",          -- Clear float (none, left, right)
    
    -- Flexbox (if using flexbox layout)
    "flex",           -- Flex properties (grow, shrink, basis)
    "justify-content",-- Justify content (start, center, space-between)
    "align-items",    -- Align items (flex-start, center, stretch)
    "align-self",     -- Align a single item (auto, flex-start, center)
    
    -- Visibility and Overflow
    "visibility",     -- Visibility of element (visible, hidden)
    "overflow",       -- Overflow (visible, hidden, scroll, auto)
    "overflow-x",     -- Overflow on X axis
    "overflow-y",     -- Overflow on Y axis
    
    -- Transitions and Animations
    "transition",     -- Shorthand for transition properties (duration, delay, etc.)
    "animation",      -- Animation shorthand (name, duration, timing-function, etc.)
    
    -- Miscellaneous
    "opacity",        -- Opacity (transparency)
    "cursor",         -- Cursor style (pointer, default, etc.)
    "box-shadow",     -- Box shadow (horizontal, vertical, blur, color)
    "text-shadow",    -- Text shadow (horizontal, vertical, blur, color)
    "transform",      -- CSS transformations (rotate, scale, translate)
    "filter",         -- CSS filters (blur, grayscale, etc.)
}


return css_properties