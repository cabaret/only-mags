-- OnlyMags

local addonName = ...

OnlyMagsDB = OnlyMagsDB or {}

local defaults = {
	petName = "Mags",
	enabled = true,
}

local C_PetJournal = C_PetJournal
local IsStealthed = IsStealthed
local InCombatLockdown = InCombatLockdown
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local function SummonPet()
	if not OnlyMagsDB.enabled then
		return
	end

	local petName = OnlyMagsDB.petName
	if not petName or petName == "" then
		return
	end

	if InCombatLockdown() or UnitIsDeadOrGhost("player") or IsStealthed() then
		return
	end

	local _, petGUID = C_PetJournal.FindPetIDByName(petName)

	if not petGUID then
		return
	end

	if C_PetJournal.GetSummonedPetGUID() ~= petGUID then
		C_PetJournal.SummonPetByGUID(petGUID)
	end
end

local magsFrame = CreateFrame("Frame")
magsFrame:RegisterEvent("ADDON_LOADED")
magsFrame:RegisterEvent("PLAYER_STARTED_MOVING")
magsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

magsFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == addonName then
		for k, v in pairs(defaults) do
			if OnlyMagsDB[k] == nil then
				OnlyMagsDB[k] = v
			end
		end
		print("|cffff69b4OnlyMags|r loaded.")
	elseif event == "PLAYER_STARTED_MOVING" then
		SummonPet()
	elseif event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(2, SummonPet)
	end
end)

SLASH_ONLYMAGS1 = "/mags"

SlashCmdList["ONLYMAGS"] = function(msg)
	local cmd = msg:lower():trim()

	if cmd == "enable" then
		OnlyMagsDB.enabled = true
		print("|cffff69b4OnlyMags|r: Enabled")
		SummonPet()
	elseif cmd == "disable" then
		OnlyMagsDB.enabled = false
		print("|cffff69b4OnlyMags|r: Disabled")
		C_PetJournal.SummonPetByGUID(C_PetJournal.GetSummonedPetGUID())
	else
		print("|cffff69b4OnlyMags|r: /mags enable | disable")
	end
end

local function SetPetAsPermanent(displayName)
	if not displayName then
		return
	end
	OnlyMagsDB.petName = displayName
	print("|cffff69b4OnlyMags|r: Pet set to |cfffff000" .. displayName .. "|r")
end

local function ClearPermanentPet()
	OnlyMagsDB.petName = ""
	print("|cffff69b4OnlyMags|r: Cleared.")
end

local function SetupPetJournalMenu()
	if not (Menu and Menu.ModifyMenu) then
		return
	end

	Menu.ModifyMenu("MENU_PET_COLLECTION_PET", function(ownerRegion, rootDescription, contextData)
		local petGUID = ownerRegion and ownerRegion.petID
		if not petGUID then
			return
		end

		local _, customName, _, _, _, _, _, name = C_PetJournal.GetPetInfoByPetID(petGUID)
		local displayName = customName or name
		if not displayName then
			return
		end

		rootDescription:CreateDivider()

		if OnlyMagsDB.petName == displayName then
			rootDescription:CreateButton("Clear permanent pet", function()
				ClearPermanentPet()
				C_PetJournal.SummonPetByGUID(C_PetJournal.GetSummonedPetGUID())
			end)
		else
			rootDescription:CreateButton("Set permanent pet", function()
				SetPetAsPermanent(displayName)
				C_PetJournal.SummonPetByGUID(petGUID)
			end)
		end
	end)
end

local menuFrame = CreateFrame("Frame")
menuFrame:RegisterEvent("ADDON_LOADED")
menuFrame:SetScript("OnEvent", function(self, _, addon)
	if addon == "Blizzard_Collections" then
		C_Timer.After(0.1, SetupPetJournalMenu)
		self:UnregisterEvent("ADDON_LOADED")
	end
end)

if C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
	C_Timer.After(0.1, SetupPetJournalMenu)
end

local function ApplyCDMOverrides()
	if CooldownViewerConstants then
		CooldownViewerConstants.ITEM_AURA_COLOR = CreateColor(0.3, 0.7, 0.2, 0.9)
	end
end

hooksecurefunc("CooldownFrame_Set", function(cooldown, _, _, _, drawEdge)
	if drawEdge and cooldown:GetParent() then
		local parent = cooldown:GetParent()
		if parent.GetSpellID and parent.GetBaseSpellID then
			cooldown:SetEdgeTexture("Interface\\AddOns\\OnlyMags\\edge-green")
		end
	end
end)

if C_AddOns.IsAddOnLoaded("Blizzard_CooldownViewer") then
	ApplyCDMOverrides()
else
	EventUtil.ContinueOnAddOnLoaded("Blizzard_CooldownViewer", ApplyCDMOverrides)
end
