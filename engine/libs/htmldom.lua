-- The html dom here does not currently follow much of the spec.
--  Why?: Its not a priority. I want to be able to render as a UI first. Then worry about compat later.
--        Additionally, there is _alot_ of parts to the dom that are just not that useful in the way
--        it is described in the WW3C doc. 
--        Also, I want to do a single pass renderer. I dont want to do multiple passes over the xml and dom.
--        Mainly because there are ways to get around the need to pass multiple times, while also reducing 
--        the complexity of parsing and rendering the page.
--
-- This dom will be simple.
--
-- The structure is just a tree of the element ids that are generated as the xml is parsed.
-- Elements are processed on thier close tags and the dom may be updated at anytime between tags.

local tinsert       = table.insert 
local tremove       = table.remove

local xmlp 		    = require("engine.libs.xmlparser") 
local htmle 		= require("engine.libs.htmlelements")
local layout        = require("engine.libs.htmllayout")
local rapi 		    = require("engine.libs.htmlrender-api")

local pcss          = require("lua.cssparse")
local utils         = require("lua.utils")

----------------------------------------------------------------------------------

local htmlelements 	= htmle.elements 
local FONT_SIZES 	= htmle.FONT_SIZES

----------------------------------------------------------------------------------

local styleempty = { 
	textsize    = FONT_SIZES.p, 
	linesize    = FONT_SIZES.p * 1.5, 
	maxlinesize = 0, 
	width       = 0, 
	height      = 0,
}

styleempty.margin      = htmle.defaultmargin(styleempty)
styleempty.padding     = htmle.defaultpadding(styleempty)
styleempty.border      = htmle.defaultborder(styleempty)

local stylestack    = {}
stylestack[1] = deepcopy(styleempty)

----------------------------------------------------------------------------------
-- Root node always has nil parent.
local dom_node = {
    parent      = nil,   -- parent node, used mainly in traversal
    children    = {},    -- list of child nodes which can contain mode child nodes.
    eid         = nil,
}

----------------------------------------------------------------------------------

local dom = {
    root        = dom_node,
    elookup     = {},    -- As elements are added, they are mapped here for fast eid->node fetch
    styles      = {},    -- A collection of styles loaded in from css and style tags
    selectors   = {},    -- From the styles a selectors table is build. To be used in xml parsing
}

local dom_root 		= dom.root
local curr_node 	= dom_root

----------------------------------------------------------------------------------

dom.stylenone  = function(  )
	return deepcopy(styleempty)
end 

----------------------------------------------------------------------------------

dom.reset = function()
    dom.root = nil
    dom.elookup = {}
    return dom.root
end 

----------------------------------------------------------------------------------
-- Get the xml node and remove it.
dom.delnode = function( node )
    if(node == nil) then return nil end 
    -- This isnt overly intuitive, but we want to remove from the parent child list.
    local oldnode = nil
    if(node.parent) then 
        local remove = nil
        for i,v in ipairs(node.parent.children) do 
            if(v.eid == eid) then
                remove = i 
                oldnode = v
                break 
            end 
        end 
        if(remove) then tremove(node.parent.children, remove) end 
    end
    return oldnode
end

----------------------------------------------------------------------------------

dom.delelement = function( eid )
    local node = elookup[eid]
    return dom.delnode( node )
end

----------------------------------------------------------------------------------

dom.getelement = function( eid )
    return dom.elookup[eid]
end

----------------------------------------------------------------------------------

dom.getparent = function( node )
    return node.parent
end

----------------------------------------------------------------------------------

dom.addstylesource = function( styledata )
    
    tinsert(dom.styles, styledata)
    return #dom.styles
end

----------------------------------------------------------------------------------
-- Simple node traversal
---   funcs is a set of functions that are called at different stages 
---   - funcs.pre  - execute before an element 
---   - funcs.post - execute after the exit of an element (like a close tag)
dom.traversenodes = function( ctx, node, funcs )

    if(node) then 
        funcs.pre(ctx, node)
        for k,v in pairs(node) do 
            -- Might be a string index
            if(type(k) == "number") then
                if(type(v) == "table") then
                    dom.traversenodes( ctx, v, funcs ) 
                end
            end
        end
        funcs.post(ctx, node)
    end
end

----------------------------------------------------------------------------------
-- Decode css and build lookups and selects for the html
dom.processstyles = function()

    -- Preprocess fonts first, and pass to rapi 
    -- Process style css format 1 line at a time. No tokenisation - I dont believe its needed?
    for i,v in ipairs(dom.styles) do 
        local csstbl = pcss.parse_css(v.data)
        local fonts = pcss.preprocess_fonts(v.data)
        for fi, fv in ipairs(fonts) do 
            dom.renderCtx.add_font(fv.family, fv.src )
        end
    end

    for i,v in ipairs(dom.styles) do 
        local csstbl = pcss.parse_css(v.data)
        -- pcss.print_table(csstbl)
        utils.tmerge( dom.selectors, csstbl )
    end
end

----------------------------------------------------------------------------------
-- Pass js to duktape so it can be readied to be run. 
--  NOTE: many core doms will need to be registered in duktape for this to work - TBD
dom.processscripts = function()
end

