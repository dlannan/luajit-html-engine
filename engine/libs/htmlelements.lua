----------------------------------------------------------------------------------
-- Html element rendering. 
--
-- 		Each element has a style setup (element entry) and a style cleanup (element exit)

----------------------------------------------------------------------------------

local tinsert 	= table.insert
local tremove 	= table.remove

local tcolor = { r=0.0, b=1.0, g=0.0, a=1.0 }

----------------------------------------------------------------------------------

local htmlelements 		= {}
local dirty_elements 	= true

local common    		= require("engine.libs.elements-common")
local libstyle  		= require("engine.libs.elements-style")
local layout 			= require("engine.libs.htmllayout")

----------------------------------------------------------------------------------
-- Heading elements 
htmlelements["h1"]  		= require("engine.libs.elements.headings")
htmlelements["h2"]  		= require("engine.libs.elements.headings")
htmlelements["h3"]  		= require("engine.libs.elements.headings")
htmlelements["h4"]  		= require("engine.libs.elements.headings")
htmlelements["h5"]  		= require("engine.libs.elements.headings")
htmlelements["h6"]  		= require("engine.libs.elements.headings")

----------------------------------------------------------------------------------
-- Text elements 
htmlelements["p"]  			= require("engine.libs.elements.text_paragraph")
htmlelements["i"]  			= require("engine.libs.elements.text_italics")
htmlelements["b"]  			= require("engine.libs.elements.text_bold")
htmlelements["br"]  		= require("engine.libs.elements.br")
htmlelements["blockquote"] 	= require("engine.libs.elements.blockquote")

----------------------------------------------------------------------------------
-- Complexg elements 
htmlelements["img"]  		= require("engine.libs.elements.img")
htmlelements["button"]  	= require("engine.libs.elements.button")
htmlelements["form"] 		= require("engine.libs.elements.form")
htmlelements["label"] 		= require("engine.libs.elements.label")
htmlelements["input"] 		= require("engine.libs.elements.input")

----------------------------------------------------------------------------------
-- Base layout elements 
htmlelements["body"] 		= require("engine.libs.elements.body")
htmlelements["html"] 		= require("engine.libs.elements.html")
htmlelements["div"] 		= require("engine.libs.elements.div")

----------------------------------------------------------------------------------
-- Script elements 
htmlelements["script"] 		= require("engine.libs.elements.script")

----------------------------------------------------------------------------------
-- Head specific elements 
htmlelements["head"] 		= require("engine.libs.elements.head")
htmlelements["title"] 		= require("engine.libs.elements.head_title")

----------------------------------------------------------------------------------

return {
	FONT_SIZES 		= libstyle.FONT_SIZES,

	addtextobject 	= common.textdefault,

	defaultmargin	= libstyle.defaultmargin,
	defaultpadding	= libstyle.defaultpadding,
	defaultborder	= libstyle.defaultborder,
	
	elements 		= htmlelements, 
	init			= layout.init,
	finish			= layout.finish,

	-- Use this flag to update elements
	dirty 			= dirty_elements,
}

----------------------------------------------------------------------------------