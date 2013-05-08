local Lib = LibStub('LibPetSearch-1.0')
if #Lib.filters > 0 then
	return
end

local _, Addon = ...
local Journal = Addon.Journal

local function match(search, ...)
	for i = 1, select('#', ...) do
		local text = select(i, ...)
		if text and text:lower():find(search) then
			return true
		end
	end
end

local function compare(op, a, b)
	if op == '<=' then
		return a <= b
	end

	if op == '<' then
		return a < b
	end

	if op == '>' then
		return a > b
	end

	if op == '>=' then
		return a >= b
	end

	return a == b
end


--[[ Basics ]]--

Lib:NewFilter {
	id = 'name',
  	tags = {'n', 'name'},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	match = function(self, pet, _, search)
		local name = Journal:GetInfo(pet)
		return match(search, name)
	end
}

Lib:NewFilter {
	id = 'type',
	tags = {'t', 'type'},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	match = function(self, pet, _, search)
		local name = Journal:GetTypeName(pet)
		return match(search, name)
	end
}

Lib:NewFilter {
	id = 'source',
	tags = {'s', 'source', 'l', 'location'},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	match = function(self, pet, _, search)
		local _, name = Journal:GetSource(pet)
		return match(search, name)
	end
}