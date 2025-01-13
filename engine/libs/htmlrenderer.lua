----------------------------------------------------------------------------------
-- Fix colors later (with css etc)

require("engine.utils.copy")

local tinsert 		= table.insert
local tremove 		= table.remove

local tcolor 		= { r=0.0, b=1.0, g=0.0, a=1.0 }

local htmle 		= require("engine.libs.htmlelements")
local htmldom 		= require("engine.libs.htmldom")
local utils 		= require("lua.utils")

----------------------------------------------------------------------------------

local cursor 		= { top = 0.0, left = 0.0 }
local frame 		= { focussed = nil, top = 0.0, left = 0.0, width = 0.0, height = 0.0 }

----------------------------------------------------------------------------------
-- Render should render the dom. 
--     Xml render should only occur once on load of xml objects.

local function render( position )

	frame.top 		= position.top or 0.0
	frame.left 		= position.left or 0.0
	cursor.top 		= frame.top
	cursor.left 	= frame.left
	cursor.element_top = nil

	if(htmle.dirty) then
		htmle.init(frame, cursor)
		htmldom.render(frame, cursor)
		htmle.dirty = nil
	end 
	htmle.finish()
end

----------------------------------------------------------------------------------
-- Load the xml file and process it

local function load( ctx, filename )
	htmldom.loadxmlfile( ctx, filename, frame, cursor)
end

----------------------------------------------------------------------------------
local function rendersize( x, y )

	frame.width, frame.height 		= x, y
end

----------------------------------------------------------------------------------

return { 
	load 		= load,
	render 		= render,
	rendersize 	= rendersize,
}

----------------------------------------------------------------------------------
