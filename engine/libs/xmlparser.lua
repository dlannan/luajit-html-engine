-- Derived from the XML parser here: http://lua-users.org/wiki/LuaXml

-- No close tags 
local no_close_tags = {
  ["br"]     = true,
  ["img"]    = true,
  ["input"]  = true,
  ["link"]   = true,
}

local function parseargs(s)
  local arg = {}
  string.gsub(s, "([%-%w:_]+)=([\"'])(.-)%2", function (w, _, a)
    arg[w] = a
  end)
  return arg
end
    
local function collect(s)
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:_-]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
    elseif c == "" then   -- start tag
      top = {label=label, xarg=parseargs(xarg)}
      table.insert(stack, top)   -- new level
      if(no_close_tags[label]) then 
        local toclose = table.remove(stack)  -- remove top
        top = stack[#stack]
        table.insert(top, toclose)
      end
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[#stack].label)
  end
  return stack[1]
end

local function dumpxml(tbl, indent)

  if(indent == nil) then indent = 0 end
  indent = indent + 4
  for k,v in pairs(tbl) do 
    print(string.rep(" ", indent)..k.."   "..tostring(v))
    if(type(v) == "table") then dumpxml(v, indent) end
  end 
end


return { parse = collect, dumpxml = dumpxml }