--[[
Core.lua - Mr. Mythical Gear Check Core Logic

Purpose: Main functionality for gear validation and issue detection
Dependencies: All Data and Utils modules
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}

MrMythicalGearCheckDebug = false

--- Debug print function - only prints if debug is enabled
--- @param message string The debug message to print
local function debugPrint(message)
    if MrMythicalGearCheckDebug then
        print(message)
    end
end

MrMythicalGearCheck.DebugPrint = MrMythicalGearCheck.DebugPrint or debugPrint

--- Event handler for addon initialization
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MrMythicalGearCheck" then
            -- Delay the options initialization slightly to ensure Settings API is ready
            if MrMythicalGearCheck.Options then
                MrMythicalGearCheck.Options.initializeSettings()
            end
        end
    end
end)

_G.MrMythicalGearCheck = MrMythicalGearCheck
