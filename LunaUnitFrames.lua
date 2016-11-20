LunaUF = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceDB-2.0", "AceHook-2.1", "FuBarPlugin-2.0", "AceDebug-2.0")
LunaUF:RegisterDB("LunaDB")
LunaUF:SetDebugging(true)

-- Assets ----------------------------------------------------------------------------------
LunaUF.Version = 2100
LunaUF.BS = AceLibrary("Babble-Spell-2.2")
LunaUF.Banzai = AceLibrary("Banzai-1.0")
LunaUF.HealComm = AceLibrary("HealComm-1.0")
LunaUF.DruidManaLib = AceLibrary("DruidManaLib-1.0")
LunaUF.unitList = {"player", "pet", "target", "targettarget", "targettargettarget", "party", "partytarget", "partypet", "raid"}
LunaUF.ScanTip = CreateFrame("GameTooltip", "LunaScanTip", nil, "GameTooltipTemplate")
LunaUF.ScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
LunaUF.modules = {}
_, LunaUF.playerRace = UnitRace("player")
LunaUF.AllianceCheck = {
	["Dwarf"] = true,
	["Human"] = true,
	["Gnome"] = true,
	["NightElf"] = true,
}

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

SLASH_LUFMO1, SLASH_LUFMO2 = "/lunamo", "/lunamouseover"
function SlashCmdList.LUFMO(msg, editbox)
	local func = loadstring(msg)
	if LunaUF.db.profile.mouseover and UnitExists("mouseover") then
		if UnitIsUnit("target", "mouseover") then
			if func then
				func()
			else
				CastSpellByName(msg)
			end
			return
		else
			TargetUnit("mouseover")
			if func then
				func()
			else
				CastSpellByName(msg)
			end
			TargetLastTarget()
			return
		end
	end
	if GetMouseFocus().unit then
		if UnitIsUnit("target", GetMouseFocus().unit) then
			if func then
				func()
			else
				CastSpellByName(msg)
			end
		else
			LunaUF.Units.pauseUpdates = true
			TargetUnit(GetMouseFocus().unit)
			if func then
				func()
			else
				CastSpellByName(msg)
			end
			TargetLastTarget()
			LunaUF.Units.pauseUpdates = nil
		end
	else 
		if func then
			func()
		else
			CastSpellByName(msg)
		end
	end
end

function lufmo(msg)
	SlashCmdList.LUFMO(msg)
end

--------------------------------------------------------------------------------------------

-- Localization Stuff ----------------------------------------------------------------------
LunaUF.L = AceLibrary("AceLocale-2.2"):new("LunaUnitFrames")
local L = LunaUF.L
--------------------------------------------------------------------------------------------

-- FUBAR Stuff -----------------------------------------------------------------------------
LunaUF.name = "LunaUnitFrames"
LunaUF.hasNoColor = true
LunaUF.hasIcon = "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\icon"
LunaUF.defaultMinimapPosition = 180
LunaUF.independentProfile = true
LunaUF.cannotDetachTooltip = true
LunaUF.hideWithoutStandby = true

function LunaUF:OnClick()
	if IsControlKeyDown() then
		if LunaUF.db.profile.locked then
			LunaUF:SystemMessage(L["Entering config mode."])
			LunaUF.db.profile.locked = false
		else
			LunaUF:SystemMessage(L["Exiting config mode."])
			LunaUF.db.profile.locked = true
		end
		LunaUF:LoadUnits()
	else
		if LunaOptionsFrame:IsShown() then
			LunaOptionsFrame:Hide()
		else
			LunaOptionsFrame:Show()
		end
	end
end
--------------------------------------------------------------------------------------------

