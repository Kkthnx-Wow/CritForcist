local GetSpellInfo = GetSpellInfo
local GetSpellLink = GetSpellLink
local GetSpellTexture = GetSpellTexture

-- Initialize player data structure
local playerGUID = UnitGUID("player")
local playerName = UnitName("player")
local playerRealm = GetRealmName()

-- Frame for crit events
local eventFrame = CreateFrame("Frame", "CritEventFrame", UIParent)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- Variables
local lastAnnouncementTime = 0
local announcementCooldown = 150

-- Cache for spell details
local spellCache = {}
local MAX_CACHE_SIZE = 500

-- Constants
local MELEE_ID = 6603
local NOTEWORTHY_CRIT_DIFFERENCE = 100

-- Local references to global functions for performance
local GetTime = GetTime
local math_random = math.random
local string_format = string.format

-- Utility function to format numbers
local function FormatNumber(amount)
	if amount >= 1000000 then
		return string_format("%.1fm", amount / 1000000)
	elseif amount >= 1000 then
		return string_format("%.1fk", amount / 1000)
	else
		return tostring(amount)
	end
end

-- Function to manage spell cache size
local cacheSize = 0
local function manageCache(spellId)
	if cacheSize >= MAX_CACHE_SIZE then
		for k in pairs(spellCache) do
			spellCache[k] = nil
			cacheSize = cacheSize - 1
			break -- remove only one entry
		end
	end
	cacheSize = cacheSize + 1
end

-- Function to get spell details with caching
local function GetSpellDetails(spellId)
	local spell = spellCache[spellId]
	if not spell then
		spell = {
			name = GetSpellInfo(spellId) or "Auto Attack",
			link = GetSpellLink(spellId) or spell.name,
			icon = GetSpellTexture(spellId) or "Interface\\Icons\\INV_Misc_QuestionMark",
		}
		spellCache[spellId] = spell
		manageCache(spellId)
	end
	return spell.name, spell.link, spell.icon
end

-- Create the crit frame
local critFrame = CreateFrame("Frame", "CritFrame", UIParent)
critFrame:SetSize(400, 100)
critFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 400)
critFrame:Hide()

critFrame.icon = critFrame:CreateTexture(nil, "BACKGROUND")
critFrame.icon:SetSize(40, 40)
critFrame.icon:SetPoint("LEFT", critFrame, "LEFT", 10, 0)

critFrame.text = critFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
critFrame.text:SetPoint("LEFT", critFrame.icon, "RIGHT", 10, 0)
critFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")

critFrame.amount = critFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
critFrame.amount:SetPoint("LEFT", critFrame.text, "RIGHT", 10, 0)
critFrame.amount:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")
critFrame.amount:SetTextColor(1, 0, 0)

