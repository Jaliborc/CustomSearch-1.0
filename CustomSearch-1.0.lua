--[[
Copyright 2013-2026 João Cardoso
CustomSearch is distributed under the terms of the GNU General Public License (Version 3).
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

This file is part of CustomSearch.
--]]

local Lib = LibStub:NewLibrary('CustomSearch-1.0', 14)
if not Lib then return end

local Cache = setmetatable({}, {__mode = 'k'})
local None = {}

local pairs, select, format, tinsert, tconcat = pairs, select, format, tinsert, table.concat
local yup = function(v) return v and true end
local join = function(words, sep)
	if #words > 1 then
		return '(' .. tconcat(words, sep) .. ')'
	end
	return words[1]
end


--[[ Compiler ]]--

function Lib:Matches(object, search, filters)
	if object then
		local cache = Cache[filters]
		if not cache then
			cache = setmetatable({}, {__mode = 'v'})
			Cache[filters] = cache
		end

		local func = cache[search or '']
		if not func then
			func = self:Compile(search, filters)
			cache[search or ''] = func
		end

		return func(object)
	end
end

function Lib:Compile(search, filters)
	self.filters = filters

	local condition = self:CompileAND(' ' .. self:Clean(search or '') .. ' ')
	if condition then
		local code = format([[
			local self, filters = ...
			return function(object)
				if object then
					self.object = object
					return %s
				end
			end]], condition)

		return loadstring(code)(self, filters)
	end
	return yup
end

function Lib:CompileAND(search)
	local chunks = {}
	for phrase in search:gsub(self.AND, '&'):gmatch('[^&]+') do
		tinsert(chunks, self:CompileOR(phrase))
	end
	return #chunks > 0 and tconcat(chunks, ' and ')
end

function Lib:CompileOR(search)
	local chunks = {}
	for phrase in search:gsub(self.OR, '|'):gmatch('[^|]+') do
		tinsert(chunks, self:CompileWords(phrase))
	end

	return join(chunks, ' or ')
end

function Lib:CompileWords(search)
	local tag, rest = search:match('^%s*(%S+):(.*)$')
	if tag then
		search = rest
	end

	local chunks = {}
	local words = search:gmatch('%S+')
	for word in words do
		local negate, rest = word:match('^([!~]=*)(.*)$')
		if negate or word == self.NOT then
			word = rest and rest ~= '' and rest or words() or ''
			negate = true
		end

		local operator, rest = word:match('^(=*[<>]=*)(.*)$')
		if operator then
			word = rest ~= '' and rest or words()
			operator = format('%q', operator)
		end

		local result = self:CompileFilters(word, tag, operator or 'nil')
		if result then
			tinsert(chunks, (negate and 'not ' or '') .. result)
		end
	end

	return join(chunks, ' and ')
end

function Lib:CompileFilters(word, tag, operator)
	if word then
		local chunks = {}
		for id, filter in pairs(self.filters) do
			if tag then
				for _, value in pairs(filter.tags or None) do
					if value:sub(1, #tag) == tag then
						return format('self:UseFilter(filters.%s, %s, %q)', id, operator, word)
					end
				end
			elseif not filter.onlyTags then
				tinsert(chunks, format('self:UseFilter(filters.%s, %s, %q)', id, operator, word))
			end
		end

		return join(chunks, ' or ')
	end
end


--[[ Deprecated ]]--

function Lib:MatchAll(search)
	for phrase in search:gsub(self.AND, '&'):gmatch('[^&]+') do
		if not self:MatchAny(phrase) then
			return
		end
	end

	return true
end

function Lib:MatchAny(search)
	for phrase in search:gsub(self.OR, '|'):gmatch('[^|]+') do
		if self:Match(phrase) then
			return true
		end
	end
end

function Lib:Match(search)
	local tag, rest = search:match('^%s*(%S+):(.*)$')
	if tag then
		search = rest
	end
	
	local words = search:gmatch('%S+')
	for word in words do
		local negate, rest = word:match('^([!~]=*)(.*)$')
		if negate or word == self.NOT then
			word = rest and rest ~= '' and rest or words() or ''
			negate = -1
		else
			negate = 1
		end

		local operator, rest = word:match('^(=*[<>]=*)(.*)$')
		if operator then
			word = rest ~= '' and rest or words()
		end

		local result = self:Filter(tag, operator, word) and 1 or -1
		if result * negate ~= 1 then
			return false
		end
	end

	return true
end

function Lib:Filter(tag, operator, search)
	if not search then
		return true
	end

	for _, filter in pairs(self.filters) do
		if tag then
			for _, value in pairs(filter.tags or None) do
				if value:sub(1, #tag) == tag then
					return self:UseFilter(filter, operator, search)
				end
			end
		elseif not filter.onlyTags and self:UseFilter(filter, operator, search) then
			return true
		end
	end
end


--[[ Utilities ]]--

function Lib:UseFilter(filter, operator, search)
	local data = {filter:canSearch(operator, search, self.object)}
	if data[1] then
		return filter:match(self.object, operator, unpack(data))
	end
end

function Lib:Find(search, ...)
	for i = 1, select('#', ...) do
		local text = select(i, ...)
		if text and self:Clean(text):find(search, 1, true) then
			return true
		end
	end
end

function Lib:FindOne(search, text)
	return text and self:Clean(text):find(search, 1, true)
end

function Lib:Clean(string)
	return string:lower():gsub('[%z\1-\127\194-\244][\128-\191]', self.ACCENTS):gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
end

function Lib:Compare(op, a, b)
    if op == '<' then
        return a < b
    elseif op == '<=' or op == '=<' then
        return a <= b
    elseif op == '>' then
        return a > b
    elseif op == '>=' or op == '=>' then
        return a >= b
    else
        return a == b
    end
end


--[[ Localization ]]--

do
	local no = {enUS = 'Not', frFR = 'Pas', deDE = 'Nicht'}
	local accents = {
		a = {'à','á','â','ã','å'},
		e = {'è','é','ê','ê','ë'},
		i = {'ì', 'í', 'î', 'ï'},
		o = {'ó','ò','ô','õ'},
		u = {'ù', 'ú', 'û', 'ü'},
		c = {'ç'}, n = {'ñ'}
	}

	Lib.ACCENTS = {}
	for char, accents in pairs(accents) do
		for _, accent in ipairs(accents) do
			Lib.ACCENTS[accent] = char
		end
	end

	Lib.AND = '%s+'.. Lib:Clean(QUEST_LOGIC_AND) .. '%s+'
	Lib.OR = '%s+'.. Lib:Clean(QUEST_LOGIC_OR) ..'%s+'
	Lib.NOT = Lib:Clean(no[GetLocale()] or NO)
	setmetatable(Lib, {__call = Lib.Matches})
end