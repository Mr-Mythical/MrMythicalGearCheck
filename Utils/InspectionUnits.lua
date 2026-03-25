--[[
InspectionUnits.lua - Mr. Mythical Gear Check unit lookup helpers

Purpose: Group member lookup and inspection unit validation helpers.
Dependencies: None
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.InspectionUnits = MrMythicalGearCheck.InspectionUnits or {}

local InspectionUnits = MrMythicalGearCheck.InspectionUnits

--- Finds the unit ID for a given player name
--- @param playerName string Name of the player to find
--- @return string|nil Unit ID if found, nil otherwise
function InspectionUnits:FindUnitByName(playerName)
    if not playerName then return nil end

    if UnitName("player") == playerName then
        return "player"
    end

    for i = 1, GetNumSubgroupMembers() do
        local unit = "party" .. i
        if UnitName(unit) == playerName then
            return unit
        end
    end

    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        if UnitName(unit) == playerName then
            return unit
        end
    end

    if UnitName("target") == playerName then
        return "target"
    end

    if UnitName("mouseover") == playerName then
        return "mouseover"
    end

    return nil
end

--- Gets all current group members
--- @return table Array of unit IDs
function InspectionUnits:GetGroupMembers()
    local members = {}

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitExists(unit) then
                table.insert(members, unit)
            end
        end
    elseif IsInGroup() then
        table.insert(members, "player")
        for i = 1, GetNumSubgroupMembers() do
            local unit = "party" .. i
            if UnitExists(unit) then
                table.insert(members, unit)
            end
        end
    else
        return {}
    end

    return members
end

--- Validates if a unit is suitable for inspection
--- @param unit string Unit ID to validate
--- @param requireCanInspect boolean Whether to also check CanInspect (default: false)
--- @return boolean True if unit is valid for inspection
--- @return string|nil Error message if invalid
function InspectionUnits:IsValidInspectionUnit(unit, requireCanInspect)
    if not unit then
        return false, "Unit is nil"
    end

    if not UnitExists(unit) then
        return false, "Unit does not exist"
    end

    if not UnitIsPlayer(unit) then
        return false, "Unit is not a player"
    end

    if requireCanInspect and not CanInspect(unit) then
        return false, "Unit cannot be inspected"
    end

    return true
end
