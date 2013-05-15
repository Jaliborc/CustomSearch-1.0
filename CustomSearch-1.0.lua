--[[
Copyright 2013 João Cardoso
LibCustomSearch is distributed under the terms of the GNU General Public License (Version 3).
As a special exception, the copyright holders of this library give you permission to embed it
with independent modules to produce an addon, regardless of the license terms of these
independent modules, and to copy and distribute the resulting software under terms of your
choice, provided that you also meet, for each embedded independent module, the terms and
conditions of the license of that module. Permission is not granted to modify this library.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the library. If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.

This file is part of LibCustomSearch.
--]]

local Lib = LibStub:NewLibrary('CustomSearch-1.0', 1)
if not Lib then
	return
end

local function useful(a)
	return a and #a > 0
end

local function lower(a)
	return (a or ''):lower()
end


--[[ Parsing ]]--

function Lib:Matches(object, search, filters)
	if object then
		self.filters = filters
		self.object = object

		return self:MatchAll(strsplit(' ', lower(search)))
	end
end

function Lib:MatchAll(...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if not self:MatchOne(strsplit('|', search)) then
      		return
		end
	end

	return true
end

function Lib:MatchOne(...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if useful(search) and self:Match(search) then
        	return true
		end
	end
end

function Lib:Match(search)
	local negated = search:match('^[!~][%s]*(.+)$')
	if negated then
		return not self:Filter(negated)
	end

	return self:Filter(search, true)
end


--[[ Filtering ]]--

function Lib:Filter(search, default)
	local tag, rest = search:match('^[%s]*(%w+):(.*)$')
	if tag then
		tag = '^' .. tag
		search = rest
	end

	local operator, search = search:match('^[%s]*([%>%<%=]*)[%s]*(.-)[%s]*$')
	if useful(search) then
		operator = useful(operator) and operator

		if tag then
			for _, filter in pairs(self.filters) do
				if filter.tags then
					for _, value in pairs(filter.tags) do
						if value:find(tag) then
							return self:UseFilter(filter, operator, search)
						end
					end
				end
			end
		else
			for _, filter in pairs(self.filters) do
				if not filter.onlyTags and self:UseFilter(filter, operator, search) then
					return true
				end
			end
			
			return
		end
	end

	return default
end

function Lib:UseFilter(filter, operator, search)
	local data = {filter:canSearch(operator, search)}
	if data[1] then
		return filter:match(self.object, operator, unpack(data))
	end
end


--[[ Utilities ]]--

function Lib:Find(search, ...)
	for i = 1, select('#', ...) do
		local text = select(i, ...)
		if text and text:lower():find(search) then
			return true
		end
	end
end

function Lib:Compare(op, a, b)
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

setmetatable(Lib, {__call = Lib.Matches})