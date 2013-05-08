--[[
Copyright 2013 João Cardoso
LibPetSearch is distributed under the terms of the GNU General Public License (Version 3).
As a special exception, the copyright holders of this addon do not give permission to
redistribute and/or modify it.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the addon. If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.

This file is part of LibPetSearch.
--]]

local Lib = LibStub:NewLibrary('LibPetSearch-1.0', 1)
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


--[[ Parsing ]]--

function Lib:MatchAll(link, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if not self:MatchOne(link, strsplit('|', search)) then
      		return
		end
	end

	return true
end

function Lib:MatchOne(link, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if useful(search) and self:Match(link, search) then
        	return true
		end
	end
end

function Lib:Match(link, search)
	local negated = search:match('^[!~][%s]*(.+)$')
	if negated then
		return not self:Filter(link, negated)
	end

	return self:Filter(link, search, true)
end


--[[ Filtering ]]--

function Lib:NewFilter(object)
	self.filters[object.id] = object
end

function Lib:IterateFilters()
	return pairs(self.filters)
end

function Lib:Filter(link, search, default)
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
							return self:UseFilter(filter, link, operator, search)
						end
					end
				end
			end
		else
			for id, filter in self:IterateFilters() do
				if not filter.onlyTags and self:UseFilter(filter, link, operator, search) then
					return true
				end
			end
			
			return false
		end
	end

	return default
end

function Lib:UseFilter(filter, link, operator, search)
	local capture1, capture2, capture3 = filter:canSearch(operator, search)
	if capture1 then
		return filter:match(link, operator, capture1, capture2, capture3)
	end
end