--Constant Values --------------------------------------------------------------------------
LunaUF.constants = {
	backdrop = {
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 16,
		insets = {left = -1.5, right = -1.5, top = -1.5, bottom = -1.5},
	},
	icon = "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\icon",
	AnchorPoint = {
	["UP"] = "BOTTOM",
	["DOWN"] = "TOP",
	["RIGHT"] = "LEFT",
	["LEFT"] = "RIGHT",
	},
	RaidClassMapping = {
		[1] = "WARRIOR",
		[2] = "DRUID",
		[3] = LunaUF.AllianceCheck[LunaUF.playerRace] and "PALADIN" or "SHAMAN",
		[4] = "WARLOCK",
		[5] = "PRIEST",
		[6] = "MAGE",
		[7] = "ROGUE",
		[8] = "HUNTER",
		[9] = "PET",
	},
	CLASS_ICON_TCOORDS = {
		["WARRIOR"]     = {0.0234375, 0.2265625, 0.0234375, 0.2265625},
		["MAGE"]        = {0.2734375, 0.4765625, 0.0234375, 0.2265625},
		["ROGUE"]       = {0.5234375, 0.7265625, 0.0234375, 0.2265625},
		["DRUID"]       = {0.7734375, 0.97265625, 0.0234375, 0.2265625},
		["HUNTER"]      = {0.0234375, 0.2265625, 0.2734375, 0.4765625},
		["SHAMAN"]      = {0.2734375, 0.4765625, 0.2734375, 0.4765625},
		["PRIEST"]      = {0.5234375, 0.7265625, 0.2734375, 0.4765625},
		["WARLOCK"]     = {0.7734375, 0.97265625, 0.2734375, 0.4765625},
		["PALADIN"]     = {0.0234375, 0.2265625, 0.5234375, 0.7265625}
	},
	barorder = {
		horizontal = {
			[1] = "portrait",
			[2] = "healthBar",
			[3] = "powerBar",
			[4] = "castBar",
		},
		vertical = {
		},
	},
	specialbarorder = {
		["player"] = {
			horizontal = {
				[1] = "portrait",
				[2] = "healthBar",
				[3] = "powerBar",
				[4] = "castBar",
				[5] = "druidBar",
				[6] = "totemBar",
				[7] = "reckStacks",
				[8] = "xpBar",
			},
			vertical = {
			},
		},
		["pet"] = {
			horizontal = {
				[1] = "portrait",
				[2] = "healthBar",
				[3] = "powerBar",
				[4] = "castBar",
				[5] = "xpBar",
			},
			vertical = {
			},
		},
		["target"] = {
			horizontal = {
				[1] = "portrait",
				[2] = "healthBar",
				[3] = "powerBar",
				[4] = "castBar",
				[5] = "comboPoints",
			},
			vertical = {
			},
		},
		["raid"] = {
			horizontal = {
				[1] = "portrait",
				[2] = "castBar",
			},
			vertical = {
				[1] = "healthBar",
				[2] = "powerBar",
			},
		},
	},
}
--------------------------------------------------------------------------------------------

--Upon Loading
function LunaUF:OnInitialize()

	-- Slash Commands ----------------------------------------------------------------------
	LunaUF.cmdtable = {type = "group", handler = LunaUF, args = {
		[L["cmd_reset"]] = {
			type = "execute",
			name = L["cmd_reset"],
			desc = L["Resets your current settings."],
			func = function ()
					StaticPopup_Show ("RESET_LUNA")
				end,
		},
		[L["cmd_config"]] = {
			type = "execute",
			name = L["cmd_config"],
			desc = L["Toggle config mode on and off."],
			func = function ()
					if LunaUF.db.profile.locked then
						LunaUF:SystemMessage(L["Entering config mode."])
						LunaUF.db.profile.locked = false
					else
						LunaUF:SystemMessage(L["Exiting config mode."])
						LunaUF.db.profile.locked = true
					end
					LunaUF:LoadUnits()
				end,
		},
		[L["cmd_menu"]] = {
			type = "execute",
			name = L["cmd_menu"],
			desc = L["Show/hide the options menu."],
			func = function ()
					if LunaOptionsFrame:IsShown() then
						LunaOptionsFrame:Hide()
					else
						LunaOptionsFrame:Show()
					end
				end,
		},
	}}
	LunaUF:RegisterChatCommand({"/luna", "/luf", "/lunauf", "/lunaunitframes"}, LunaUF.cmdtable)
	----------------------------------------------------------------------------------------
	
	self:RegisterDefaults("profile", self.defaults.profile)
	self:InitBarorder()
	self:HideBlizzard()
	self:LoadUnits()
	self:CreateOptionsMenu()
	self:LoadOptions()
	LunaUF:SystemMessage(L["Loaded. The ride never ends!"])
	if not MobHealth3 and MobHealthFrame then
		LunaUF:SystemMessage(L["Mobhealth2/Mobinfo2 found. Please consider MobHealth3 for a better experience."])
	end
