--[[
InspectionUnits.lua - Mr. Mythical Gear Check unit lookup helpers

Purpose: Group member lookup and inspection unit validation helpers.
Dependencies: None
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.InspectionUnits = MrMythicalGearCheck.InspectionUnits or {}

local InspectionUnits = MrMythicalGearCheck.InspectionUnits

local function getPlayerRealmName()
    if GetNormalizedRealmName then
        local realm = GetNormalizedRealmName()
        if realm and realm ~= "" then
            return realm
        end
    end

    local realm = GetRealmName and GetRealmName() or nil
    if realm and realm ~= "" then
        return realm:gsub("%s+", "")
    end

    return nil
end

--- Builds a stable Name-Realm key for a unit (same-realm players get the local realm appended)
--- @param unit string Unit ID
--- @return string|nil Full player name key
function InspectionUnits:GetUnitFullName(unit)
    if not unit or not UnitExists(unit) then
        return nil
    end

    local name, realm = UnitName(unit)
    if not name or name == "" then
        return nil
    end

    if realm and realm ~= "" then
        return name .. "-" .. realm
    end

    local playerRealm = getPlayerRealmName()
    if playerRealm then
        return name .. "-" .. playerRealm
    end

    return name
end

--- Normalizes a player name for comparison (lowercase, strip spaces in realm)
--- @param playerName string
--- @return string
function InspectionUnits:NormalizePlayerName(playerName)
    if not playerName or playerName == "" then
        return ""
    end

    local normalized = tostring(playerName):gsub("%s+", "")
    return string.lower(normalized)
end

--- Returns true when two name keys refer to the same player
--- @param nameA string|nil
--- @param nameB string|nil
--- @return boolean
function InspectionUnits:NamesMatch(nameA, nameB)
    if not nameA or not nameB then
        return false
    end

    if nameA == nameB then
        return true
    end

    local normA = self:NormalizePlayerName(nameA)
    local normB = self:NormalizePlayerName(nameB)
    if normA ~= "" and normA == normB then
        return true
    end

    if Ambiguate then
        local shortA = Ambiguate(nameA, "short")
        local shortB = Ambiguate(nameB, "short")
        if shortA and shortB and shortA == shortB then
            -- Only treat short-name matches as equal when neither side includes a conflicting realm.
            local realmA = nameA:match("%-(.+)$")
            local realmB = nameB:match("%-(.+)$")
            if not realmA or not realmB or self:NormalizePlayerName(realmA) == self:NormalizePlayerName(realmB) then
                return true
            end
        end
    end

    return false
end

--- Finds the unit ID for a given player name (supports Name or Name-Realm)
--- @param playerName string Name of the player to find
--- @return string|nil Unit ID if found, nil otherwise
function InspectionUnits:FindUnitByName(playerName)
    if not playerName then
        return nil
    end

    local members = self:GetGroupMembers()
    for _, unit in ipairs(members) do
        local fullName = self:GetUnitFullName(unit)
        local shortName = UnitName(unit)
        if self:NamesMatch(fullName, playerName) or self:NamesMatch(shortName, playerName) then
            return unit
        end
    end

    if UnitExists("target") and UnitIsPlayer("target") then
        local fullName = self:GetUnitFullName("target")
        if self:NamesMatch(fullName, playerName) or self:NamesMatch(UnitName("target"), playerName) then
            return "target"
        end
    end

    if UnitExists("mouseover") and UnitIsPlayer("mouseover") then
        local fullName = self:GetUnitFullName("mouseover")
        if self:NamesMatch(fullName, playerName) or self:NamesMatch(UnitName("mouseover"), playerName) then
            return "mouseover"
        end
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

--- Describes why a unit cannot be inspected right now.
--- Returns nil when inspection should still be attempted (transient CanInspect/combat states).
--- @param unit string Unit ID
--- @return string|nil Failure reason, or nil if inspectable / worth attempting
function InspectionUnits:GetInspectFailureReason(unit)
    if not unit then
        return "Unit is nil"
    end

    -- Local player never needs a remote inspect request.
    if unit == "player" then
        return nil
    end

    if not UnitExists(unit) then
        return "Player left the group"
    end

    if not UnitIsPlayer(unit) then
        return "Unit is not a player"
    end

    -- Caller already pauses on InCombatLockdown; do not hard-fail members who are fighting.
    -- Range/CanInspect can also be briefly false — only hard-fail clear out-of-range cases.
    if not CanInspect(unit) then
        if CheckInteractDistance and not CheckInteractDistance(unit, 1) then
            return "Out of inspect range"
        end
        -- Transient CanInspect failure: still allow InspectUnit/NotifyInspect retries.
        return nil
    end

    return nil
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
        return false, "Player left the group"
    end

    if not UnitIsPlayer(unit) then
        return false, "Unit is not a player"
    end

    if requireCanInspect then
        local reason = self:GetInspectFailureReason(unit)
        if reason then
            return false, reason
        end
    end

    return true
end
