--[[
GearData.lua - Mr. Mythical Gear Check Gear Database

Purpose: Basic gear slot information for validation
Dependencies: None
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.GearData = {}

local GearData = MrMythicalGearCheck.GearData

--- Equipment slot names for display
GearData.SLOT_NAMES = {
    [1] = "Head",
    [2] = "Neck", 
    [3] = "Shoulder",
    [5] = "Chest",
    [6] = "Belt",
    [7] = "Legs",
    [8] = "Feet",
    [9] = "Wrist",
    [10] = "Hands",
    [11] = "Ring 1",
    [12] = "Ring 2", 
    [13] = "Trinket 1",
    [14] = "Trinket 2",
    [15] = "Back",
    [16] = "Main Hand",
    [17] = "Off Hand"
}

--- Gets slot name for display
--- Gets slot name for display
--- @param slotId number Equipment slot ID
--- @return string Slot name
function GearData:GetSlotName(slotId)
    return self.SLOT_NAMES[slotId] or ("Slot " .. tostring(slotId))
end

-- Ensure global access
_G.MrMythicalGearCheck = MrMythicalGearCheck
