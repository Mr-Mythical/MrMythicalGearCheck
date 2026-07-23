--[[
InspectionState.lua - Mr. Mythical Gear Check inspection state helpers

Purpose: Persistent scan state and inspection status reporting.
Dependencies: GearUtils, GearData, InspectionUnits
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.InspectionState = MrMythicalGearCheck.InspectionState or {}

local InspectionState = MrMythicalGearCheck.InspectionState

InspectionState.groupScanState = InspectionState.groupScanState or {}

local function getDependency(name)
    return (_G.MrMythicalGearCheck and _G.MrMythicalGearCheck[name]) or MrMythicalGearCheck[name]
end

local function getUnitDisplayName(unit)
    local InspectionUnits = getDependency("InspectionUnits")
    if InspectionUnits and InspectionUnits.GetUnitFullName then
        return InspectionUnits:GetUnitFullName(unit) or UnitName(unit)
    end
    return UnitName(unit)
end

local function findScanDataForName(playerName)
    local scanData = InspectionState.groupScanState[playerName]
    if scanData then
        return scanData, playerName
    end

    local InspectionUnits = getDependency("InspectionUnits")
    if not InspectionUnits or not InspectionUnits.NamesMatch then
        return nil, playerName
    end

    for storedName, storedData in pairs(InspectionState.groupScanState) do
        if InspectionUnits:NamesMatch(storedName, playerName) then
            return storedData, storedName
        end
    end

    return nil, playerName
end

--- Creates a brief summary for an inspected player
--- @param unit string Unit ID
--- @param playerName string Player name
--- @param gearInfo table|nil Optional cached gear info
--- @return string Brief summary of player's gear status
--- @return table|nil Detail payload with gearDetails / summaryLines / totalIssues
function InspectionState:CreatePlayerSummary(unit, playerName, gearInfo)
    local GearUtils = getDependency("GearUtils")
    if not GearUtils then
        return "Inspection completed", nil
    end

    local analysis = GearUtils:AnalyzeGear(unit, "detailed")
    if not analysis then
        return "Inspection completed", nil
    end

    local itemLevel = 0
    local itemCount = 0
    local gearData = getDependency("GearData")
    if gearData and gearData.SLOT_NAMES then
        for slotId, _ in pairs(gearData.SLOT_NAMES) do
            local itemLink = GetInventoryItemLink(unit, slotId)
            if itemLink then
                local itemLvl = C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(itemLink)
                if itemLvl and itemLvl > 0 then
                    itemLevel = itemLevel + itemLvl
                    itemCount = itemCount + 1
                end
            end
        end
    end
    local avgItemLevel = itemCount > 0 and math.floor(itemLevel / itemCount) or 0

    local details = {
        gearDetails = analysis.gearDetails or {},
        summaryLines = analysis.summaryLines or {},
        totalIssues = analysis.totalIssues or 0,
        avgItemLevel = avgItemLevel
    }

    if analysis.totalIssues == 0 then
        return string.format("iLvl %d - |cff00ff00PERFECT GEAR|r", avgItemLevel), details
    end

    local issueTypes = {}
    if analysis.emptySlots > 0 then
        table.insert(issueTypes, analysis.emptySlots .. " empty slots")
    end
    if analysis.unenchantedItems > 0 then
        table.insert(issueTypes, analysis.unenchantedItems .. " missing enchants")
    end
    if analysis.lowRankEnchants > 0 then
        table.insert(issueTypes, analysis.lowRankEnchants .. " enchant issues")
    end
    if analysis.emptyGems > 0 then
        table.insert(issueTypes, analysis.emptyGems .. " empty gems")
    end
    if analysis.lowRankGems > 0 then
        table.insert(issueTypes, analysis.lowRankGems .. " gem issues")
    end
    if analysis.suboptimalGems and analysis.suboptimalGems > 0 then
        table.insert(issueTypes, analysis.suboptimalGems .. " suboptimal gems")
    end
    if analysis.hasLowDurability then
        table.insert(issueTypes, "needs repair")
    end

    local issueText = table.concat(issueTypes, ", ")
    return string.format("iLvl %d - |cffff8000%d ISSUES|r (%s)", avgItemLevel, analysis.totalIssues, issueText), details
end

--- Gets list of failed inspections (members that need scanning)
--- @return table List of members that haven't been successfully scanned
function InspectionState:GetFailedInspectionsList()
    local failedList = {}
    local InspectionUnits = getDependency("InspectionUnits")
    local groupMembers = InspectionUnits and InspectionUnits:GetGroupMembers() or {}

    for _, unit in ipairs(groupMembers) do
        local playerName = getUnitDisplayName(unit)
        if playerName then
            local scanState = findScanDataForName(playerName)
            if not scanState or scanState.hasData ~= true then
                table.insert(failedList, {
                    name = playerName,
                    unit = unit,
                    reason = scanState and scanState.reason or "Not scanned",
                    retryCount = scanState and scanState.retryCount or 0
                })
            end
        end
    end

    return failedList
end

--- Clears scan state for current group members (for fresh scan)
function InspectionState:ClearGroupScanState()
    local InspectionUnits = getDependency("InspectionUnits")
    local groupMembers = InspectionUnits and InspectionUnits:GetGroupMembers() or {}
    for _, unit in ipairs(groupMembers) do
        local playerName = getUnitDisplayName(unit)
        if playerName then
            local _, storedKey = findScanDataForName(playerName)
            if storedKey then
                self.groupScanState[storedKey] = nil
            end
            self.groupScanState[playerName] = nil
        end
    end
end

--- Gets current inspection status for UI display
--- @param scanQueue table|nil Current scan queue
--- @return table Current inspection status
function InspectionState:GetInspectionStatus(scanQueue)
    local InspectionUnits = getDependency("InspectionUnits")
    local groupMembers = InspectionUnits and InspectionUnits:GetGroupMembers() or {}
    local memberReports = {}
    local failedCount = 0

    for _, unit in ipairs(groupMembers) do
        local playerName = getUnitDisplayName(unit)
        if playerName then
            local scanData = findScanDataForName(playerName)
            if scanData and scanData.hasData then
                table.insert(memberReports, {
                    name = playerName,
                    unit = unit,
                    summary = scanData.summary,
                    details = scanData.details,
                    hasData = true,
                    reason = scanData.reason
                })
            else
                local summary = "Not scanned"
                local reason = nil
                if scanData and scanData.summary then
                    summary = scanData.summary
                end
                if scanData and scanData.reason then
                    reason = scanData.reason
                    if not scanData.summary then
                        summary = "Failed - " .. reason
                    end
                end
                table.insert(memberReports, {
                    name = playerName,
                    unit = unit,
                    summary = summary,
                    details = scanData and scanData.details or nil,
                    hasData = false,
                    reason = reason
                })
                failedCount = failedCount + 1
            end
        end
    end

    return {
        hasResults = #memberReports > 0,
        totalMembers = #groupMembers,
        inspectedMembers = #memberReports - failedCount,
        failedCount = failedCount,
        canRescan = failedCount > 0 and not InCombatLockdown(),
        memberReports = memberReports,
        failedInspections = self:GetFailedInspectionsList(),
        queuedCount = scanQueue and #scanQueue or 0,
        scanQueue = scanQueue or {}
    }
end
