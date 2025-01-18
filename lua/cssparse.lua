-- Function to parse the CSS string
local function parse_css(css_string)
    local css_table = {}

    -- Function to get or create a nested table for a selector
    local function get_or_create_table(path, root)
        local current = root
        for part in path:gmatch("[^%s>]+") do
            current[part] = current[part] or {}
            current = current[part]
        end
        return current
    end

    -- Split by blocks: "selector { properties }"
    for selector_block, properties_block in css_string:gmatch("([^{}]+)%s*{%s*([^}]*)%s*}") do
        -- Process selectors
        local current_selectors = {}
        for selector in selector_block:gmatch("[^,]+") do
            selector = selector:match("^%s*(.-)%s*$") -- Trim whitespace
            table.insert(current_selectors, selector)
            get_or_create_table(selector, css_table) -- Ensure selector table exists
        end

        -- Process properties
        for property_line in properties_block:gmatch("[^;]+") do
            local key, value = property_line:match("^(.-):%s*(.-)%s*$")
            if key and value then
                for _, selector in ipairs(current_selectors) do
                    local selector_table = get_or_create_table(selector, css_table)
                    if(type(key) == "string") then key = string.gsub(key, "[\r\n ]", "") end
                    selector_table[key] = value
                end
            end
        end
    end

    return css_table
end

-- Print the resulting table
local function print_table(tbl, indent)
    indent = indent or 0
    local padding = string.rep("  ", indent)
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print(padding .. key .. " {")
            print_table(value, indent + 1)
            print(padding .. "}")
        else
            print(padding .. key .. ": " .. value)
        end
    end
end

local function test()

    local css_data = [[
        body, html { margin: 0; padding: 0; }
        h1, .title, #main-title { font-size: 24px; font-weight: bold; }
        .title > p, .subtitle span { color: blue; font-style: italic; }
    ]]      

    -- Parse the CSS dataset
    local parsed_css = parse_css(css_data)
    print_table(parsed_css)
end 

return {
    parse_css       = parse_css,
    print_table     = print_table,

    test            = test,
}