local CritForcist = {}
local playerGUID = UnitGUID("player")

-- Frame for crit events
local eventFrame = CreateFrame("Frame", "CritEventFrame", UIParent)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- Variables
local critDatabase = {}
local lastAnnouncementTime = 0
local announcementCooldown = 10 -- Cooldown period in seconds

-- Cache for spell details
local spellCache = {}

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
	end
	return spell.name, spell.link, spell.icon
end

-- Create the crit frame
local critFrame = CreateFrame("Frame", "CritFrame", UIParent)
critFrame:SetSize(400, 100)
critFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 300)
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
critFrame.amount:SetTextColor(1, 0, 0) -- Red color

-- Function to announce new high crits
local function AnnounceNewHighCrit(spellName, spellLink, amount)
	if not IsInGroup() then
		return
	end -- Only announce if in a group

	local currentTime = GetTime()
	if currentTime - lastAnnouncementTime < announcementCooldown then
		return
	end
	lastAnnouncementTime = currentTime

	local messages = {
		"Behold! My " .. spellLink .. " just hit a record-high crit of " .. FormatNumber(amount) .. "!",
		"Boom! My " .. spellLink .. " crit for a record " .. FormatNumber(amount) .. "!",
		"I just hit my highest crit ever! " .. spellLink .. " for " .. FormatNumber(amount) .. "!",
	}
	local message = messages[math_random(#messages)]
	SendChatMessage(message, "PARTY")
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

	PlaySound(SOUNDKIT.RAID_WARNING, "Master")

	if not critFrame.animGroup then
		critFrame.animGroup = critFrame:CreateAnimationGroup()

		local moveUp = critFrame.animGroup:CreateAnimation("Translation")
		moveUp:SetOffset(0, 200)
		moveUp:SetDuration(2.0)
		moveUp:SetSmoothing("OUT")

		local fadeOut = critFrame.animGroup:CreateAnimation("Alpha")
		fadeOut:SetFromAlpha(1)
		fadeOut:SetToAlpha(0)
		fadeOut:SetDuration(2.0)
		fadeOut:SetStartDelay(1.5)
		fadeOut:SetSmoothing("OUT")

		critFrame.animGroup:SetScript("OnFinished", function()
			critFrame:Hide()
		end)
	end
	critFrame.animGroup:Play()
end

-- Function to track highest crits
local function TrackHighestCrit(spellName, spellLink, spellIcon, amount)
	local highestCrit = critDatabase[spellName] or 0
	if amount > highestCrit then
		critDatabase[spellName] = amount
		AnnounceNewHighCrit(spellName, spellLink, amount)
		ShowCritAnimation(spellLink, spellIcon, amount)
	end
end

-- Event handlers
local function OnADDON_LOADED(_, addonName)
	if addonName == "CritForcist" then
		if not CritForcistDB then
			CritForcistDB = {}
		end
		critDatabase = CritForcistDB
	end
end

local function OnPLAYER_LOGOUT()
	CritForcistDB = critDatabase
end

local function OnCOMBAT_LOG_EVENT_UNFILTERED()
	local _, subevent, _, sourceGUID = CombatLogGetCurrentEventInfo()
	if sourceGUID ~= playerGUID then
		return
	end -- Only process if player caused the event
	if subevent ~= "SWING_DAMAGE" and subevent ~= "SPELL_DAMAGE" then
		return
	end

	local spellId, amount, critical
	if subevent == "SWING_DAMAGE" then
		amount, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
		spellId = 6603 -- Auto Attack spell ID
	elseif subevent == "SPELL_DAMAGE" then
		spellId, _, _, amount, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
	end

	if critical then
		local spellName, spellLink, spellIcon = GetSpellDetails(spellId)
		TrackHighestCrit(spellName, spellLink, spellIcon, amount)
	end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		OnADDON_LOADED(...)
	elseif event == "PLAYER_LOGOUT" then
		OnPLAYER_LOGOUT()
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

-- Note: Add options menu, more animations, and sound toggle in future updates here
