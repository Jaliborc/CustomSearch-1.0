--[[
	ItemSearch
		An item text search engine of some sort
--]]

local Lib = LibStub:NewLibrary('LibItemSearch-1.1', 2)
if Lib then
	Lib.filters = {}
else
	return
end

local function useful(a)
	return a and #a > 0
end

local function lower(a)
	return (a or ''):lower()
end


--[[ User API ]]--

function Lib:Matches(link, search)
	if link then
		return self:MatchAll(link, strsplit('&', lower(search)))
	end
end

function Lib:InSet(link, search)
	if IsEquippableItem(link) then
		local id = tonumber(link:match('item:(%-?%d+)'))
		return self:BelongsToSet(id, lower(search))
	end
end


--[[ Parsing ]]--

function Lib:MatchAll(item, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if not self:MatchOne(item, strsplit('|', search)) then
      		return
		end
	end

	return true
end

function Lib:MatchOne(item, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if useful(search) and self:Match(item, search) then
        	return true
		end
	end
end

function Lib:Match(item, search)
	local negated = search:match('^[!~][%s]*(.+)$')
	if negated then
		return not self:Filter(item, negated)
	end

	return self:Filter(item, search, true)
end


--[[ Filtering ]]--

function Lib:NewFilter(object)
	self.filters[object.id] = object
end

function Lib:IterateFilters()
	return pairs(self.filters)
end

function Lib:Filter(item, search, default)
	local tag, rest = search:match('^[%s]*(%w+):(.*)$')
	if tag then
		tag = '^' .. tag
		search = rest
	end

	local operator, search = search:match('^[%s]*([%>%<%=]*)[%s]*(.-)[%s]*$')
	if useful(search) then
		operator = useful(operator) and operator

		if tag then
			for id, filter in self:IterateFilters() do
				if filter.tags then
					for _, value in pairs(filter.tags) do
						if value:find(tag) then
							return self:UseFilter(filter, item, operator, search)
						end
					end
				end
			end
		else
			for id, filter in self:IterateFilters() do
				if not filter.onlyTags and self:UseFilter(filter, item, operator, search) then
					return true
				end
			end
			
			return false
		end
	end

	return default
end

function Lib:UseFilter(filter, item, operator, search)
	local capture1, capture2, capture3 = filter:canSearch(operator, search)
	if capture1 then
		return filter:findItem(item, operator, capture1, capture2, capture3)
	end
end