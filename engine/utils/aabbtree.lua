
local utils     = require("lua.utils")

----------------------------------------------------------------------------------
-- AABB Tree implementation in Lua with depth handling
local AABBTree  = {}
local nodeid    = 0
AABBTree.__index = AABBTree

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
-- Create a new AABBTree
function AABBTree.new()
    return setmetatable({ root = nil }, AABBTree)
end

----------------------------------------------------------------------------------
-- AABB Tree Node
local function createNode(aabb, object, depth, parent)
    nodeid = nodeid + 1
    return {
        id      = nodeid,
        aabb    = aabb,
        object  = object,   -- The object stored in the node (nil for internal nodes)
        depth   = depth,    -- Depth for rendering order (lower is in front)
        left    = nil,
        right   = nil,
        parent  = parent,   -- root node parent is nil.
    }
end

----------------------------------------------------------------------------------
-- Recalculate the AABB for a node based on its children
local function recalculateAABB(node)
    if not node.left or not node.right then return node.aabb end   
    node.aabb = combineAABB(node.left.aabb, node.right.aabb)
    return node.aabb
end

----------------------------------------------------------------------------------
-- Add an object to the AABBTree
function AABBTree:add(newAABB, object, depth)
    local function fitsWithin(aabb1, aabb2)
        return (aabb1.minX >= aabb2.minX and aabb1.maxX <= aabb2.maxX and
                aabb1.minY >= aabb2.minY and aabb1.maxY <= aabb2.maxY)
    end

    if not self.root then
        -- Create root node if tree is empty
        self.root = createNode(newAABB, object, depth, nil)
        return self.root
    end

    local function ensureAABB(node)
        if not node.aabb then
            node.aabb = {
                minX = newAABB.minX,
                minY = newAABB.minY,
                maxX = newAABB.maxX,
                maxY = newAABB.maxY
            }
        end
    end

    self.inserted_node = nil

    local function insert(node, pnode)
        ensureAABB(node) -- Ensure node has a valid AABB before using it

        -- If node is a leaf (contains an object)
        if node.object then
            self.inserted_node = {
                aabb = {
                    minX = math.min(node.aabb.minX, newAABB.minX),
                    minY = math.min(node.aabb.minY, newAABB.minY),
                    maxX = math.max(node.aabb.maxX, newAABB.maxX),
                    maxY = math.max(node.aabb.maxY, newAABB.maxY),
                },
                left = node,
                right = createNode(newAABB, object, depth, pnode)
            }
            return inserted_node
        end

        -- Find the best-fitting child to insert into
        if fitsWithin(newAABB, node.aabb) then
            if node.left and fitsWithin(newAABB, node.left.aabb) then
                node.left = insert(node.left, node)
            elseif node.right and fitsWithin(newAABB, node.right.aabb) then
                node.right = insert(node.right, node)
            else
                -- Create new parent node
                return {
                    aabb = {
                        minX = math.min(node.aabb.minX, newAABB.minX),
                        minY = math.min(node.aabb.minY, newAABB.minY),
                        maxX = math.max(node.aabb.maxX, newAABB.maxX),
                        maxY = math.max(node.aabb.maxY, newAABB.maxY),
                    },
                    left = node,
                    right = createNode(newAABB, object, depth, pnode)
                }
            end
            return node
        end

        -- Otherwise, create a new parent node encompassing both
        return {
            aabb = {
                minX = math.min(node.aabb.minX, newAABB.minX),
                minY = math.min(node.aabb.minY, newAABB.minY),
                maxX = math.max(node.aabb.maxX, newAABB.maxX),
                maxY = math.max(node.aabb.maxY, newAABB.maxY),
            },
            left = node,
            right = createNode(newAABB, object, depth, pnode)
        }
    end

    -- Insert into the tree
    self.root = insert(self.root, nil)
    return self.inserted_node
end

----------------------------------------------------------------------------------
-- Remove an object from the AABBTree
function AABBTree:remove(object)
    local function findNode(node, object)
        if not node then return nil end
        if node.object == object then
            return node
        end
        return findNode(node.left, object) or findNode(node.right, object)
    end

    local node = findNode(self.root, object)
    if not node then return end

    if node == self.root then
        self.root = nil
        return
    end

    local parent = node.parent
    local sibling = (parent.left == node) and parent.right or parent.left

    -- Replace the parent with the sibling
    if parent.parent then
        if parent.parent.left == parent then
            parent.parent.left = sibling
        else
            parent.parent.right = sibling
        end
        sibling.parent = parent.parent
    else
        self.root = sibling
        sibling.parent = nil
    end

    -- Update the tree upwards
    local current = sibling.parent
    while current do
        recalculateAABB(current)
        if current.left and current.right then
            current.depth = math.min(current.left.depth, current.right.depth)
        end
        current = current.parent
    end
end

