
local utils     = require("lua.utils")

local tinsert   = table.insert
local trmeove   = table.remove

----------------------------------------------------------------------------------
-- AABB Tree implementation in Lua with depth handling
local LayoutTree    = {}
local nodeid        = 0
local object_lookup = {}

LayoutTree.__index = LayoutTree

----------------------------------------------------------------------------------
-- Helper function: Create a new AABB
local function createAABB(minX, minY, maxX, maxY)
    return { minX = minX, minY = minY, maxX = maxX, maxY = maxY }
end

----------------------------------------------------------------------------------
-- Helper function: Combine two AABBs
local function combineAABB(aabb1, aabb2)
    return createAABB(
        math.min(aabb1.minX, aabb2.minX),
        math.min(aabb1.minY, aabb2.minY),
        math.max(aabb1.maxX, aabb2.maxX),
        math.max(aabb1.maxY, aabb2.maxY)
    )
end

----------------------------------------------------------------------------------
-- Create a new LayoutTree
function LayoutTree.new()
    return setmetatable({ root = nil }, LayoutTree)
end

----------------------------------------------------------------------------------
-- AABB Tree Node
local function createNode(aabb, object, depth)
    nodeid = nodeid + 1
    local newnode = {
        id      = nodeid,
        aabb    = aabb,
        object  = object,   -- The object stored in the node (nil for internal nodes)
        depth   = depth,    -- Depth for rendering order (lower is in front)
        parent  = nil,      -- root node parent is nil.
        children    = {},
    }

    if(object) then object_lookup[object] = newnode end
    return newnode
end

----------------------------------------------------------------------------------
-- Recalculate the AABB for a node based on its children
local function recalculateAABB(node)
    
    if(node.children) then 
        for i, v in ipairs(node.children) do
            if(v.aabb) then 
                node.aabb = combineAABB(node.aabb, v.aabb)
            end 
        end 
    end
    return node.aabb
end

----------------------------------------------------------------------------------
-- Add an object to the LayoutTree
function LayoutTree:add(child, parent)
    
    if not self.root then
        -- Create root node if tree is empty
        self.root = child
        return
    end

    -- If we have a valid root, and an nil parent, then the child is a root child.
    if(parent == nil) then parent = self.root end 
    parent.aabb = combineAABB( child.aabb, parent.aabb )
    child.parent = parent 
    tinsert(parent.children, child)
end

----------------------------------------------------------------------------------
-- Remove an object from the LayoutTree
function LayoutTree:removeNode(node)

    if(node.parent) then 
        local removal_idx = nil
        for i,v in ipairs(node.parent.children) do
            if(v == node) then 
                removal_idx = i 
                break 
            end 
        end 
        tremove(node.parent.children, removal_idx)
    end
    return node
end

----------------------------------------------------------------------------------
-- Remove an object from the LayoutTree 
--   But dont necessarily delete the children of th node!
function LayoutTree:remove(object)
    local node = object_lookup[object]
    return self:removeNode(node)
end

----------------------------------------------------------------------------------
function LayoutTree:update(node, newAABB)

    node.aabb.minX = newAABB.minX
    node.aabb.minY = newAABB.minY
    node.aabb.maxX = newAABB.maxX
    node.aabb.maxY = newAABB.maxY

    local function traverseup( pnode )
        if(pnode == nil) then return end
        pnode.aabb = combineAABB( pnode.aabb, newAABB )
        traverseup(pnode.parent) 
    end
    traverseup(node.parent)
end

----------------------------------------------------------------------------------
function LayoutTree:print(node, depth)
    depth = depth or 0
    node = node or self.root  -- Start from root if not provided

    if not node then return end  -- Prevent recursion on nil nodes

    -- Print indentation based on depth
    local indent = string.rep("-", depth)
    if node.object then
        print(string.format("%s[Leaf] Object: %d | AABB: (%.2f, %.2f) -> (%.2f, %.2f) | Depth: %d",
            indent, tostring(node.object.id), node.aabb.minX, node.aabb.minY, node.aabb.maxX, node.aabb.maxY, node.depth or -1))
    else
        print(string.format("%s[Node] AABB: (%.2f, %.2f) -> (%.2f, %.2f)", 
            indent, node.aabb.minX, node.aabb.minY, node.aabb.maxX, node.aabb.maxY))
    end

    -- Recursively print children (only if they exist)
    if node.children then 
        for i,v in ipairs(node.children) do
            self:print(v, depth + 1) 
        end
    end
end

----------------------------------------------------------------------------------

local function traverse( node, prefunc, postfunc, nodedata )

    if not node then return end
    if(prefunc) then prefunc( node, nodedata ) end
    for i,v in ipairs(node.children) do 
        traverse(v, prefunc, postfunc, nodedata)
    end
    if(postfunc) then postfunc( node, nodedata ) end
end    

----------------------------------------------------------------------------------
-- Depth-based traversal for painter's algorithm
function LayoutTree:traverseDepthBased()
    local result = {}

    local function collectNodes(node, res)
        if node.object then
            -- Leaf node with an object
            table.insert(res, node)
        end
    end

    traverse(self.root, collectNodes, nil, result)

    -- Sort by depth (descending, farthest first)
    table.sort(result, function(a, b)
        return a.depth > b.depth
    end)

    -- Return the sorted nodes
    return result
end

----------------------------------------------------------------------------------
function LayoutTree:queryObjectId(oid)
    local result = nil

    local function oidtest(node, res)

        -- Check if the point is within this node's AABB
        local aabb = node.aabb
        if node.object and res == nil then
            if node.object.id == oid then
                res = node.object
                return
            end
        end
    end

    traverse(self.root, oidtest, nil, result)
    return result
end

----------------------------------------------------------------------------------
function LayoutTree:queryPoint(x, y)
    local result = {}

    local function testaabb(node, res)

        -- Check if the point is within this node's AABB
        local aabb = node.aabb
        if x >= aabb.minX and x <= aabb.maxX and y >= aabb.minY and y <= aabb.maxY then
            if node.object then
                -- Leaf node with an object, add to result
                tinsert(res, node)
            end
        end
    end

    traverse(self.root, testaabb, nil, result)
    return result
end

----------------------------------------------------------------------------------

LayoutTree.createAABB         = createAABB
LayoutTree.createNode         = createNode
LayoutTree.combineAABB        = combineAABB
LayoutTree.recalculateAABB    = recalculateAABB

return LayoutTree

----------------------------------------------------------------------------------
