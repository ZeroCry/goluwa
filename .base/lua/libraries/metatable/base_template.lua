local metatable = (...) or _G.metatable

do
	local META = {}

	function META:__tostring()
		if self.ClassName ~= self.Type then
			return ("%s:%s[%p]"):format(self.Type, self.ClassName, self)
		else
			return ("%s[%p]"):format(self.Type, self)
		end
	end

	function META.New(meta, tbl, skip_gc_callback)
		return metatable.CreateObject(nil, meta, tbl, skip_gc_callback)
	end

	function META:Remove(...)
		if self.OnRemove then 
			self:OnRemove(...) 
		end
		metatable.MakeNULL(self)
	end

	function META:IsValid()
		return true
	end

	function META:GetTrace()
		return self.debug_trace or ""
	end

	function metatable.CreateTemplate(super_type, sub_type, skip_register)
		local template = type(super_type) == "table" and super_type or {}
		
		for k, v in pairs(META) do
			template[k] = template[k] or v
		end
		
		if type(super_type) == "string" then
			template.Type = super_type
			template.ClassName = sub_type or super_type
		end
		
		if not skip_register then
			metatable.Register(template)
		end
		
		template.__index = template
		
		return template
	end
end

function metatable.CreateObject(meta, override, skip_gc_callback)
	override = override or {}
	
	if type(meta) == "string" then
		meta = metatable.GetRegistered(meta)
	end
		
	local self = setmetatable(override, meta) 
	
	if not skip_gc_callback then
		utility.SetGCCallback(self)
	end
	
	self.debug_trace = debug.trace(true)
	
	metatable.created_objects = metatable.created_objects or utility.CreateWeakTable()
	table.insert(metatable.created_objects, self)
	
	return self
end

function metatable.GetCreated()
	return metatable.created_objects
end