end

--System Message Output --------------------------------------------------------------------
function LunaUF:SystemMessage(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFF2150C2LunaUnitFrames|cFFFFFFFF: "..msg)
end
--------------------------------------------------------------------------------------------

--On Profile changed------------------------------------------------------------------------
function LunaUF:OnProfileEnable()
	self:InitBarorder()
	self:HideBlizzard()
	self:LoadUnits()
	self:LoadOptions()
end
--------------------------------------------------------------------------------------------

--Register Module --------------------------------------------------------------------------
function LunaUF:RegisterModule(module, key, name, isBar, class)
	self.modules[key] = module

	module.moduleKey = key
	module.moduleHasBar = isBar
	module.moduleName = name
	module.moduleClass = class
	
end
--------------------------------------------------------------------------------------------

--Hiding the Blizzard stuff ----------------------------------------------------------------
function LunaUF:HideBlizzard()
	-- Castbar
	local CastingBarFrame = getglobal("CastingBarFrame")
	if self.db.profile.blizzard.castbar then
		if CastingBarFrame.OldShow then
			CastingBarFrame.Show = CastingBarFrame.OldShow
		end
		if CastingBarFrame.OldHide then
			CastingBarFrame.Hide = CastingBarFrame.OldHide
		end
		if CastingBarFrame.OldIsShown then
			CastingBarFrame.IsShown = CastingBarFrame.OldIsShown
		end
		if CastingBarFrame.OldIsVisible then
			CastingBarFrame.IsVisible = CastingBarFrame.OldIsVisible
		end
		if CastingBarFrame.LUAFShown then
			CastingBarFrame.LUAFShown = nil
			CastingBarFrame:Show()
		end
	else
		CastingBarFrame.OldShow = CastingBarFrame.Show
		CastingBarFrame.OldHide = CastingBarFrame.Hide
		CastingBarFrame.OldIsShown = CastingBarFrame.IsShown
		CastingBarFrame.OldIsVisible = CastingBarFrame.IsVisible
		CastingBarFrame.Show = function(this)
				this.LUAFShown = true
			end
		CastingBarFrame.Hide = function(this)
				this.LUAFShown = nil
			end
		CastingBarFrame.IsShown = function(this)
				return this.LUAFShown
			end
		CastingBarFrame.IsVisible = function(this)
				return this.LUAFShown and this:GetParent():IsVisible()
			end
	end
	--Buffs
	if self.db.profile.blizzard.buffs then
		BuffFrame:Show()
	else
		BuffFrame:Hide()
	end
	--Weapon Enchants
	if self.db.profile.blizzard.weaponbuffs then
		TemporaryEnchantFrame:Show()
	else
		TemporaryEnchantFrame:Hide()
	end
	--Player
	if self.db.profile.blizzard.player then
		PlayerFrame:RegisterEvent("UNIT_LEVEL")
		PlayerFrame:RegisterEvent("UNIT_COMBAT")
		PlayerFrame:RegisterEvent("UNIT_FACTION")
		PlayerFrame:RegisterEvent("UNIT_MAXMANA")
		PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		PlayerFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
		PlayerFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
		PlayerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		PlayerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		PlayerFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
		PlayerFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
		PlayerFrame:RegisterEvent("PARTY_LEADER_CHANGED")
		PlayerFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
		PlayerFrame:RegisterEvent("RAID_ROSTER_UPDATE")
		PlayerFrame:RegisterEvent("PLAYTIME_CHANGED")
		PlayerFrame:Show()
--		PlayerFrame_Update()
		UnitFrameHealthBar_Update(PlayerFrame.healthhar, "player")
		UnitFrameManaBar_Update(PlayerFrame.manabar, "player")
	else
		PlayerFrame:UnregisterAllEvents()
		PlayerFrame:Hide()
	end
	--Pet
	if self.db.profile.blizzard.pet then
		PetFrame:RegisterEvent("UNIT_PET");
		PetFrame:RegisterEvent("UNIT_COMBAT");
		PetFrame:RegisterEvent("UNIT_AURA");
		PetFrame:RegisterEvent("PET_ATTACK_START");
		PetFrame:RegisterEvent("PET_ATTACK_STOP");
		PetFrame:RegisterEvent("UNIT_HAPPINESS");
--		PetFrame_Update()
	else
		PetFrame:UnregisterAllEvents()
		PetFrame:Hide()
	end
	--Target
	ClearTarget()
	if self.db.profile.blizzard.target then
		TargetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
		TargetFrame:RegisterEvent("UNIT_HEALTH")
		TargetFrame:RegisterEvent("UNIT_LEVEL")
		TargetFrame:RegisterEvent("UNIT_FACTION")
		TargetFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
		TargetFrame:RegisterEvent("UNIT_AURA")
		TargetFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
		TargetFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
		TargetFrame:RegisterEvent("RAID_TARGET_UPDATE")
		ComboFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
		ComboFrame:RegisterEvent("PLAYER_COMBO_POINTS")
		ComboPointsFrame_OnEvent()
	else
		TargetFrame:UnregisterAllEvents()
		TargetFrame:Hide()
		ComboFrame:UnregisterAllEvents()
		ComboFrame:Hide()
	end
	--Party
	if self.db.profile.blizzard.party then
		if self.RaidOptionsFrame_UpdatePartyFrames then
			RaidOptionsFrame_UpdatePartyFrames = self.RaidOptionsFrame_UpdatePartyFrames
		end
		for i=1,4 do
			local frame = getglobal("PartyMemberFrame"..i)
			frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
			frame:RegisterEvent("PARTY_LEADER_CHANGED")
			frame:RegisterEvent("PARTY_MEMBER_ENABLE")
			frame:RegisterEvent("PARTY_MEMBER_DISABLE")
			frame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
			frame:RegisterEvent("UNIT_PVP_UPDATE")
			frame:RegisterEvent("UNIT_AURA")
			frame:RegisterEvent("UNIT_PET")
			frame:RegisterEvent("VARIABLES_LOADED")
			frame:RegisterEvent("UNIT_NAME_UPDATE")
			frame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
			frame:RegisterEvent("UNIT_DISPLAYPOWER")
		end
		UnitFrame_OnEvent("PARTY_MEMBERS_CHANGED")
		ShowPartyFrame()
	else
		self.RaidOptionsFrame_UpdatePartyFrames = RaidOptionsFrame_UpdatePartyFrames
		RaidOptionsFrame_UpdatePartyFrames = function () end
		for i=1,4 do
			local frame = getglobal("PartyMemberFrame"..i)
			frame:UnregisterAllEvents()
			frame:Hide()
		end
	end
end

--------------------------------------------------------------------------------------------

function LunaUF:InitBarorder()
	for key,unitGroup in pairs(LunaUF.db.profile.units) do
		if not unitGroup.barorder then
			if LunaUF.constants.specialbarorder[key] then
				unitGroup.barorder = deepcopy(LunaUF.constants.specialbarorder[key])
			else
				unitGroup.barorder = deepcopy(LunaUF.constants.barorder)
			end
		elseif key == "player" and (getn(unitGroup.barorder.horizontal) + getn(unitGroup.barorder.vertical)) < 8 then
			tinsert(unitGroup.barorder.horizontal, "reckStacks")
		end
	end
end

--------------------------------------------------------------------------------------------

function LunaUF:LoadUnits()
	for _, type in pairs(self.unitList) do
		self.Units:InitializeFrame(type)
	end
end
