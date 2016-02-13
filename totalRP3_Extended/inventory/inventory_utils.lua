----------------------------------------------------------------------------------
-- Total RP 3
--	---------------------------------------------------------------------------
--	Copyright 2015 Sylvain Cossement (telkostrasz@totalrp3.info)
--
--	Licensed under the Apache License, Version 2.0 (the "License");
--	you may not use this file except in compliance with the License.
--	You may obtain a copy of the License at
--
--		http://www.apache.org/licenses/LICENSE-2.0
--
--	Unless required by applicable law or agreed to in writing, software
--	distributed under the License is distributed on an "AS IS" BASIS,
--	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--	See the License for the specific language governing permissions and
--	limitations under the License.
----------------------------------------------------------------------------------
local Globals, Events, Utils = TRP3_API.globals, TRP3_API.events, TRP3_API.utils;
local EMPTY = TRP3_API.globals.empty;
local getClass = TRP3_API.extended.getClass;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- UTILS func
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function isContainerByClass(item)
	return item and item.CO;
end
TRP3_API.inventory.isContainerByClass = isContainerByClass;

local function isUsableByClass(item)
	return item and item.US;
end
TRP3_API.inventory.isUsableByClass = isUsableByClass;

local function isContainerByClassID(itemID)
	return itemID == "main" or isContainerByClass(getClass(itemID));
end
TRP3_API.inventory.isContainerByClassID = isContainerByClassID;

local function isUsableByClass(item)
	return item and item.US;
end
TRP3_API.inventory.isContainerByClass = isContainerByClass;

local function isUsableByClassID(itemID)
	return isUsableByClass(getClass(itemID));
end
TRP3_API.inventory.isUsableByClassID = isUsableByClassID;

local function getBaseClassDataSafe(itemClass)
	local icon = "TEMP";
	local name = UNKNOWN;
	local qa = 1;
	if itemClass and itemClass.BA then
		if itemClass.BA.IC then
			icon = itemClass.BA.IC;
		end
		if itemClass.BA.NA then
			name = itemClass.BA.NA;
		end
		if itemClass.BA.QA then
			qa = itemClass.BA.QA;
		end
	end
	return icon, name, qa;
end
TRP3_API.inventory.getBaseClassDataSafe = getBaseClassDataSafe;

local function checkContainerInstance(container)
	if not container.content then
		container.content = {};
	end
end
TRP3_API.inventory.checkContainerInstance = checkContainerInstance;

function TRP3_API.inventory.getItemTextLine(itemClass)
	local icon, name = getBaseClassDataSafe(itemClass);
	return Utils.str.icon(icon, 25) .. " " .. name;
end

local ITEM_QUALITY_COLORS = { -- TODO: calcul
	{"|cff9d9d9d", 157/255, 157/255, 157/255},
	{"|cffffffff", 1, 1, 1},
	{"|cff1eff00", 30/255, 1, 0},
	{"|cff0070dd", 0, 112/255, 221/255},
	{"|cffa335ee", 163/255, 53/255, 238/255},
	{"|cffff8000", 1, 128/255, 0},
}

local function getQualityColorTab(quality)
	quality = quality or 1;
	return ITEM_QUALITY_COLORS[quality];
end
TRP3_API.inventory.getQualityColorTab = getQualityColorTab;

local function getQualityColorText(quality)
	return getQualityColorTab(quality)[1];
end
TRP3_API.inventory.getQualityColorText = getQualityColorText;

local function getQualityColorRGB(quality)
	local tab = getQualityColorTab(quality);
	return tab[2], tab[3], tab[4];
end
TRP3_API.inventory.getQualityColorRGB = getQualityColorRGB;

local function getItemLink(itemClass)
	local icon, name, qa = getBaseClassDataSafe(itemClass);
	return getQualityColorText(qa) .. "[" .. name .. "]|r";
end
TRP3_API.inventory.getItemLink = getItemLink;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- CONTAINER func
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function isItemInContainer(item, container)
	if not container or not container.content or not isContainerByClassID(container.id) then
		return false;
	end
	if item == container then -- Check by ref
		return true;
	end

	local contains = false;
	for _, slot in pairs(container.content) do
		contains = isItemInContainer(item, slot);
	end
	return contains;
end
TRP3_API.inventory.isItemInContainer = isItemInContainer;

local function countItemInstances(container, itemID)
	local count = 0;

	for _, slot in pairs(container.content or EMPTY) do
		if slot.id == itemID then
			count = count + (slot.count or 1);
		end
		if isContainerByClassID(slot.id) then
			count = count + countItemInstances(slot, itemID);
		end
	end

	return count;
end
TRP3_API.inventory.countItemInstances = countItemInstances;