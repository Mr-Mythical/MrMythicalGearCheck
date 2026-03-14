--[[
Core.lua - MrMythicalGearCheck core bootstrap

Purpose: Initializes core addon state and startup event handling.
Dependencies: Shared addon table and Options module (if loaded).
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

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MrMythicalGearCheck" then
            if MrMythicalGearCheck.Options then
                MrMythicalGearCheck.Options.initializeSettings()
            end
        end
    end
end)

_G.MrMythicalGearCheck = MrMythicalGearCheck
