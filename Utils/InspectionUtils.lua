--[[
InspectionUtils.lua - Mr. Mythical Gear Optimizer Inspection Utilities

Purpose: Utilities for group inspection and gear checking
Dependencies: GearUtils, ConfigData
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.InspectionUtils = {}

local InspectionUtils = MrMythicalGearCheck.InspectionUtils

--- Common inspect frame names used across multiple functions
local INSPECT_FRAME_NAMES = {
    "InspectFrame",
    "InspectFrameNew", 
    "Blizzard_InspectUI",
    "InspectPaperDollFrame"
}

--- Used for cooldown tracking between group scans
local lastInspectionTime = 0

--- Persistent group scan state - stores scan data for each group member
--- Key: playerName, Value: scan data or nil if not scanned/failed
InspectionUtils.groupScanState = {}

--- Scan queue for players to inspect
local scanQueue = {}

local groupInspectionCallback
local uiProgressCallback

--- Adds a player to the scan queue
--- @param playerName string Name of the player to add
--- @return boolean True if added successfully
function InspectionUtils:AddPlayerToScanQueue(playerName)
    if not playerName or playerName == "" then
        return false
    end
    
    -- Check if already in queue
    for _, queued in ipairs(scanQueue) do
        if queued.name == playerName then
            return false -- Already in queue
        end
    end
    
    table.insert(scanQueue, {
        name = playerName,
        addedTime = GetTime()
    })

    return true
end

--- Adds all current group members to the scan queue
--- @return number Number of players added
function InspectionUtils:AddGroupToScanQueue()
    local added = 0
    local groupMembers = self:GetGroupMembers()
    
    for _, unit in ipairs(groupMembers) do
        local name = UnitName(unit)
        if name and self:AddPlayerToScanQueue(name) then
            added = added + 1
        end
    end
    
    return added
end

--- Clears the scan queue
function InspectionUtils:ClearScanQueue()
    scanQueue = {}
end

--- Removes a player from the scan queue
--- @param playerName string Name of the player to remove
--- @return boolean True if removed successfully
function InspectionUtils:RemovePlayerFromScanQueue(playerName)
    for i, queued in ipairs(scanQueue) do
        if queued.name == playerName then
            table.remove(scanQueue, i)
            return true
        end
    end
    return false
end

--- Scans all players in the scan queue
--- @param callback function Optional callback when all scans complete
--- @param progressCallback function Optional callback for progress updates
--- @param clearPrevious boolean Optional - if true, clears previous results before scanning
function InspectionUtils:ScanQueuedPlayers(callback, progressCallback, clearPrevious)
    if #scanQueue == 0 then
        if callback then callback({}) end
        return
    end
    
    -- Process scan queue
    
    -- Check if we're in combat
    if InCombatLockdown() then
        if callback then callback({}) end
        return
    end
    
    -- Check cooldown
    local currentTime = GetTime()
    local cooldownTime = 5.0
    if lastInspectionTime and (currentTime - lastInspectionTime) < cooldownTime then
        local remainingTime = cooldownTime - (currentTime - lastInspectionTime)
        if callback then callback({}) end
        return
    end
    lastInspectionTime = currentTime
    
    -- Clear previous results if requested (for fresh scan)
    if clearPrevious then
        self:ClearGroupScanState()
    end
    
    -- Store callbacks
    groupInspectionCallback = callback
    uiProgressCallback = progressCallback
    
    -- Create inspection queue from members that need scanning
    self.inspectionQueue = {}
    for i, queued in ipairs(scanQueue) do
        local playerName = queued.name
        -- Only add to queue if they don't have scan data
        if not self.groupScanState[playerName] then
            table.insert(self.inspectionQueue, {
                name = playerName,
                index = i
            })
        end
    end
    
    -- Start scanning
    self:StartNextInspection(false)
end

--- Inspects all group members' gear
--- @param callback function Optional callback when all inspections complete
--- @param progressCallback function Optional callback for progress updates
--- @param clearPrevious boolean Optional - if true, clears previous results before scanning
function InspectionUtils:InspectGroup(callback, progressCallback, clearPrevious)
    -- Add all group members to scan queue
    self:ClearScanQueue()
    local added = self:AddGroupToScanQueue()
    
    if added == 0 then
        if callback then callback({}) end
        return
    end
    
    -- Now scan the queued players
    self:ScanQueuedPlayers(callback, progressCallback, clearPrevious)
end

--- Rescans failed inspections
--- @param callback function Callback to execute when rescan completes
--- @param progressCallback function Optional callback for progress updates
function InspectionUtils:RescanFailedInspections(callback, progressCallback)
    -- Clear existing scan queue
    self:ClearScanQueue()
    
    -- Get the current inspection status to find failed inspections
    local currentStatus = self:GetInspectionStatus()
    if not currentStatus or not currentStatus.failedInspections or #currentStatus.failedInspections == 0 then
        if callback then 
            callback(currentStatus or {
                memberReports = {},
                failedCount = 0,
                inspectedMembers = 0,
                totalMembers = 0,
                hasResults = false
            }) 
        end
        return
    end
    
    -- Add failed inspections to the rescan queue
    self.rescanQueue = {}
    local index = 1
    for _, failedInspection in ipairs(currentStatus.failedInspections) do
        if failedInspection.name then
            local unit = self:FindUnitByName(failedInspection.name)
            if unit then
                table.insert(self.rescanQueue, {
                    unit = unit,
                    name = failedInspection.name,
                    index = index,
                    retryCount = (failedInspection.retryCount or 0) + 1
                })
                index = index + 1
            end
        end
    end
    
    if #self.rescanQueue == 0 then
        if callback then callback(currentStatus) end
        return
    end
    
    -- Start the rescan process
    groupInspectionCallback = callback
    uiProgressCallback = progressCallback
    self:StartNextInspection(true) -- true indicates this is a rescan
end

--- Finds the unit ID for a given player name
--- @param playerName string Name of the player to find
--- @return string|nil Unit ID if found, nil otherwise
function InspectionUtils:FindUnitByName(playerName)
    if not playerName then return nil end
    
    -- Check if it's the player themselves
    if UnitName("player") == playerName then
        return "player"
    end
    
    -- Check party members
    for i = 1, GetNumSubgroupMembers() do
        local unit = "party" .. i
        if UnitName(unit) == playerName then
            return unit
        end
    end
    
    -- Check raid members
    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        if UnitName(unit) == playerName then
            return unit
        end
    end
    
    -- Check if it's a target or mouseover
    if UnitName("target") == playerName then
        return "target"
    end
    
    if UnitName("mouseover") == playerName then
        return "mouseover"
    end
    
    return nil
end

--- Starts inspection of the next unit in the queue (consolidated function for both inspection and rescan)
--- @param isRescan boolean Whether this is a rescan operation
function InspectionUtils:StartNextInspection(isRescan)
    local queue = isRescan and self.rescanQueue or self.inspectionQueue
    local failureHandler = isRescan and self.HandleRescanFailure or self.HandleInspectionFailure
    local progressType = isRescan and "rescan_progress" or "progress"
    local messagePrefix = isRescan and "Rescanning" or "Analyzing"
    local completionType = isRescan and "rescan_completed" or "completed"
    local completionMessage = isRescan and "Rescan complete!" or "Inspection complete!"

    if not queue or #queue == 0 then
        -- All inspections complete
        local successfulCount = 0
        local totalCount = 0

        -- Count successful scans from persistent state
        for playerName, scanData in pairs(self.groupScanState) do
            totalCount = totalCount + 1
            if scanData.hasData then
                successfulCount = successfulCount + 1
            end
        end

        local failedCount = totalCount - successfulCount
        local operationName = isRescan and "Rescan" or "Inspection"

        -- Clear any pending inspections and close inspect window
        self:ClearInspectionState()

        -- Final progress update
        self:SendProgressCallback({
            type = completionType,
            message = completionMessage,
            failedCount = failedCount,
            canRescan = failedCount > 0
        })

        -- Call the stored callback with results
        if groupInspectionCallback then
            groupInspectionCallback(self:GetInspectionStatus())
            groupInspectionCallback = nil  -- Clear it after use
            uiProgressCallback = nil
        end

        -- Clear the appropriate queue
        if isRescan then
            self.rescanQueue = nil
        else
            self.inspectionQueue = nil
        end

        -- Results are kept in memory for the session
        return
    end

    -- Get next player to inspect
    local nextItem = table.remove(queue, 1)
    local playerName = nextItem.name
    local index = nextItem.index

    -- Start inspection process

    -- Progress update
    if uiProgressCallback then
        local totalMembers = 0
        for _ in pairs(self.groupScanState) do
            totalMembers = totalMembers + 1
        end
        self:SendProgressCallback({
            type = progressType,
            current = index - 1,
            total = totalMembers,
            progress = math.floor(((index - 1) / totalMembers) * 100),
            message = messagePrefix .. " " .. playerName .. "..."
        })
    end

    -- Find the unit for this player name
    local unit = self:FindUnitByName(playerName)

    -- Set current inspection target
    self.currentInspectionUnit = unit
    self.currentInspectionName = playerName

    if not unit then
        failureHandler(self, "", playerName, "Unit not found", isRescan)
        return
    end

    -- Attempt to inspect the unit
    local isValid, errorMsg = self:IsValidInspectionUnit(unit, false)
    if isValid then
        local success = self:RequestInspection(unit)
        if not success then
            failureHandler(self, unit or "", playerName, "Failed to request inspection", isRescan)
        end
    else
        failureHandler(self, unit or "", playerName, errorMsg or "Unit validation failed", isRescan)
    end
end

--- Sends a progress callback if callback is registered
--- @param callbackData table The callback data to send
function InspectionUtils:SendProgressCallback(callbackData)
    if uiProgressCallback then
        uiProgressCallback(callbackData)
    end
end

--- Validates if a unit is suitable for inspection
--- @param unit string Unit ID to validate
--- @param requireCanInspect boolean Whether to also check CanInspect (default: false)
--- @return boolean True if unit is valid for inspection
--- @return string|nil Error message if invalid
function InspectionUtils:IsValidInspectionUnit(unit, requireCanInspect)
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

--- Requests inspection for a unit
--- @param unit string Unit ID
--- @return boolean True if inspection was requested successfully
function InspectionUtils:RequestInspection(unit)
    if not CanInspect(unit) then
        return false
    end
    
    -- Close any existing inspect window
    self:CloseInspectWindow()
    
    -- Request inspection
    local success, err = pcall(InspectUnit, unit)
    if success then
        return true
    else
        return false
    end
end

--- Handles successful inspection data retrieval
--- @param unit string Unit ID
--- @param name string Player name
function InspectionUtils:ProcessInspectionSuccess(unit, name)
    
    -- Check if this is a rescan (if we're in rescan mode)
    local isRescan = self.rescanQueue ~= nil
    
    -- Generate and show summary for this player
    local summary = self:CreatePlayerSummary(unit, name)
    if summary then
        
        -- Send character overview through UI progress callback
        self:SendProgressCallback({
            type = isRescan and "rescan_complete" or "character_complete",
            playerName = name,
            summary = summary,
            message = name .. ": " .. summary
        })
    else
        
        -- Send basic completion through UI progress callback
        self:SendProgressCallback({
            type = isRescan and "rescan_complete" or "character_complete",
            playerName = name,
            summary = "Inspection completed",
            message = name .. ": Inspection completed"
        })
    end
    
    -- Store successful scan data in persistent state
    self.groupScanState[name] = {
        hasData = true,
        summary = summary or "Inspection completed",
        timestamp = time()
    }
    
    -- Clear current inspection state
    self.currentInspectionUnit = nil
    self.currentInspectionName = nil
    
    -- Close inspect window before next inspection
    self:CloseInspectWindow()
    
    -- Move to next inspection/rescan after a short delay
    C_Timer.After(0.5, function()
        if isRescan then
            self:StartNextInspection(true)
        else
            self:StartNextInspection(false)
        end
    end)
end

--- Handles inspection or rescan failure (consolidated function)
--- @param unit string Unit ID
--- @param name string Player name
--- @param reason string Failure reason
--- @param isRescan boolean Whether this is a rescan operation
function InspectionUtils:HandleInspectionFailure(unit, name, reason, isRescan)
    local operationName = isRescan and "rescan" or "inspection"
    local progressType = isRescan and "rescan_failed" or "character_failed"

    if not isRescan then
        -- For initial inspections, mark as failed in persistent state
        self.groupScanState[name] = {
            hasData = false,
            summary = "Analysis failed - " .. reason,
            timestamp = time(),
            reason = reason
        }
    else
        -- For rescans, player remains in failed state (don't modify persistent state)
    end

    -- Send failure through UI progress callback
    self:SendProgressCallback({
        type = progressType,
        playerName = name,
        summary = operationName .. " failed - " .. reason,
        message = name .. ": " .. operationName .. " failed - " .. reason
    })

    -- Clear current inspection state
    self.currentInspectionUnit = nil
    self.currentInspectionName = nil

    -- Move to next inspection/rescan after a short delay
    C_Timer.After(0.5, function()
        if isRescan then
            self:StartNextInspection(true)
        else
            self:StartNextInspection(false)
        end
    end)
end

--- Gets all current group members
--- @return table Array of unit IDs
function InspectionUtils:GetGroupMembers()
    local members = {}
    
    -- Check group status
    
    if IsInRaid() then
        -- In raid, include all raid members including player
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitExists(unit) then
                table.insert(members, unit)
            end
        end
    elseif IsInGroup() then
        -- In party, include player and all party members
        table.insert(members, "player")
        for i = 1, GetNumSubgroupMembers() do
            local unit = "party" .. i
            if UnitExists(unit) then
                table.insert(members, unit)
            end
        end
    else
        -- Not in group, return empty list
        return {}
    end
    
    return members
end

--- Creates a brief summary for an inspected player
--- @param unit string Unit ID
--- @param playerName string Player name
--- @return string Brief summary of player's gear status
function InspectionUtils:CreatePlayerSummary(unit, playerName)
    local GearUtils = MrMythicalGearCheck.GearUtils
    
    -- Use the comprehensive analysis from live gear data
    local analysis = GearUtils:AnalyzeGear(unit, "detailed")
    
    -- Calculate item level from live data
    local itemLevel = 0
    local itemCount = 0
    local gearData = MrMythicalGearCheck.GearData
    if gearData and gearData.SLOT_NAMES then
        for slotId, _ in pairs(gearData.SLOT_NAMES) do
            local itemLink = GetInventoryItemLink(unit, slotId)
            if itemLink then
                local _, _, _, itemLvl = GetItemInfo(itemLink)
                if itemLvl and itemLvl > 0 then
                    itemLevel = itemLevel + itemLvl
                    itemCount = itemCount + 1
                end
            end
        end
    end
    local avgItemLevel = itemCount > 0 and math.floor(itemLevel / itemCount) or 0
    
    -- Create comprehensive summary
    if analysis.totalIssues == 0 then
        return string.format("iLvl %d - |cff00ff00PERFECT GEAR|r", avgItemLevel)
    else
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
        if analysis.missingSockets > 0 then
            table.insert(issueTypes, analysis.missingSockets .. " missing sockets")
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
        return string.format("iLvl %d - |cffff8000%d ISSUES|r (%s)", avgItemLevel, analysis.totalIssues, issueText)
    end
end

-- Event frames for debugging and monitoring (not critical for functionality)
-- Create event frame for inspection completion
local inspectionEventFrame = CreateFrame("Frame")
inspectionEventFrame:RegisterEvent("INSPECT_READY")
inspectionEventFrame:RegisterEvent("INSPECT_HONOR_UPDATE")  -- Fired when inspect data is available

inspectionEventFrame:SetScript("OnEvent", function(self, event, unitGUID)
    if event == "INSPECT_READY" or event == "INSPECT_HONOR_UPDATE" then
        -- Check if we have an active inspection
        if InspectionUtils.currentInspectionUnit then
            local unit = InspectionUtils.currentInspectionUnit
            local name = InspectionUtils.currentInspectionName
            
            if unit and UnitGUID(unit) == unitGUID then
                
                -- Process inspection success - now uses live data only
                InspectionUtils:ProcessInspectionSuccess(unit, name)
            end
        end
    end
end)

-- Create frame to monitor inspect window state
local inspectWindowFrame = CreateFrame("Frame")
-- Note: INSPECTOR_SHOW and INSPECTOR_HIDE are not valid WoW events
-- We monitor inspect window state through the IsInspectWindowOpen() function instead

inspectWindowFrame:SetScript("OnEvent", function(self, event)
    -- No events registered for this frame - monitoring is done via polling
end)

--- Checks if the inspect window is currently open
--- @return boolean True if inspect window is open
function InspectionUtils:IsInspectWindowOpen()
    -- Check multiple possible inspect frame names
    for _, frameName in ipairs(INSPECT_FRAME_NAMES) do
        local frame = _G[frameName]
        if frame and frame:IsVisible() then
            return true
        end
    end
    
    -- Also check if any frame with "Inspect" in the name is visible
    for name, frame in pairs(_G) do
        if type(frame) == "table" and type(frame.IsVisible) == "function" and 
           string.find(name, "Inspect") and frame:IsVisible() then
            return true
        end
    end
    
    return false
end

--- Gets the unit currently being inspected
--- @return string|nil Unit ID of currently inspected unit, or nil if none
function InspectionUtils:GetInspectedUnit()
    -- Check multiple possible inspect frame names
    for _, frameName in ipairs(INSPECT_FRAME_NAMES) do
        local frame = _G[frameName]
        if frame and frame:IsVisible() and frame.unit then
            local unit = frame.unit
            if UnitExists(unit) then
                return unit
            end
        end
    end
    
    -- Try to get from global inspected unit if available
    if InspectFrame and InspectFrame.unit then
        local unit = InspectFrame.unit
        if UnitExists(unit) then
            return unit
        end
    end
    
    -- Check if we can determine from any visible inspect-related frame
    for name, frame in pairs(_G) do
        if type(frame) == "table" and type(frame.IsVisible) == "function" and 
           string.find(name, "Inspect") and frame:IsVisible() and frame.unit then
            local unit = frame.unit
            if UnitExists(unit) then
                return unit
            end
        end
    end
    
    return nil
end

--- Checks if the currently inspected unit matches the expected unit
--- @param expectedUnit string Expected unit ID
--- @return boolean True if the inspected unit matches
function InspectionUtils:IsInspectingCorrectUnit(expectedUnit)
    local inspectedUnit = self:GetInspectedUnit()
    if not inspectedUnit then
        return false
    end
    
    -- Compare unit GUIDs for accuracy
    local expectedGUID = UnitGUID(expectedUnit)
    local inspectedGUID = UnitGUID(inspectedUnit)
    
    return expectedGUID == inspectedGUID
end

--- Forces the inspect UI to load and open
--- @param unit string Unit to inspect
function InspectionUtils:ForceOpenInspectUI(unit)
    local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
    local loadAddOn = rawget(_G, "LoadAddOn")

    if isAddOnLoaded and loadAddOn and not isAddOnLoaded("Blizzard_InspectUI") then
        local loaded, reason = loadAddOn("Blizzard_InspectUI")
        if not loaded then
            return false
        end
    end
    
    -- Try to show the inspect frame
    if InspectFrame and InspectFrame.Show then
        InspectFrame:Show()
        InspectFrame.unit = unit
        return true
    end
    
    return false
end

--- Checks if we can safely attempt to get inspection data
--- @param unit string Unit ID being inspected
--- @return boolean True if safe to attempt data retrieval
function InspectionUtils:CanSafelyGetInspectData(unit)
    -- Must be able to inspect the unit
    if not CanInspect(unit) then
        return false
    end
    
    -- Unit must exist and be a player
    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        return false
    end
    
    -- Unit should not be in combat
    if UnitAffectingCombat(unit) then
        return false
    end
    
    -- Check if inspect window is open (if we're not inspecting ourselves)
    if unit ~= "player" and not self:IsInspectWindowOpen() then
        return false
    end
    
    -- Check if we're inspecting the correct unit
    if unit ~= "player" and not self:IsInspectingCorrectUnit(unit) then
        return false
    end
    
    return true
end

--- Gets list of failed inspections (members that need scanning)
--- @return table List of members that haven't been successfully scanned
function InspectionUtils:GetFailedInspectionsList()
    local failedList = {}
    local groupMembers = self:GetGroupMembers()
    
    for _, unit in ipairs(groupMembers) do
        local playerName = UnitName(unit)
        if playerName then
            local scanState = self.groupScanState[playerName]
            -- Consider failed if never scanned OR if scanned but hasData is not true
            if not scanState or scanState.hasData ~= true then
                table.insert(failedList, {
                    name = playerName,
                    unit = unit,
                    reason = scanState and scanState.reason or "Not scanned"
                })
            end
        end
    end
    
    return failedList
end

--- Clears scan state for current group members (for fresh scan)
function InspectionUtils:ClearGroupScanState()
    local groupMembers = self:GetGroupMembers()
    for _, unit in ipairs(groupMembers) do
        local playerName = UnitName(unit)
        if playerName then
            self.groupScanState[playerName] = nil
        end
    end
end

--- Gets current inspection status for UI display
--- @return table Current inspection status
function InspectionUtils:GetInspectionStatus()
    -- Get current group members
    local groupMembers = self:GetGroupMembers()
    local memberReports = {}
    local failedCount = 0
    
    -- Build reports from persistent state
    for _, unit in ipairs(groupMembers) do
        local playerName = UnitName(unit)
        if playerName then
            local scanData = self.groupScanState[playerName]
            if scanData and scanData.hasData then
                -- Has scan data
                table.insert(memberReports, {
                    name = playerName,
                    unit = unit,
                    summary = scanData.summary,
                    hasData = true
                })
            else
                -- No scan data (not scanned or failed)
                local summary = "Not scanned"
                if scanData and scanData.summary then
                    summary = scanData.summary
                end
                table.insert(memberReports, {
                    name = playerName,
                    unit = unit,
                    summary = summary,
                    hasData = false
                })
                failedCount = failedCount + 1
            end
        end
    end
    
    local result = {
        hasResults = #memberReports > 0,
        totalMembers = #groupMembers,
        inspectedMembers = #memberReports - failedCount,
        failedCount = failedCount,
        canRescan = failedCount > 0 and not InCombatLockdown(),
        memberReports = memberReports,
        failedInspections = self:GetFailedInspectionsList(),
        queuedCount = #scanQueue,
        scanQueue = scanQueue
    }
    
    return result
end

--- Closes any open inspect windows
function InspectionUtils:CloseInspectWindow()
    -- Close standard inspect frames
    for _, frameName in ipairs(INSPECT_FRAME_NAMES) do
        local frame = _G[frameName]
        if frame and frame.Hide then
            frame:Hide()
        end
    end
    
    -- Also try to close via HideUIPanel (Blizzard's preferred method)
    if InspectFrame then
        HideUIPanel(InspectFrame)
    end
end

--- Clears inspection state and closes windows
function InspectionUtils:ClearInspectionState()
    self.currentInspectionUnit = nil
    self.currentInspectionName = nil
    self:CloseInspectWindow()
end
