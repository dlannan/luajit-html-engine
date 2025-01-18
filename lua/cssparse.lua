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

local function preprocess_fonts(css)
    -- Pattern to extract @font-face blocks from the CSS
    local font_face_pattern = "@font%-face%s*{(.-)}"
    local fonts = {}

    -- Extract all @font-face rules
    for font_block in css:gmatch(font_face_pattern) do
        local font = {}
        
        -- Find the font-family and font-source (src) in the block
        font.family = font_block:match("font%-family%s*:%s*([^;]+);")
        font.src = font_block:match("src%s*:%s*([^;]+);")
        
        if font.family and font.src then
            font.family = font.family:gsub("[\"']", "")
            -- cleanup font.src to remove url(...) and only use the string
            font.src = font.src:match("url%((.+)%)") or font.src
            font.src = font.src:gsub("[\"']", "")
            -- Store the fonts and the font source (you can use the font source URL here)
            table.insert(fonts, font)
        end
    end

    -- Print out the fonts for debugging
    for _, font in ipairs(fonts) do
        print("Font Family: " .. font.family)
        print("Font Source: " .. font.src)
        
        -- Example: Simulate loading the font here (this is a placeholder)
        -- In a real scenario, you would either download the font file or link it in the HTML.
        -- For now, we'll just print that the font is "loaded".
        print("Loading font " .. font.family .. " from source: " .. font.src)
    end

    -- Once fonts are processed, you can continue with the rest of the CSS parsing.
    return fonts
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
    parse_css           = parse_css,
    print_table         = print_table,
    preprocess_fonts    = preprocess_fonts,

    test                = test,
}