-- Function to announce new high crits
local function AnnounceNewHighCrit(spellName, spellLink, amount)
	local currentTime = GetTime()
	if currentTime - lastAnnouncementTime < announcementCooldown then
		return
	end
	lastAnnouncementTime = currentTime

	local messages = {
		"Behold! My " .. spellLink .. " crit for " .. FormatNumber(amount) .. "!",
		"Boom! " .. FormatNumber(amount) .. " from " .. spellLink .. "!",
		"High score! " .. spellLink .. " crit " .. FormatNumber(amount) .. "!",
		"LOL! " .. spellLink .. " just crit for " .. FormatNumber(amount) .. "!",
		"New record! " .. spellLink .. " at " .. FormatNumber(amount) .. "!",
		"OwO What's this? " .. FormatNumber(amount) .. " crit from " .. spellLink .. "!",
		"Crushed it! " .. spellLink .. " for " .. FormatNumber(amount) .. "!",
		"Watch out! " .. spellLink .. " crit " .. FormatNumber(amount) .. "!",
		"Yikes! " .. FormatNumber(amount) .. " crit from " .. spellLink .. "!",
		"Top that! " .. spellLink .. " crit " .. FormatNumber(amount) .. "!",
		"Kaboom! " .. spellLink .. " for " .. FormatNumber(amount) .. "!",
		"Nice! " .. spellLink .. " crit " .. FormatNumber(amount) .. "!",
		"Ha! " .. FormatNumber(amount) .. " from " .. spellLink .. "!",
		"Epic crit! " .. spellLink .. " " .. FormatNumber(amount) .. "!",
		"Wow! " .. spellLink .. " crit " .. FormatNumber(amount) .. "!",
	}
	local message = messages[math_random(#messages)]

	if IsInRaid() then
		SendChatMessage(message, "RAID")
	elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
		SendChatMessage(message, "PARTY")
	else
		SendChatMessage(message, "EMOTE")
	end
end

-- Function to show crit animation
local function ShowCritAnimation(spellLink, spellIcon, amount)
	if critFrame.animGroup and critFrame.animGroup:IsPlaying() then
		critFrame.animGroup:Stop()
	end

	critFrame.icon:SetTexture(spellIcon)
	critFrame.text:SetText(spellLink .. " Crit For")
	critFrame.amount:SetText(FormatNumber(amount))
	critFrame:Show()

	-- PlaySound(SOUNDKIT.RAID_WARNING, "Master")

	if not critFrame.animGroup then
		critFrame.animGroup = critFrame:CreateAnimationGroup()

		local moveUp = critFrame.animGroup:CreateAnimation("Translation")
		moveUp:SetOffset(0, 100)
		moveUp:SetDuration(2.0)
		moveUp:SetSmoothing("OUT")

		local fadeOut = critFrame.animGroup:CreateAnimation("Alpha")
		fadeOut:SetFromAlpha(1)
		fadeOut:SetToAlpha(0)
		fadeOut:SetDuration(2.0) -- Increased from 2.0 to 4.0 for slower fade
		fadeOut:SetStartDelay(1.5)
		fadeOut:SetSmoothing("OUT")

		critFrame.animGroup:SetScript("OnFinished", function()
			critFrame:Hide()
		end)
	end

	if critFrame.animGroup and not critFrame.animGroup:IsPlaying() then
		critFrame.animGroup:Play()
	end
end

-- Function to track highest crits
local function TrackHighestCrit(spellName, amount)
	local playerDB = CritForcistDB[playerName][playerRealm] or {}
	local spellEntry = playerDB[spellName] or {}

	-- Only update if this crit is higher than previously stored
	if not spellEntry.highestCrit or amount > spellEntry.highestCrit then
		local previousHighest = spellEntry.highestCrit or 0 -- Store the previous highest crit
		spellEntry.highestCrit = amount

		-- Now compare with the previous highest crit to decide if it's noteworthy
		if amount - previousHighest >= NOTEWORTHY_CRIT_DIFFERENCE then
			-- Note: Here we need the spell link for announcement, but we don't save it in DB
			local spellLink = GetSpellLink(GetSpellInfo(spellName)) or spellName
			local _, _, spellIcon = GetSpellDetails(spellName)
			AnnounceNewHighCrit(spellName, spellLink, amount)
			ShowCritAnimation(spellLink, spellIcon, amount)
		end

		playerDB[spellName] = spellEntry
		CritForcistDB[playerName][playerRealm] = playerDB
	end
end

-- Event handlers with error handling
local function OnADDON_LOADED(addonName)
	if addonName == "CritForcist" then
		CritForcistDB = CritForcistDB or {}
		CritForcistDB[playerName] = CritForcistDB[playerName] or {}
		CritForcistDB[playerName][playerRealm] = CritForcistDB[playerName][playerRealm] or {}

		eventFrame:UnregisterEvent("ADDON_LOADED")
	end
end

local function OnCOMBAT_LOG_EVENT_UNFILTERED()
	local _, subevent, _, sourceGUID = CombatLogGetCurrentEventInfo()
	local spellId, amount, critical

	if subevent == "SWING_DAMAGE" then
		amount, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
		spellId = MELEE_ID
	elseif subevent == "SPELL_DAMAGE" then
		spellId, _, _, amount, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
	end

	if critical and sourceGUID == playerGUID then
		local action = spellId and GetSpellLink(spellId) or MELEE
		TrackHighestCrit(action, amount)
	end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		OnADDON_LOADED(...)
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		OnCOMBAT_LOG_EVENT_UNFILTERED()
	end
end)

-- Test command for the animation popup
SLASH_CRITFORCISTTEST1 = "/cft"
SlashCmdList["CRITFORCISTTEST"] = function()
	local testSpellName = "Test Spell"
	local testSpellLink = "|cff71d5ff|Hspell:12345|h[Test Spell]|h|r"
	local testSpellIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
	local testAmount = 123456
	ShowCritAnimation(testSpellLink, testSpellIcon, testAmount)
end
