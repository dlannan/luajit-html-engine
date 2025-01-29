-- AABB Tree implementation in Lua with depth handling
local AABBTree = {}
AABBTree.__index = AABBTree

-- Helper function: Create a new AABB
local function createAABB(minX, minY, maxX, maxY)
    return { minX = minX, minY = minY, maxX = maxX, maxY = maxY }
end

-- Helper function: Combine two AABBs
local function combineAABB(aabb1, aabb2)
    return createAABB(
        math.min(aabb1.minX, aabb2.minX),
        math.min(aabb1.minY, aabb2.minY),
        math.max(aabb1.maxX, aabb2.maxX),
        math.max(aabb1.maxY, aabb2.maxY)
    )
end

-- Create a new AABBTree
function AABBTree.new()
    return setmetatable({ root = nil }, AABBTree)
end

-- AABB Tree Node
local function createNode(aabb, object, depth)
    return {
        aabb = aabb,
        object = object, -- The object stored in the node (nil for internal nodes)
        depth = depth,   -- Depth for rendering order (lower is in front)
        left = nil,
        right = nil,
        parent = nil
    }
end

-- Recalculate the AABB for a node based on its children
local function recalculateAABB(node)
    if not node.left or not node.right then return end
    node.aabb = combineAABB(node.left.aabb, node.right.aabb)
end


-- Add an object to the AABBTree
function AABBTree:add(newAABB, object, depth)
    local function fitsWithin(aabb1, aabb2)
        return (aabb1.minX >= aabb2.minX and aabb1.maxX <= aabb2.maxX and
                aabb1.minY >= aabb2.minY and aabb1.maxY <= aabb2.maxY)
    end

    if not self.root then
        -- Create root node if tree is empty
        self.root = { aabb = newAABB, depth = depth, object = object, left = nil, right = nil }
        return
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

    local function insert(node)
        ensureAABB(node) -- Ensure node has a valid AABB before using it

        -- If node is a leaf (contains an object)
        if node.object then
            return {
                aabb = {
                    minX = math.min(node.aabb.minX, newAABB.minX),
                    minY = math.min(node.aabb.minY, newAABB.minY),
                    maxX = math.max(node.aabb.maxX, newAABB.maxX),
                    maxY = math.max(node.aabb.maxY, newAABB.maxY),
                },
                left = node,
                right = { aabb = newAABB, depth = depth, object = object, left = nil, right = nil }
            }
        end

        -- Find the best-fitting child to insert into
        if fitsWithin(newAABB, node.aabb) then
            if node.left and fitsWithin(newAABB, node.left.aabb) then
                node.left = insert(node.left)
            elseif node.right and fitsWithin(newAABB, node.right.aabb) then
                node.right = insert(node.right)
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
                    right = { aabb = newAABB, depth = depth, object = object, left = nil, right = nil }
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
            right = { aabb = newAABB, depth = depth, object = object, left = nil, right = nil }
        }
    end

    -- Insert into the tree
    self.root = insert(self.root)
end

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


AABBTree.createAABB         = createAABB
AABBTree.createNode         = createNode
AABBTree.combineAABB        = combineAABB
AABBTree.recalculateAABB    = recalculateAABB

return AABBTree


--[[ Test Example
    local AABBTree = require("AABBTree")

    local tree = AABBTree.new()
    
    tree:add(createAABB(0, 0, 2, 2), "Object1", 5) -- Depth 5
    tree:add(createAABB(3, 3, 5, 5), "Object2", 2) -- Depth 2 (in front of Object1)
    tree:add(createAABB(1, 1, 4, 4), "Object3", 8) -- Depth 8 (behind both)
    
    print("Tree after additions:")
    tree:print()
    
    tree:remove("Object2")
    print("\nTree after removing Object2:")
    tree:print()

    -- Depth traversal
    local nodes = tree:traverseDepthBased()
    for _, node in ipairs(nodes) do
        print(string.format("Object: %s, Depth: %d", tostring(node.object), node.depth))
    end

]]--    