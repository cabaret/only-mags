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

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_STARTED_MOVING")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(_, event, arg1)
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
