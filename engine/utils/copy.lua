-- Useful copy functions

-- Deep Copy
-- This is good for instantiating tables/objects without too much effort :)

function deepcopy(t)
	if type(t) ~= 'table' then return t end
	local mt = getmetatable(t)
	local res = {}
	for k,v in pairs(t) do
		if type(v) == 'table' then
		v = deepcopy(v)
		end
		res[k] = v
	end
	setmetatable(res,mt)
	return res
end


-- Data Copy
-- This only copues the first level objects. Any child tables are ignored

function datacopy(t)
	local res = {}
	for k,v in pairs(t) do 
		if(type(v) ~= "table") then 
			res[k] = v
		end
	end
	return res
end