local NULL = {}

NULL.ClassName = "NULL"
NULL.IsNull = true

local function FALSE()
	return false
end

function NULL:__tostring()
	return "NULL"
end
	
function NULL:__index(key)
	if key == "ClassName" then
		return "NULL"
	end
	
	if key == "IsValid" then	
		return FALSE
	end
	
	if type(key) == "string" and key:sub(0, 2) == "Is" then
		return FALSE
	end

	error(("tried to index %q on a NULL value"):format(key), 2)
end

util.DeclareMetaTable("null_meta", NULL)

GetNULL = GetNULL or function() return setmetatable({}, NULL) end

function MakeNULL(var)
	setmetatable(var, getmetatable(GetNULL()))
end

_G.NULL = GetNULL()