----------------------------------------------------------------------------------
-- The style functions for preprocessing style data
local stylefuncs = {}
stylefuncs.pre = function(ctx, xml)

    if(xml.label) then 
        -- For initial processing, we store style text and css files into a lib. 
        -- Layout pass handles the application of the styling.
        if(xml.label == "style" ) then 
            for k,v in pairs(xml) do 
                if(type(k) == "number" and type(v) == "string") then
                    local styledata = {
                        data    = tostring(v),  -- force string 
                        srctype = xml.label,    -- changes if using link or css files
                        node    = xml.parent,   -- which node owns this
                    }
                    dom.addstylesource( styledata )
                end 
            end
        elseif(xml.label == "link") then 
            if(xml.xarg["href"]) then 
                local styledata = {
                    data    = utils.loaddata(xml.xarg["href"]),  
                    srctype = xml.label,    -- changes if using link or css files
                    node    = xml.parent,   -- which node owns this
                } 
                if(xml.xarg["ref"]) then styledata.ref = xml.xarg["ref"] end
                if(xml.xarg["type"]) then styledata.stype = xml.xarg["type"] end
                dom.addstylesource( styledata )
            end
        end 

        if(xml.label == "script") then 
        end
    end
end

----------------------------------------------------------------------------------

stylefuncs.post = function(ctx, xml)
end

----------------------------------------------------------------------------------
-- The xmlhandler is intended for creating a base dom. With all the info needed
--   to be able to "rerun" the dom tree as needed.
local nodefuncs = {}
nodefuncs.pre = function( ctx, xml )

	local currstyle = stylestack[#stylestack]
	local style = deepcopy(currstyle)
	local this_node = nil

	local g = { ctx=ctx, cursor = dom.ctx.cursor, frame = dom.ctx.frame }
	-- Check element names 
	local label = nil
	if( xml.label ) then label = string.lower(xml.label) end
	if(label) then 

        style.etype = label
		local iselement = htmlelements[label]	
		if(iselement and iselement.opened) then 
			-- Assign parent
			style.pstyle = currstyle

            -- Fetch any selectors on this tag type 
            if(style and dom.selectors[label]) then 
                style = utils.tmerge(style, dom.selectors[label]) 
            end
            local class = xml.xarg["class"]
            if(style and class and dom.selectors["."..class]) then 
                style = utils.tmerge(style, dom.selectors["."..class]) 
            end
            local id = xml.xarg["id"]
            if(style and id and dom.selectors["#"..id]) then 
                style = utils.tmerge(style, dom.selectors["#"..id]) 
            end

			iselement.opened( g, style, xml ) 
		end    
		tinsert(stylestack, style)
	end 

	if(style.notextprocess == nil) then 
		for k,v in pairs(xml) do 

			if(type(k) == "number") then

                if(v and type(v) == "string") then
                    if(string.find(v, "DOCTYPE") == nil) then
                        local txt = v
                        xml[k] = {}
                        xml[k]["label"] = "text"
                        xml[k]["xarg"] = { text = txt }
                    end 
                end
			end
		end
	end 

    xml.g         = g
    xml.style     = style
end

----------------------------------------------------------------------------------

nodefuncs.post = function(ctx, xml)

    local style     = stylestack[#stylestack]
    local g         = xml.g
    local label     = xml.label
    
	-- Check label to close the element
	if(label) then 
		local iselement = htmlelements[label]
		if(iselement and iselement.closed) then 

            iselement.closed( g, style, xml ) 
            local element 		= layout.getelement(style.elementid)
            local geom 			= layout.getgeom()
            xml.geom = geom.get(element.gid)
        end 
		tremove( stylestack ) 
	end
end 

----------------------------------------------------------------------------------

dom.loadxmlfile = function( self, filename, frame, cursor )

    dom.ctx = {
        frame       = frame,
        cursor      = cursor,
    }

    dom.renderCtx = self.renderCtx 
    curr_node = dom.reset(htmlelements)

	--local filename = "/data/html/sample02-forms.html"
	local xml = utils.loaddata(filename)
	local xmldata = xmlp.parse(xml)
    dom.loadxml(xmldata)
end

----------------------------------------------------------------------------------

dom.loadxml = function( xmldata )

    -- TODO: Put validation here later
    dom.xmldoc = xmldata

    -- Pre process all style and css - this allows lookups when xml is processed and layout
    dom.traversenodes( dom.renderCtx, dom.xmldoc, stylefuncs) 

    dom.processstyles() 
    dom.processscripts()

    -- Process the xml into our elements and dom tree items
    dom.traversenodes( dom.renderCtx, dom.xmldoc, nodefuncs ) 
    -- xmlp.dumpxml(dom.xmldoc)

    -- remove parent style hierarchies from nodes
    dom.traversenodes( dom.renderCtx, dom.xmldoc, {
        pre = function(ctx, xml)
            if(xml.style and xml.style.pstyle) then xml.style.pstyle = nil end
        end,
        post = function(ctx, xml)
        end,
    })

    -- print("----> ", utils.tdump(dom.xmldoc))
end

----------------------------------------------------------------------------------

dom.layout = function(frame, cursor)

    dom.traversenodes( dom.renderCtx, dom.xmldoc, {
        pre = function(ctx, xml)
        end,
        post = function(ctx, xml)
            if(xml.label) then 
                local iselement = htmlelements[xml.label]
                if(iselement and iselement.layout) then 
                    iselement.layout( ctx, xml ) 
                end
            end
        end,
    }) 
end

----------------------------------------------------------------------------------

dom.render = function(frame, cursor)
    
    --xmlhandler( dom.renderCtx, dom.xmldoc )
    -- Do a normal traverse of the dom tree - not xml tree
    local geom = layout.getgeom()

    -- visit each node like layout does and call layout methods
    -- dom.traversenodes( dom.root, function(node) 
    --     local e = layout.getelement(node.eid)
    --     if(e) then 
    --         local iselement = htmlelements[e.etype]
    --         if(iselement) then 
    --             local obj 			= geom.get( e.gid )
    --             e.width 		= obj.width
    --             e.height 		= obj.height
    --             geom.renew( e.gid, e.pos.left, e.pos.top, e.width, e.height )
    --         end
    --     end
    -- end)    
end

----------------------------------------------------------------------------------

return dom 

----------------------------------------------------------------------------------