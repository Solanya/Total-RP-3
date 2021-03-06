----------------------------------------------------------------------------------
--- Total RP 3
--- ---------------------------------------------------------------------------
--- Copyright 2014-2019 Renaud "Ellypse" Parize <ellypse@totalrp3.info> @EllypseCelwe
---
--- Licensed under the Apache License, Version 2.0 (the "License");
--- you may not use this file except in compliance with the License.
--- You may obtain a copy of the License at
---
--- 	http://www.apache.org/licenses/LICENSE-2.0
---
--- Unless required by applicable law or agreed to in writing, software
--- distributed under the License is distributed on an "AS IS" BASIS,
--- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--- See the License for the specific language governing permissions and
--- limitations under the License.
----------------------------------------------------------------------------------

---@type TRP3_API
local _, TRP3_API = ...;
local Ellyb = TRP3_API.Ellyb;

--region Total RP 3 imports
local loc = TRP3_API.loc;
local Events = TRP3_API.Events;
local getConfigValue = TRP3_API.configuration.getValue;
local registerConfigKey = TRP3_API.configuration.registerConfigKey;
local displayDropDown = TRP3_API.ui.listbox.displayDropDown;
--endregion

--region Ellyb imports
local YELLOW = Ellyb.ColorManager.YELLOW
--endregion

--region WoW imports
local after = C_Timer.After;
local GetTime = GetTime;
--endregion

local CONFIG_MAP_BUTTON_POSITION = "MAP_BUTTON_POSITION";
---@type Button
local WorldMapButton = TRP3_WorldMapButton;

local NORMAL_STATE_MAP_ICON = Ellyb.Icon("icon_treasuremap");
local ON_COOLDOWN_STATE_MAP_ICON = Ellyb.Icon("ability_mage_timewarp")

--region Configuration
Events.registerCallback(Events.WORKFLOW_ON_LOADED, function()
	registerConfigKey(CONFIG_MAP_BUTTON_POSITION, "BOTTOMLEFT");

	local function placeMapButton()
		local position = getConfigValue(CONFIG_MAP_BUTTON_POSITION)

		WorldMapButton:SetParent(WorldMapFrame.BorderFrame);
		WorldMapButton:ClearAllPoints();

		local xPadding = 10;
		local yPadding = 10;

		if position == "TOPRIGHT" then
			xPadding = -10;
			yPadding = -45;
		elseif position == "TOPLEFT" then
			yPadding = -30;
		elseif position == "BOTTOMRIGHT" then
			xPadding = -10;
			yPadding = 40;
		end

		WorldMapButton:SetPoint(position, WorldMapFrame.ScrollContainer, position, xPadding, yPadding);
	end

	tinsert(TRP3_API.configuration.CONFIG_FRAME_PAGE.elements, {
		inherit = "TRP3_ConfigH1",
		title = loc.CO_MAP_BUTTON,
	});

	tinsert(TRP3_API.configuration.CONFIG_FRAME_PAGE.elements, {
		inherit = "TRP3_ConfigDropDown",
		widgetName = "TRP3_ConfigurationFrame_MapButtonWidget",
		title = loc.CO_MAP_BUTTON_POS,
		listContent = {
			{loc.CO_ANCHOR_BOTTOM_LEFT, "BOTTOMLEFT"},
			{loc.CO_ANCHOR_TOP_LEFT, "TOPLEFT"},
			{loc.CO_ANCHOR_BOTTOM_RIGHT, "BOTTOMRIGHT"},
			{loc.CO_ANCHOR_TOP_RIGHT, "TOPRIGHT"}
		},
		listCallback = placeMapButton,
		listCancel = true,
		configKey = CONFIG_MAP_BUTTON_POSITION,
	});

	--{{{ UI setup
	NORMAL_STATE_MAP_ICON:Apply(WorldMapButton.Icon);
	---@type Tooltip
	Ellyb.Tooltips.getTooltip(WorldMapButton)
		 :SetTitle(loc.MAP_BUTTON_TITLE)
		 :OnShow(function(tooltip)
		tooltip:AddTempLine(WorldMapButton.subtitle)
	end)
	--}}}

	placeMapButton();
end)
--endregion

--region Broadcast Lifecycle
-- When we get BROADCAST_CHANNEL_CONNECTING we'll ensure the button is
-- disabled and tell the user things are firing up.
Events.registerCallback(Events.BROADCAST_CHANNEL_CONNECTING, function()
	WorldMapButton:SetEnabled(false);
	WorldMapButton.subtitle = YELLOW(loc.MAP_BUTTON_SUBTITLE_CONNECTING);
	WorldMapButton.Icon:SetDesaturated(true);
end);

-- If we get BROADCAST_CHANNEL_OFFLINE we'll ensure the button remains
-- disabled and dump the localised error into the tooltip, to be useful.
Events.registerCallback(Events.BROADCAST_CHANNEL_OFFLINE, function(reason)
	WorldMapButton:SetEnabled(false);
	WorldMapButton.subtitle = YELLOW(loc.MAP_BUTTON_SUBTITLE_OFFLINE):format(reason);
	WorldMapButton.Icon:SetDesaturated(true);
end);

-- When we get BROADCAST_CHANNEL_READY it's time to enable the button use the
-- standard tooltip description.
Events.registerCallback(Events.BROADCAST_CHANNEL_READY, function()
	WorldMapButton:SetEnabled(true);
	WorldMapButton.subtitle = YELLOW(loc.MAP_BUTTON_SUBTITLE);
	WorldMapButton.Icon:SetDesaturated(false);
end);

--endregion

WorldMapButton:SetScript("OnClick", function(self)
	local structure = {};
	---@param scan MapScanner
	for scanID, scan in pairs(TRP3_API.MapScannersManager.getAllScans()) do
		if scan:CanScan() then
			tinsert(structure, { scan:GetActionString(), scanID });
		end
	end
	if #structure == 0 then
		tinsert(structure, {loc.MAP_BUTTON_NO_SCAN, nil});
	end
	displayDropDown(self, structure, TRP3_API.MapScannersManager.launch, 0, true);
end);

function WorldMapButton.resetCooldown()
	WorldMapButton:Enable();
	NORMAL_STATE_MAP_ICON:Apply(WorldMapButton.Icon);
end

function WorldMapButton.startCooldown(timer)
	WorldMapButton:Disable();
	ON_COOLDOWN_STATE_MAP_ICON:Apply(WorldMapButton.Icon);
	WorldMapButton.Cooldown:SetCooldown(GetTime(), timer)
	after(timer, WorldMapButton.resetCooldown)
end

TRP3_API.WorldMapButton = WorldMapButton;
