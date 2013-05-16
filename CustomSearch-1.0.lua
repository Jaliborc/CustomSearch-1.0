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


--[[ Parsing ]]--

function Lib:Matches(object, search, filters)
	if object then
		self.filters = filters
		self.object = object

		return self:MatchAll(search or '')
	end
end

function Lib:MatchAll(search)
	for phrase in search:lower():gmatch('[^&]+') do
		if not self:MatchAny(phrase) then
      		return
		end
	end

	return true
end

function Lib:MatchAny(search)
	for phrase in search:gmatch('[^|]+') do
		if self:Match(phrase) then
        	return true
		end
	end
end

function Lib:Match(search)
	local tag, rest = search:match('^%s*(%S+):(.*)$')
	if tag then
		tag = '^' .. tag
		search = rest
	end

	local words = search:gmatch('%S+')
	for word in words do
		local negate, operator = 1

		if word:find('^not?$') or word:find('^[!~]=*$') then
			negate = -1
			word = words() or ''
		end

		if word:find('^=*[<>]=*$') then
			operator = word
			word = words()
		end

		local result = self:Filter(tag, operator, word) and 1 or -1
		if result * negate ~= 1 then
			return
		end
	end

	return true
end


--[[ Filtering ]]--

function Lib:Filter(tag, operator, search)
	if not search then
		return true
	end

	if tag then
		for _, filter in pairs(self.filters) do
			for _, value in pairs(filter.tags or {}) do
				if value:find(tag) then
					return self:UseFilter(filter, operator, search)
				end
			end
		end
	else
		for _, filter in pairs(self.filters) do
			if not filter.onlyTags and self:UseFilter(filter, operator, search) then
				return true
			end
		end
	end
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
	if op then
		if op:find('<') then
			 if op:find('=') then
			 	return a <= b
			 end

			 return a < b
		end

		if op:find('>')then
			if op:find('=') then
			 	return a >= b
			end

			return a > b
		end
	end

	return a == b
end

setmetatable(Lib, {__call = Lib.Matches})