local Lib = LibStub('LibItemSearch-1.1')
if #Lib.filters > 0 then
	return
end

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
	id = 'itemName',
  	tags = {'n', 'name'},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	findItem = function(self, item, _, search)
		local name = item:match('%[(.-)%]')
		return match(search, name)
	end
}

Lib:NewFilter {
	id = 'itemType',
	tags = {'t', 'type', 'slot'},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	findItem = function(self, item, _, search)
		local type, subType, _, equipSlot = select(6, GetItemInfo(item))
		return match(search, type, subType, _G[equipSlot])
	end
}

Lib:NewFilter {
	id = 'itemLevel',
	tags = {'l', 'level', 'lvl'},

	canSearch = function(self, _, search)
		return tonumber(search)
	end,

	findItem = function(self, link, operator, num)
		local lvl = select(4, GetItemInfo(link))
		if lvl then
			return compare(operator, lvl, num)
		end
	end
}


--[[ Quality ]]--

local qualities = {}
for i = 0, #ITEM_QUALITY_COLORS do
  qualities[i] = _G['ITEM_QUALITY' .. i .. '_DESC']:lower()
end

Lib:NewFilter {
	id = 'itemQuality',
	tags = {'q', 'quality'},

	canSearch = function(self, _, search)
		for i, name in pairs(qualities) do
		  if name:find(search) then
			return i
		  end
		end
	end,

	findItem = function(self, link, operator, num)
		local quality = select(3, GetItemInfo(link))
		return compare(operator, quality, num)
	end,
}


--[[ Tooltip Searches ]]--

local tooltipCache = setmetatable({}, {__index = function(t, k) local v = {} t[k] = v return v end})
local tooltipScanner = _G['LibItemSearchTooltipScanner'] or CreateFrame('GameTooltip', 'LibItemSearchTooltipScanner', UIParent, 'GameTooltipTemplate')

local function link_FindSearchInTooltip(itemLink, search)
	local itemID = itemLink:match('item:(%d+)')
	if not itemID then
		return
	end
	
	local cachedResult = tooltipCache[search][itemID]
	if cachedResult ~= nil then
		return cachedResult
	end

	tooltipScanner:SetOwner(UIParent, 'ANCHOR_NONE')
	tooltipScanner:SetHyperlink(itemLink)

	local result = false
	if tooltipScanner:NumLines() > 1 and _G[tooltipScanner:GetName() .. 'TextLeft2']:GetText() == search then
		result = true
	elseif tooltipScanner:NumLines() > 2 and _G[tooltipScanner:GetName() .. 'TextLeft3']:GetText() == search then
		result = true
	end

	tooltipCache[search][itemID] = result
	return result
end


Lib:NewFilter {
	id = 'bindType',

	canSearch = function(self, _, search)
		return self.keywords[search]
	end,

	findItem = function(self, itemLink, _, search)
		return search and link_FindSearchInTooltip(itemLink, search)
	end,

	keywords = {
    	['soulbound'] = ITEM_BIND_ON_PICKUP,
    	['bound'] = ITEM_BIND_ON_PICKUP,
		['boe'] = ITEM_BIND_ON_EQUIP,
		['bop'] = ITEM_BIND_ON_PICKUP,
		['bou'] = ITEM_BIND_ON_USE,
		['quest'] = ITEM_BIND_QUEST,
		['boa'] = ITEM_BIND_TO_BNETACCOUNT
	}
}

Lib:NewFilter {
	id = 'tooltip',
	tags = {'tt', 'tip', 'tooltip'},
	onlyTags = true,

	canSearch = function(self, _, search)
		return search
	end,

	findItem = function(self, link, _, search)
		tooltipScanner:SetOwner(UIParent, 'ANCHOR_NONE')
		tooltipScanner:SetHyperlink(link)

		for i = 1, tooltipScanner:NumLines() do
			local text =  _G[tooltipScanner:GetName() .. 'TextLeft' .. i]:GetText():lower()
			
			if text:find(search) then
				return true
			end
		end

		return false
	end,
}


--[[ Equipment Sets ]]--

if IsAddOnLoaded('ItemRack') then
	local sameID = ItemRack.SameID

	function Lib:BelongsToSet(id, search)
		for name, set in pairs(ItemRackUser.Sets) do
			if name:sub(1,1) ~= '' and match(search, name) then
				for _, item in pairs(set.equip) do
					if sameID(id, item) then
						return true
					end
				end
			end
		end
	end

elseif IsAddOnLoaded('Wardrobe') then
	function Lib:BelongsToSet(id, search)
		for _, outfit in ipairs(Wardrobe.CurrentConfig.Outfit) do
			local name = outfit.OutfitName
			if match(search, name) then
				for _, item in pairs(outfit.Item) do
					if item.IsSlotUsed == 1 and item.ItemID == id then
						return true
					end
				end
			end
		end
	end

else
	function Lib:BelongsToSet(id, search)
		for i = 1, GetNumEquipmentSets() do
			local name = GetEquipmentSetInfo(i)
			if match(search, name) then
				local items = GetEquipmentSetItemIDs(name)
				for _, item in pairs(items) do
					if id == item then
						return true
					end
				end
			end
		end
	end
end

Lib:NewFilter {
	id = 'equipmentSet',
	tags = {'s', 'set'},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	findItem = function(self, link, _, search)
		return Lib:InSet(link, search)
	end,
}