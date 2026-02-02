-- OnlyMags

local addonName = ...

OnlyMagsDB = OnlyMagsDB or {}

local defaults = {
	petName = "Mags",
	enabled = true,
}

-- Localize frequently used API functions
local C_PetJournal = C_PetJournal
local C_Timer = C_Timer
local C_AddOns = C_AddOns

-- Cache the pet GUID to avoid repeated name lookups
local cachedPetGUID = nil
local cachedPetName = nil

local function GetPetGUID()
	local petName = OnlyMagsDB.petName
	if not petName or petName == "" then
		cachedPetGUID = nil
		cachedPetName = nil
		return nil
	end

	-- Only look up if the name changed or we don't have a cached GUID
	if petName ~= cachedPetName then
		local _, petGUID = C_PetJournal.FindPetIDByName(petName)
		cachedPetGUID = petGUID
		cachedPetName = petName
	end

	return cachedPetGUID
end

local function SummonPet()
	if not OnlyMagsDB.enabled then
		return
	end

	local petGUID = GetPetGUID()
	if not petGUID then
		return
	end

	-- Check if already summoned (Blizzard uses this pattern, not IsCurrentlySummoned)
	if C_PetJournal.GetSummonedPetGUID() == petGUID then
		return
	end

	-- Use PetIsSummonable which handles combat, death, stealth, and other restrictions
	if not C_PetJournal.PetIsSummonable(petGUID) then
		return
	end

	C_PetJournal.SummonPetByGUID(petGUID)
end

local function DismissCurrentPet()
	local summonedPetGUID = C_PetJournal.GetSummonedPetGUID()
	if summonedPetGUID then
		C_PetJournal.DismissSummonedPet(summonedPetGUID)
	end
end

local function SetPetAsPermanent(displayName, petGUID)
	if not displayName then
		return
	end
	OnlyMagsDB.petName = displayName
	-- Update cache immediately
	cachedPetName = displayName
	cachedPetGUID = petGUID
	print("|cffff69b4OnlyMags|r: Pet set to |cfffff000" .. displayName .. "|r")
end

local function ClearPermanentPet()
	OnlyMagsDB.petName = ""
	cachedPetGUID = nil
	cachedPetName = nil
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

		-- Use GetPetInfoTableByPetID for cleaner access to pet info
		local petInfo = C_PetJournal.GetPetInfoTableByPetID(petGUID)
		if not petInfo then
			return
		end

		local displayName = petInfo.customName or petInfo.name
		if not displayName then
			return
		end

		rootDescription:CreateDivider()

		if OnlyMagsDB.petName == displayName then
			rootDescription:CreateButton("Clear permanent pet", function()
				ClearPermanentPet()
				DismissCurrentPet()
			end)
		else
			rootDescription:CreateButton("Set permanent pet", function()
				SetPetAsPermanent(displayName, petGUID)
				C_PetJournal.SummonPetByGUID(petGUID)
			end)
		end
	end)
end

-- Single frame for all events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_STARTED_MOVING")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == addonName then
			for k, v in pairs(defaults) do
				if OnlyMagsDB[k] == nil then
					OnlyMagsDB[k] = v
				end
			end
			print("|cffff69b4OnlyMags|r loaded.")
		elseif arg1 == "Blizzard_Collections" then
			C_Timer.After(0.1, SetupPetJournalMenu)
		end
	elseif event == "PLAYER_STARTED_MOVING" then
		SummonPet()
	elseif event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(2, SummonPet)
	end
end)

-- Setup menu if Blizzard_Collections is already loaded
if C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
	C_Timer.After(0.1, SetupPetJournalMenu)
end

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
		DismissCurrentPet()
	else
		print("|cffff69b4OnlyMags|r: /mags enable | disable")
	end
end
