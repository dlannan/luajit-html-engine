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

local utils         = require("lua.utils")

----------------------------------------------------------------------------------

local htmlelements 	= htmle.elements 
local FONT_SIZES 	= htmle.FONT_SIZES

----------------------------------------------------------------------------------

local styleempty = { 
	textsize = FONT_SIZES.p, 
	linesize = FONT_SIZES.p * 1.5, 
	maxlinesize = 0, 
	width = 0, 
	height = 0 
}
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
}

local dom_root 		= dom.root
local curr_node 	= dom_root

----------------------------------------------------------------------------------

dom.stylenone  = function(  )
	return deepcopy(styleempty)
end 

----------------------------------------------------------------------------------

dom.reset = function()
    dom.root = {
        parent = nil, 
        children = {},
        eid = nil,
    }
    dom.elookup = {}
    return dom.root
end 

----------------------------------------------------------------------------------

dom.newnode = function( eid )
    local node = { parent = node, children = {}, eid = eid }
    return node 
end

----------------------------------------------------------------------------------

dom.addnode = function( node, newnode )
    tinsert(node.children, newnode )
    dom.elookup[newnode.eid] = newnode
    return newnode
end

----------------------------------------------------------------------------------

dom.addelement = function( node, eid )
    local newnode = dom.newnode(eid)
    return dom.addnode(node, newnode)
end

----------------------------------------------------------------------------------

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
-- Simple node traversal
dom.traversenodes = function( node, func )

    if(node) then 
        if(node.children) then 
            for k,v in ipairs( node.children ) do 
                if(v.children) then 
                    dom.traversenodes( v, func ) 
                end 
            end
        end
        func(node)
    end
end

----------------------------------------------------------------------------------
-- Refreshes the layout data and geom for parent and children nodes
dom.refreshnodes = function( topnode )

    local geom = layout.getgeom()

    -- visit each node like layout does and call layout methods
    dom.traversenodes( topnode, function(node) 
        local e = layout.getelement(node.eid)
        if(e) then 
            local iselement = htmlelements[e.etype]
            if(iselement) then 
                local obj 			= geom.get( e.gid )
                e.width 		= obj.width
                e.height 		= obj.height
                geom.renew( e.gid, e.pos.left, e.pos.top, e.width, e.height )
            end
        end
    end)
end

----------------------------------------------------------------------------------

local function xmlhandler( ctx, xml )

	local currstyle = stylestack[#stylestack]
	local style = deepcopy(currstyle)
	local this_node = nil

	if(style.margin == nil) then style.margin = htmle.defaultmargin(style) end
	if(style.padding == nil) then style.padding = htmle.defaultpadding(style) end
	if(style.border == nil) then style.border = htmle.defaultborder(style) end
	local g = { ctx=ctx, cursor = dom.ctx.cursor, frame = dom.ctx.frame }

	-- Check element names 
	local label = nil
	if( xml.label ) then label = string.lower(xml.label) end
	if(label) then 
		style.etype = label
		local iselement = htmlelements[label]	
		if(iselement) then 
			-- Assign parent
			style.pstyle = currstyle

			iselement.opened( g, style, xml.xarg ) 
			this_node = dom.addelement( curr_node, style.elementid )
		end
		tinsert(stylestack, style)
	end 

	if(style.dontprocess == nil) then 
		for k,v in pairs(xml) do 

			-- Might be a string index
			if(type(k) == "number") then
				if( type(v) == "string") then
					if(string.find(v, "DOCTYPE") == nil) then
						local tstyle = deepcopy(style)
						tstyle.pstyle = style
						tinsert(stylestack, tstyle)
						htmle.addtextobject( g, tstyle, xml.arg, v )
						tremove( stylestack ) 
					end
				end

				if(type(v) == "table") then
					if(this_node) then curr_node = this_node end
					xmlhandler( ctx, v ) 
				end
			end
		end
	end 

	-- Check label to close the element
	if(label) then 
		local iselement = htmlelements[xml.label]
		if(iselement and iselement.closed) then iselement.closed( g, style ) end 
		tremove( stylestack ) 
		if(this_node) then curr_node = dom.getparent(this_node) end
	end
end 

----------------------------------------------------------------------------------

dom.loadxmlfile = function( self, filename, frame, cursor )

    dom.ctx = {
        frame       = frame,
        cursor      = cursor,
    }

    dom.renderCtx = self.renderCtx 

	--local filename = "/data/html/sample02-forms.html"
	local xml = utils.loaddata(filename)
	local xmldata = xmlp.parse(xml)
    dom.loadxml(xmldata)
end

----------------------------------------------------------------------------------

dom.loadxml = function( xmldata )

    curr_node = dom.reset(htmlelements)
    -- TODO: Put validation here later
    dom.xmldoc = xmldata
    -- Process the xml into our elements and dom tree items
    xmlhandler( dom.renderCtx, dom.xmldoc )
    -- xmlp.dumpxml(dom.xmldoc)
end

----------------------------------------------------------------------------------

dom.render = function(frame, cursor)
    curr_node = dom.reset()
    xmlhandler( dom.renderCtx, dom.xmldoc )
    -- Do a normal traverse of the dom tree - not xml tree
end

----------------------------------------------------------------------------------

return dom 

----------------------------------------------------------------------------------