----------------------------------------------------------------------------------
-- Remove an object from the AABBTree
function AABBTree:removeNode(node)

    if not node then return end

    if node == self.root then
        self.root = nil
        return
    end

    if node.parent then
        local parent = node.parent
        local sibling = (parent.left == node) and parent.right or parent.left
        if parent.parent then
            if parent.parent.left == parent then
                parent.parent.left = sibling
            else
                parent.parent.right = sibling
            end
            sibling.parent = parent.parent
        else
            self.aabb = sibling.aabb
            self.value = sibling.value
            self.left = sibling.left
            self.right = sibling.right
            self.object = sibling.object 
            self.parent = sibling.parent
            if self.left then self.left.parent = self end
            if self.right then self.right.parent = self end
        end
    end
end

----------------------------------------------------------------------------------
function AABBTree:update(node, newAABB)
    -- Step 1: Remove node (and recursively its children)
    self:removeNode(node)

    -- Step 2: Update AABB bounds
    node.minX = newAABB.minX
    node.minY = newAABB.minY
    node.maxX = newAABB.maxX
    node.maxY = newAABB.maxY

    -- Step 3: If it's a parent, update children recursively
    local newnode = nil
    if node.left or node.right then
        newnode = self:rebuildSubtree(node)
    else
        -- Step 4: Reinsert the updated node
        newnode = self:add(newAABB, node.object, node.depth)
    end
    return newnode
end

----------------------------------------------------------------------------------
-- Helper function to rebuild a subtree
function AABBTree:rebuildSubtree(parentNode)
    if parentNode.left then
        return self:update(parentNode.left, recalculateAABB(parentNode.left))
    end
    if parentNode.right then
        return self:update(parentNode.right, recalculateAABB(parentNode.right))
    end

    -- Reinsert the parent with its updated bounds
    return self:add(parentNode, recalculateAABB(parentNode))
end

----------------------------------------------------------------------------------
function AABBTree:print(node, depth)
    depth = depth or 0
    node = node or self.root  -- Start from root if not provided

    if not node then return end  -- Prevent recursion on nil nodes

    -- Print indentation based on depth
    local indent = string.rep("-", depth)
    if node.object then
        print(string.format("%s[Leaf] Object: %d | AABB: (%.2f, %.2f) -> (%.2f, %.2f) | Depth: %d",
            indent, tostring(node.object.gid), node.aabb.minX, node.aabb.minY, node.aabb.maxX, node.aabb.maxY, node.depth or -1))
    else
        print(string.format("%s[Node] AABB: (%.2f, %.2f) -> (%.2f, %.2f)", 
            indent, node.aabb.minX, node.aabb.minY, node.aabb.maxX, node.aabb.maxY))
    end

    -- Recursively print children (only if they exist)
    if node.left then self:print(node.left, depth + 1) end
    if node.right then self:print(node.right, depth + 1) end
end

----------------------------------------------------------------------------------
-- Depth-based traversal for painter's algorithm
function AABBTree:traverseDepthBased()
    local result = {}

    local function collectNodes(node)
        if not node then return end
        if node.object then
            -- Leaf node with an object
            table.insert(result, node)
        else
            -- Internal node: Traverse both children
            collectNodes(node.left)
            collectNodes(node.right)
        end
    end

    collectNodes(self.root)

    -- Sort by depth (descending, farthest first)
    table.sort(result, function(a, b)
        return a.depth > b.depth
    end)

    -- Return the sorted nodes
    return result
end

----------------------------------------------------------------------------------
function AABBTree:queryOebjctId(oid)
    local result = nil

    local function traverse(node)
        if not node then return end

        -- Check if the point is within this node's AABB
        local aabb = node.aabb
        if node.object then
            if node.object.id == oid then
                result = node.object
                return
            end
            
            -- Continue searching child nodes only if they exist
            if node.left then traverse(node.left) end
            if node.right then traverse(node.right) end
        end
    end

    traverse(self.root)
    return result
end

----------------------------------------------------------------------------------
function AABBTree:queryPoint(x, y)
    local result = {}

    local function traverse(node)
        if not node then return end

        -- Check if the point is within this node's AABB
        local aabb = node.aabb
        if x >= aabb.minX and x <= aabb.maxX and y >= aabb.minY and y <= aabb.maxY then
            if node.object then
                -- Leaf node with an object, add to result
                table.insert(result, node)
            end
            
            -- Continue searching child nodes only if they exist
            if node.left then traverse(node.left) end
            if node.right then traverse(node.right) end
        end
    end

    traverse(self.root)
    return result
end

----------------------------------------------------------------------------------

AABBTree.createAABB         = createAABB
AABBTree.createNode         = createNode
AABBTree.combineAABB        = combineAABB
AABBTree.recalculateAABB    = recalculateAABB

return AABBTree

----------------------------------------------------------------------------------
