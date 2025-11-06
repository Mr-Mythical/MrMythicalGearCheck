--[[
UnifiedUI.lua - Mr. Mythical Gear Check Unified Interface

Purpose: Modern unified interface for gear checking functionality
Dependencies: GearUtils, InspectionUtils, UIHelpers (accessed at runtime)
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.UnifiedUI = {}

local UnifiedUI = MrMythicalGearCheck.UnifiedUI

local UIContentCreators = {}
local NavigationManager = {}

-- Get UI constants at runtime
local function getUIConstants()
    local UIHelpers = MrMythicalGearCheck.UIHelpers
    return UIHelpers and UIHelpers.UI_CONSTANTS
end

-- Get UI helpers at runtime
local function getUIHelpers()
    return MrMythicalGearCheck.UIHelpers
end

function UIContentCreators.updateMemberFramesWithResults(uiElements, memberReports)
    if not uiElements.memberFrames or not memberReports then return end
    
    -- Create a lookup table for quick access to results by player name
    local resultsByName = {}
    for _, report in ipairs(memberReports) do
        if report.name then
            resultsByName[report.name] = report
        end
    end
    
    -- Update each member frame with existing results
    for _, memberFrame in ipairs(uiElements.memberFrames) do
        local playerName = memberFrame.playerName
        local result = resultsByName[playerName]
        
        if result and result.hasData then
            -- Show success status
            memberFrame.statusIcon:SetTexture("Interface/Buttons/UI-CheckBox-Check")
            memberFrame.statusIcon:SetVertexColor(0, 1, 0, 1) -- Green for success
            memberFrame.statusText:SetText(result.summary or "Complete")
            memberFrame.statusText:SetTextColor(0, 1, 0, 1)
        elseif result then
            -- Show failed status
            memberFrame.statusIcon:SetTexture("Interface/Buttons/UI-StopButton")
            memberFrame.statusIcon:SetVertexColor(1, 0, 0, 1) -- Red for failed
            memberFrame.statusText:SetText(result.summary or "Failed")
            memberFrame.statusText:SetTextColor(1, 0, 0, 1)
        else
            -- No previous data for this member
            memberFrame.statusIcon:SetTexture("Interface/Buttons/UI-MinusButton-Up")
            memberFrame.statusIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Gray for not scanned
            memberFrame.statusText:SetText("Not scanned")
            memberFrame.statusText:SetTextColor(0.7, 0.7, 0.7, 1)
        end
    end
end

function UIContentCreators.showInspectionStatus(uiElements, status, headerMessage)
    if not status or not status.memberReports then
        UIContentCreators.setAnalysisMessage(uiElements, "")
        UIContentCreators.updateGroupScanLayout(uiElements)
        return
    end
    
    local successCount = 0
    local failedCount = 0
    
    for _, report in ipairs(status.memberReports) do
        if report.hasData then
            successCount = successCount + 1
        else
            failedCount = failedCount + 1
        end
    end
    
    local summaryParts = {}

    if headerMessage and headerMessage ~= "" then
        table.insert(summaryParts, headerMessage)
    end

    local totalMembers = #status.memberReports
    table.insert(summaryParts, string.format("Analyzed %d members", totalMembers))

    if successCount > 0 then
        table.insert(summaryParts, string.format("%d complete", successCount))
    end

    if failedCount > 0 then
        table.insert(summaryParts, string.format("%d pending", failedCount))
    end

    if status.failedCount and status.failedCount > failedCount then
        table.insert(summaryParts, string.format("%d failed inspections", status.failedCount))
    end

    UIContentCreators.setAnalysisMessage(uiElements, table.concat(summaryParts, " • "))
    UIContentCreators.updateGroupScanLayout(uiElements)
end

function UIContentCreators.showGroupScanResults(uiElements, results)
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if not InspectionUtils then return end

    local status = results or InspectionUtils:GetInspectionStatus()
    if not status then
        UIContentCreators.setAnalysisMessage(uiElements, "")
        UIContentCreators.updateGroupValidationState(uiElements, "completed")
        UIContentCreators.updateGroupScanLayout(uiElements)
        return
    end

    UIContentCreators.showInspectionStatus(uiElements, status, "Group scan finished")
    UIContentCreators.updateGroupValidationState(uiElements, "completed")
    UIContentCreators.updateGroupScanLayout(uiElements)
end

function UIContentCreators.updateGroupScanLayout(uiElements)
    -- Calculate height for member frames (each frame is 25 pixels high, plus spacing)
    local memberHeight = uiElements.memberFrames and #uiElements.memberFrames * 25 + 40 or 40
    
    -- Position analysis text below member frames with some padding
    if uiElements.analysisText then
        -- Clear any existing points first
        uiElements.analysisText:ClearAllPoints()
        uiElements.analysisText:SetPoint("TOPLEFT", uiElements.scrollChild, "TOPLEFT", 10, -memberHeight)
        
        -- Calculate height for analysis text
        local textHeight = uiElements.analysisText:GetStringHeight()
        
        -- Set total height with proper spacing (member frames + text + padding)
        local totalHeight = memberHeight + textHeight + 30
        uiElements.scrollChild:SetHeight(math.max(totalHeight, 400)) -- Minimum height of 400
    end
end

function UIContentCreators.updateTextHeight(uiElements)
    local textHeight = uiElements.analysisText:GetStringHeight()
    uiElements.scrollChild:SetHeight(math.max(textHeight + 20, uiElements.scrollFrame:GetHeight()))
    
    -- Also update the layout to ensure proper positioning
    UIContentCreators.updateGroupScanLayout(uiElements)
end

function UIContentCreators.setAnalysisMessage(uiElements, message)
    if not uiElements or not uiElements.analysisText then
        return
    end

    uiElements.analysisText:SetText(message or "")
    UIContentCreators.updateTextHeight(uiElements)
end

function UIContentCreators.updateProgress(uiElements, completed, total)
    if not uiElements or not uiElements.progressBar or not uiElements.progressText then
        return
    end

    local progressPercent = 0
    if total and total > 0 then
        progressPercent = math.min(100, math.max(0, (completed / total) * 100))
    end

    uiElements.progressBar:SetValue(progressPercent)
    uiElements.progressText:SetText(string.format("%.0f%%", progressPercent))
end

function UIContentCreators.initializeGroupMemberDisplay(uiElements)
    if not uiElements then return end
    
    -- Clear any existing member frames
    if uiElements.memberFrames then
        for _, frame in ipairs(uiElements.memberFrames) do
            frame:Hide()
        end
        -- Clear the table (use wipe if available, otherwise recreate)
        if table.wipe then
            table.wipe(uiElements.memberFrames)
        else
            uiElements.memberFrames = {}
        end
    else
        uiElements.memberFrames = {}
    end
    
    -- Get current group members
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if not InspectionUtils then 
        return 
    end
    
    local groupMembers = InspectionUtils:GetGroupMembers()
    
    -- Create member display frames
    local yOffset = -10
    for i, unit in ipairs(groupMembers) do
        local memberFrame = UIContentCreators.createMemberDisplayFrame(uiElements.scrollChild, unit, i, yOffset)
        table.insert(uiElements.memberFrames, memberFrame)
        yOffset = yOffset - 25
    end
    
    -- Update scroll child height
    uiElements.scrollChild:SetHeight(math.max(#groupMembers * 25 + 20, 320))
end

function UIContentCreators.createMemberDisplayFrame(parent, unit, index, yOffset)
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS then
        return nil
    end
    
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(UI_CONSTANTS.FRAME.CONTENT_WIDTH - 60, 20)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    
    -- Member name
    local nameText = UnitName(unit) or "Unknown"
    local nameLabel = UIHelpers.createFontString(frame, "OVERLAY", "GameFontNormal",
        nameText, "LEFT", 0, 0)
    
    -- Status indicator
    local statusIcon = frame:CreateTexture(nil, "OVERLAY")
    statusIcon:SetSize(16, 16)
    statusIcon:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    statusIcon:SetTexture("Interface/Buttons/UI-MinusButton-Up")
    statusIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Gray for not scanned
    
    -- Status text
    local statusText = UIHelpers.createFontString(frame, "OVERLAY", "GameFontNormalSmall",
        "Not scanned", "RIGHT", -25, 0)
    statusText:SetTextColor(0.7, 0.7, 0.7, 1)
    
    frame.nameLabel = nameLabel
    frame.statusIcon = statusIcon
    frame.statusText = statusText
    frame.unit = unit
    frame.playerName = nameText
    
    return frame
end

function UIContentCreators.updateMemberStatus(uiElements, unit, status, resultText)
    for _, memberFrame in ipairs(uiElements.memberFrames) do
        if memberFrame.unit == unit then
            if status == "scanning" then
                memberFrame.statusIcon:SetTexture("Interface/Buttons/UI-RefreshButton")
                memberFrame.statusIcon:SetVertexColor(1, 0.8, 0, 1) -- Yellow for scanning
                memberFrame.statusText:SetText("Scanning...")
                memberFrame.statusText:SetTextColor(1, 0.8, 0, 1)
            elseif status == "success" then
                memberFrame.statusIcon:SetTexture("Interface/Buttons/UI-CheckBox-Check")
                memberFrame.statusIcon:SetVertexColor(0, 1, 0, 1) -- Green for success
                memberFrame.statusText:SetText(resultText or "Complete")
                memberFrame.statusText:SetTextColor(0, 1, 0, 1)
            elseif status == "failed" then
                memberFrame.statusIcon:SetTexture("Interface/Buttons/UI-StopButton")
                memberFrame.statusIcon:SetVertexColor(1, 0, 0, 1) -- Red for failed
                memberFrame.statusText:SetText(resultText or "Failed")
                memberFrame.statusText:SetTextColor(1, 0, 0, 1)
            end
            break
        end
    end
end

local MainFrameManager = {}

function MainFrameManager.createUnifiedFrame()
    local UI_CONSTANTS = getUIConstants()
    
    local frame = CreateFrame("Frame", "MrMythicalGearCheckUnifiedFrame", UIParent, "BackdropTemplate")
    frame:SetSize(UI_CONSTANTS.FRAME.WIDTH, UI_CONSTANTS.FRAME.HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    
    MainFrameManager.setupFrameBehavior(frame)
    frame:Hide()
    
    return frame
end

function MainFrameManager.setupFrameBehavior(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Pause scanning when window is closed
    frame:SetScript("OnHide", function()
        -- Find the group validation content frame and pause any active scans
        local contentFrame = frame.contentFrame
        if contentFrame then
            -- Look for UI elements in child frames
            local children = {contentFrame:GetChildren()}
            for _, child in ipairs(children) do
                if child.uiElements and child.uiElements.scanPaused ~= nil then
                    -- If currently scanning, pause it
                    if child.uiElements.pauseButton and child.uiElements.pauseButton:IsEnabled() then
                        local pauseText = child.uiElements.pauseButton:GetText()
                        if pauseText == "Pause" then
                            -- Set pause flag
                            child.uiElements.scanPaused = true
                            UIContentCreators.updateGroupValidationState(child.uiElements, "paused")
                        end
                    end
                end
            end
        end
    end)
    
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            frame:Hide()
            self:SetPropagateKeyboardInput(false)
            return
        end
    end)
end

function MainFrameManager.showMainFrame()
    if not MrMythicalGearCheckUnifiedFrame then
        MrMythicalGearCheckUnifiedFrame = MainFrameManager.createUnifiedFrame()
    end
    
    if MrMythicalGearCheckUnifiedFrame:IsShown() then
        MrMythicalGearCheckUnifiedFrame:Hide()
    else
        MrMythicalGearCheckUnifiedFrame:Show()
    end
end

function MainFrameManager.hideMainFrame()
    if MrMythicalGearCheckUnifiedFrame then
        MrMythicalGearCheckUnifiedFrame:Hide()
    end
end

function UIContentCreators.dashboard(parentFrame)
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS then
        return
    end
    
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge", 
        "Mr. Mythical Gear Check", "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    
    local subtitle = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontHighlight",
        "Personal, Group & Raid Gear Checking", "TOP", 0, -5)
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    
    local welcome = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormal",
        "Welcome to Mr. Mythical Gear Check! Use the navigation panel to check your gear or validate group and raid members.", "TOP", 0, -30)
    welcome:SetPoint("TOP", subtitle, "BOTTOM", 0, -30)
    welcome:SetWidth(500)
    welcome:SetJustifyH("CENTER")
    
    local version = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontDisableSmall",
        "Mr. Mythical Gear Check by Braunerr", "BOTTOM", 0, UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    UIHelpers.setTextColor(version, "DISABLED")
end

function UIContentCreators.personal_gear(parentFrame)
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS then
        return
    end
    
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Personal Gear Check", "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    
    -- Create scroll frame for gear check
    local scrollFrame, scrollChild = UIHelpers.createScrollFrame(parentFrame, 
        UI_CONSTANTS.FRAME.CONTENT_WIDTH - 40, 380, 
        UI_CONSTANTS.LAYOUT.LARGE_PADDING, -60)
    
    -- Check results text
    local analysisText = UIHelpers.createFontString(scrollChild, "OVERLAY", "GameFontNormal",
        "Loading gear check...", "TOPLEFT", 10, -10)
    analysisText:SetWidth(UI_CONSTANTS.FRAME.CONTENT_WIDTH - 80)
    analysisText:SetJustifyH("LEFT")
    analysisText:SetJustifyV("TOP")
    
    -- Refresh button
    local refreshButton = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
    refreshButton:SetSize(120, 25)
    refreshButton:SetPoint("BOTTOMRIGHT", -UI_CONSTANTS.LAYOUT.LARGE_PADDING, UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    refreshButton:SetText("Refresh Check")
    refreshButton:SetScript("OnClick", function()
        UIContentCreators.refreshPersonalGear(analysisText, scrollChild, scrollFrame)
    end)
    
    -- Initial load
    UIContentCreators.refreshPersonalGear(analysisText, scrollChild, scrollFrame)
end

function UIContentCreators.refreshPersonalGear(analysisText, scrollChild, scrollFrame)
    analysisText:SetText("Analyzing personal gear...")
    
    -- Use the GearUtils function for checking
    local GearUtils = MrMythicalGearCheck.GearUtils
    if not GearUtils then
        analysisText:SetText("Error: GearUtils module not loaded")
        return
    end
    
    if not GearUtils.AnalyzePersonalGear then
        analysisText:SetText("Error: AnalyzePersonalGear function not found")
        return
    end
    
    local success, analysis = pcall(GearUtils.AnalyzePersonalGear, GearUtils)
    
    if not success then
        analysisText:SetText("Error during analysis: " .. tostring(analysis))
        return
    end
    
    if not analysis then
        analysisText:SetText("Error: No analysis result returned")
        return
    end
    
    -- Display the analysis results
    if analysis.summaryLines and #analysis.summaryLines > 0 then
        analysisText:SetText(table.concat(analysis.summaryLines, "\n"))
    elseif analysis.error then
        analysisText:SetText("Analysis error: " .. analysis.error)
    else
        analysisText:SetText("Analysis completed but no results to display")
    end
    
    -- Adjust scroll child height based on content
    local textHeight = analysisText:GetStringHeight()
    scrollChild:SetHeight(math.max(textHeight + 20, scrollFrame:GetHeight()))
end

function UIContentCreators.group_validation(parentFrame)
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS then
        return
    end
    
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Group Gear Validation", "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    
    -- Control panel for scan operations
    local controlPanel = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    controlPanel:SetPoint("TOP", title, "BOTTOM", 0, -10)
    controlPanel:SetSize(UI_CONSTANTS.FRAME.CONTENT_WIDTH - 40, 60)
    controlPanel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    controlPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    
    -- Fresh Scan button
    local scanButton = CreateFrame("Button", nil, controlPanel, "UIPanelButtonTemplate")
    scanButton:SetPoint("LEFT", controlPanel, "LEFT", 10, 0)
    scanButton:SetSize(100, 30)
    scanButton:SetText("Fresh Scan")
    
    -- Pause button
    local pauseButton = CreateFrame("Button", nil, controlPanel, "UIPanelButtonTemplate")
    pauseButton:SetPoint("LEFT", scanButton, "RIGHT", 10, 0)
    pauseButton:SetSize(80, 30)
    pauseButton:SetText("Pause")
    pauseButton:Disable()
    
    -- Retry Failed button (always visible)
    local rescanButton = CreateFrame("Button", nil, controlPanel, "UIPanelButtonTemplate")
    rescanButton:SetPoint("LEFT", pauseButton, "RIGHT", 10, 0)
    rescanButton:SetSize(100, 30)
    rescanButton:SetText("Retry Failed")
    rescanButton:Disable() -- Initially disabled until there are failed scans
    
    -- Refresh Members button
    local refreshButton = CreateFrame("Button", nil, controlPanel, "UIPanelButtonTemplate")
    refreshButton:SetPoint("LEFT", rescanButton, "RIGHT", 10, 0)
    refreshButton:SetSize(110, 30)
    refreshButton:SetText("Refresh Members")
    refreshButton:SetScript("OnClick", function()
        UIContentCreators.refreshGroupData(parentFrame.uiElements)
    end)
    
    -- Progress bar
    local progressBar = CreateFrame("StatusBar", nil, controlPanel)
    progressBar:SetPoint("LEFT", refreshButton, "RIGHT", 20, 0)
    progressBar:SetPoint("RIGHT", controlPanel, "RIGHT", -10, 0)
    progressBar:SetHeight(20)
    progressBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    progressBar:SetStatusBarColor(0.2, 0.8, 0.2, 1.0)
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(0)
    
    -- Progress bar background
    local progressBg = progressBar:CreateTexture(nil, "BACKGROUND")
    progressBg:SetAllPoints(progressBar)
    progressBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    -- Progress text
    local progressText = UIHelpers.createFontString(progressBar, "OVERLAY", "GameFontNormalSmall",
        "Ready", "CENTER", 0, 0)
    
    -- Create scroll frame for checking results
    local scrollFrame, scrollChild = UIHelpers.createScrollFrame(parentFrame, 
        UI_CONSTANTS.FRAME.CONTENT_WIDTH - 40, 320, 
        UI_CONSTANTS.LAYOUT.LARGE_PADDING, -130)
    
    -- Analysis text (for status messages)
    local analysisText = UIHelpers.createFontString(scrollChild, "OVERLAY", "GameFontNormal",
        "", "TOPLEFT", 10, -10)
    analysisText:SetWidth(UI_CONSTANTS.FRAME.CONTENT_WIDTH - 80)
    analysisText:SetJustifyH("LEFT")
    analysisText:SetJustifyV("TOP")
    
    -- Store UI elements for easy access
    local uiElements = {
        scanButton = scanButton,
        pauseButton = pauseButton,
        rescanButton = rescanButton,
        refreshButton = refreshButton,
        progressBar = progressBar,
        progressText = progressText,
        analysisText = analysisText,
        scrollChild = scrollChild,
        scrollFrame = scrollFrame,
        memberFrames = {} -- Store individual member display frames
    }
    
    -- Initialize group member display
    UIContentCreators.initializeGroupMemberDisplay(uiElements)
    
    -- Set up button handlers
    UIContentCreators.setupGroupValidationHandlers(uiElements)
    
    -- Store uiElements for later access
    parentFrame.uiElements = uiElements
    
    -- Check for existing inspection results and display them
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if InspectionUtils then
        local status = InspectionUtils:GetInspectionStatus()
        if status and status.memberReports and #status.memberReports > 0 then
            -- Display existing results
            local successCount = 0
            local failedCount = 0
            
            for _, report in ipairs(status.memberReports) do
                if report.hasData then
                    successCount = successCount + 1
                else
                    failedCount = failedCount + 1
                end
            end
            
            UIContentCreators.setAnalysisMessage(uiElements, "")
            UIContentCreators.updateGroupScanLayout(uiElements)
            
            -- Update member frames with existing data
            UIContentCreators.updateMemberFramesWithResults(uiElements, status.memberReports)
            
            -- Update UI state to completed so retry button gets enabled if needed
            UIContentCreators.updateGroupValidationState(uiElements, "completed")
            
            -- Update layout to position text properly below member frames
            UIContentCreators.updateGroupScanLayout(uiElements)
            return
        end
    end
    
    -- Initial UI state (only if no existing results)
    UIContentCreators.updateGroupValidationState(uiElements, "ready")
end

function UIContentCreators.refreshGroupData(uiElements)
    if not uiElements then return end
    
    -- Just refresh the group member display without clearing data
    UIContentCreators.initializeGroupMemberDisplay(uiElements)
    
    -- Keep any existing scan results and just update the display
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if InspectionUtils then
        local status = InspectionUtils:GetInspectionStatus()
        if status and status.memberReports and #status.memberReports > 0 then
            -- Update member frames with existing data
            UIContentCreators.updateMemberFramesWithResults(uiElements, status.memberReports)
            
            -- Update UI state to completed so retry button gets enabled if needed
            UIContentCreators.updateGroupValidationState(uiElements, "completed")
        end
    end
    
    -- Update layout
    UIContentCreators.updateGroupScanLayout(uiElements)
end

-- Group checking control handlers
function UIContentCreators.setupGroupValidationHandlers(uiElements)
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if not InspectionUtils then return end
    
    -- Fresh Scan button - always does a complete fresh scan
    uiElements.scanButton:SetScript("OnClick", function()
        -- Check if in combat
        if InCombatLockdown() then
            UIContentCreators.setAnalysisMessage(uiElements, "")
            return
        end
        
        if not IsInGroup() and not IsInRaid() then
            UIContentCreators.setAnalysisMessage(uiElements, "")
            return
        end
        
        -- Always start a fresh scan - clear any previous results
        UIContentCreators.updateGroupValidationState(uiElements, "scanning")
        UIContentCreators.startGroupScan(uiElements)
    end)
    
    -- Pause button
    uiElements.pauseButton:SetScript("OnClick", function()
        local currentText = uiElements.pauseButton:GetText()
        if currentText == "Pause" then
            -- Set pause flag
            uiElements.scanPaused = true
            UIContentCreators.updateGroupValidationState(uiElements, "paused")
        else -- Resume
            -- Clear pause flag and continue scanning
            uiElements.scanPaused = false
            UIContentCreators.updateGroupValidationState(uiElements, "scanning")
            -- Note: The scanning will continue on the next timer tick
        end
    end)
    
    -- Retry Failed button - only retries failed inspections
    uiElements.rescanButton:SetScript("OnClick", function()
        -- Check if in combat
        if InCombatLockdown() then
            UIContentCreators.setAnalysisMessage(uiElements, "")
            return
        end
        
        -- Check if there are failed inspections to retry
        local status = InspectionUtils:GetInspectionStatus()
        if status.failedCount == 0 then
            UIContentCreators.setAnalysisMessage(uiElements, "")
            return
        end
        
        -- Start retrying failed inspections
        UIContentCreators.updateGroupValidationState(uiElements, "scanning")
        UIContentCreators.startRescan(uiElements)
    end)
end

function UIContentCreators.updateGroupValidationState(uiElements, state)
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    local status = InspectionUtils and InspectionUtils:GetInspectionStatus() or {failedCount = 0}
    
    if state == "ready" then
        uiElements.scanButton:Enable()
        uiElements.scanButton:SetText("Fresh Scan")
        uiElements.pauseButton:Disable()
        uiElements.pauseButton:SetText("Pause")
        uiElements.progressBar:SetValue(0)
        uiElements.progressText:SetText("Ready")
        uiElements.rescanButton:Disable() -- Disable retry button when ready
        
    elseif state == "scanning" then
        uiElements.scanButton:Disable()
        uiElements.pauseButton:Enable()
        uiElements.pauseButton:SetText("Pause")
        uiElements.progressText:SetText("Scanning...")
        uiElements.rescanButton:Disable() -- Disable retry button while scanning
        
    elseif state == "completed" then
        uiElements.scanButton:Enable()
        uiElements.scanButton:SetText("Fresh Scan")
        uiElements.pauseButton:Disable()
        uiElements.pauseButton:SetText("Pause")
        uiElements.progressBar:SetValue(100)
        uiElements.progressText:SetText("Complete")
        
        -- Enable retry button if there are failed inspections
        local hasFailed = status.failedCount > 0
        if not hasFailed and status.memberReports then
            -- Fallback: check memberReports for failed entries
            for _, report in ipairs(status.memberReports) do
                if not report.hasData or (report.summary and string.find(report.summary, "failed")) then
                    hasFailed = true
                    break
                end
            end
        end
        
        if hasFailed then
            uiElements.rescanButton:Enable()
            uiElements.rescanButton:SetText("Retry Failed (" .. status.failedCount .. ")")
        else
            uiElements.rescanButton:Disable()
            uiElements.rescanButton:SetText("Retry Failed")
        end
        
    elseif state == "paused" then
        uiElements.scanButton:Enable()
        uiElements.scanButton:SetText("Fresh Scan")
        uiElements.pauseButton:Enable()
        uiElements.pauseButton:SetText("Resume")
        uiElements.progressText:SetText("Paused")
        uiElements.rescanButton:Disable() -- Disable retry button when paused
    end
end

function UIContentCreators.startGroupScan(uiElements)
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if not InspectionUtils then
        UIContentCreators.setAnalysisMessage(uiElements, "")
        return
    end

    -- Clear scan state for current group members (fresh scan)
    InspectionUtils:ClearGroupScanState()
    
    -- Clear WoW's inspection cache for fresh scan
    InspectionUtils:ClearInspectionState()
    
    -- Reset member frames to "Not scanned" status
    for _, memberFrame in ipairs(uiElements.memberFrames) do
        memberFrame.statusIcon:SetTexture("Interface/Buttons/UI-MinusButton-Up")
        memberFrame.statusIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Gray for not scanned
        memberFrame.statusText:SetText("Not scanned")
        memberFrame.statusText:SetTextColor(0.7, 0.7, 0.7, 1)
    end

    -- Get group members for progress tracking
    local groupMembers = InspectionUtils:GetGroupMembers()
    local totalMembers = #groupMembers
    
    -- Update the group member display with current group composition
    UIContentCreators.initializeGroupMemberDisplay(uiElements)
    
    -- Check if we have any group members to scan
    if totalMembers == 0 then
        UIContentCreators.setAnalysisMessage(uiElements, "")
        UIContentCreators.updateGroupValidationState(uiElements, "ready")
        return
    end

    UIContentCreators.setAnalysisMessage(uiElements, "")
    
    -- Reset progress bar and pause flag
    UIContentCreators.updateProgress(uiElements, 0, totalMembers)
    uiElements.scanPaused = false
    
    local scannedCount = 0
    local results = {
        totalMembers = totalMembers,
        inspectedMembers = 0,
        memberReports = {}
    }
    
    -- Function to scan a single member
    local function scanMember(index)
        if index > totalMembers then
            -- All members scanned, show final results
            UIContentCreators.showGroupScanResults(uiElements, results)
            return
        end
        
        -- If paused, wait and try again
        if uiElements.scanPaused then
            C_Timer.After(0.5, function()
                if uiElements.scanPaused then
                    scanMember(index) -- keep waiting until unpaused
                else
                    scanMember(index)
                end
            end)
            return
        end
        
        local unit = groupMembers[index]
        local name = UnitName(unit) or "Unknown"
        
        -- Track retry attempts for this member
        if not uiElements.memberRetryCount then
            uiElements.memberRetryCount = {}
        end
        uiElements.memberRetryCount[index] = (uiElements.memberRetryCount[index] or 0) + 1
        
        -- Update status to scanning
        UIContentCreators.updateMemberStatus(uiElements, unit, "scanning")
        
        -- First try to get gear data
        local gearInfo = MrMythicalGearCheck.GearUtils:GetUnitGear(unit)
        
        if gearInfo then
            -- Process the gear data immediately
            results.inspectedMembers = results.inspectedMembers + 1
            
            local summary = InspectionUtils:CreatePlayerSummary(unit, name, gearInfo)
            
            -- Store successful scan data persistently
            InspectionUtils.groupScanState[name] = {
                hasData = true,
                summary = summary or "Analysis completed",
                gearInfo = gearInfo,
                timestamp = time()
            }
            
            table.insert(results.memberReports, {
                name = name,
                unit = unit,
                summary = summary or "Analysis completed",
                hasData = true
            })
            
            UIContentCreators.updateMemberStatus(uiElements, unit, "success", summary or "Complete")
            
            -- Update progress and move to next member
            scannedCount = scannedCount + 1
            UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
            
            -- Schedule next member scan with a delay
            C_Timer.After(0.5, function()
                if uiElements.scanPaused then
                    scanMember(index + 1) -- will re-check pause at top
                else
                    scanMember(index + 1)
                end
            end)
        else
            -- No data, need to inspect like the targeting command does
            
            -- Check if we can inspect this unit
            if not MrMythicalGearCheck.GearUtils:CanInspectUnit(unit) then
                
                table.insert(results.memberReports, {
                    name = name,
                    unit = unit,
                    summary = "Cannot inspect - not in group or out of range",
                    hasData = false
                })
                
                UIContentCreators.updateMemberStatus(uiElements, unit, "failed", "Not inspectable")
                
                -- Update progress and move to next member
                scannedCount = scannedCount + 1
                UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
                
                -- Schedule next member scan with a delay
                C_Timer.After(0.5, function()
                    scanMember(index + 1)
                end)
                return
            end
            
            -- Request inspection like the targeting command does
            UIContentCreators.updateMemberStatus(uiElements, unit, "scanning", "Inspecting...")
            local success, errorMsg = pcall(InspectUnit, unit)
            
            if not success then
                
                -- Store failed scan state persistently
                InspectionUtils.groupScanState[name] = {}
                
                table.insert(results.memberReports, {
                    name = name,
                    unit = unit,
                    summary = "Inspection request failed",
                    hasData = false
                })
                
                UIContentCreators.updateMemberStatus(uiElements, unit, "failed", "Inspection failed")
                
                -- Update progress and move to next member
                scannedCount = scannedCount + 1
                UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
                
                -- Schedule next member scan with a delay
                C_Timer.After(0.5, function()
                    scanMember(index + 1)
                end)
                return
            end
            
            -- Set up exponential backoff for inspection delay
            local memberRetryCount = 0
            local memberMaxRetries = 5
            local memberBaseDelay = 0.5 -- Starting delay in seconds
            
            local function attemptMemberInspectionCheck()
                memberRetryCount = memberRetryCount + 1
                
                local retryGearInfo = MrMythicalGearCheck.GearUtils:GetUnitGear(unit)
                
                if retryGearInfo then
                    
                    results.inspectedMembers = results.inspectedMembers + 1
                    
                    local summary = InspectionUtils:CreatePlayerSummary(unit, name, retryGearInfo)
                    
                    -- Store successful scan data persistently
                    InspectionUtils.groupScanState[name] = {
                        hasData = true,
                        summary = summary or "Analysis completed",
                        gearInfo = retryGearInfo,
                        timestamp = time()
                    }
                    
                    table.insert(results.memberReports, {
                        name = name,
                        unit = unit,
                        summary = summary or "Analysis completed",
                        hasData = true
                    })

                    UIContentCreators.updateMemberStatus(uiElements, unit, "success", summary or "Complete")                    -- Update progress and move to next member
                    scannedCount = scannedCount + 1
                    UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
                    
                    -- Schedule next member scan with a delay
                    C_Timer.After(0.5, function()
                        scanMember(index + 1)
                    end)
                elseif memberRetryCount < memberMaxRetries then
                    -- Calculate exponential backoff delay
                    local delay = memberBaseDelay * (2 ^ (memberRetryCount - 1))
                    
                    C_Timer.After(delay, function()
                        if uiElements.scanPaused then
                            scanMember(index) -- re-check pause, don't continue retry until unpaused
                        else
                            attemptMemberInspectionCheck()
                        end
                    end)
                else
                    
                    -- Store failed scan state persistently (empty table indicates failed/unscanned)
                    InspectionUtils.groupScanState[name] = {}
                    
                    table.insert(results.memberReports, {
                        name = name,
                        unit = unit,
                        summary = "Inspection failed - no gear data received",
                        hasData = false
                    })
                    
                    UIContentCreators.updateMemberStatus(uiElements, unit, "failed", "Inspection failed")
                    
                    -- Update progress and move to next member
                    scannedCount = scannedCount + 1
                    UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
                    
                    -- Schedule next member scan with a delay
                    C_Timer.After(0.5, function()
                        if uiElements.scanPaused then
                            scanMember(index + 1)
                        else
                            scanMember(index + 1)
                        end
                    end)
                end
            end
            
            -- Start the first check after initial delay
            C_Timer.After(memberBaseDelay, function()
                if uiElements.scanPaused then
                    scanMember(index)
                else
                    attemptMemberInspectionCheck()
                end
            end)


        end
    end
    
    -- Start scanning the first member
    scanMember(1)
end

function UIContentCreators.startRescan(uiElements)
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if not InspectionUtils then
        UIContentCreators.setAnalysisMessage(uiElements, "")
        return
    end

    -- Check if there are failed inspections to retry
    local status = InspectionUtils:GetInspectionStatus()
    if status.failedCount == 0 then
        UIContentCreators.setAnalysisMessage(uiElements, "")
        UIContentCreators.updateGroupValidationState(uiElements, "completed")
        return
    end

    -- Use the proper rescan function from InspectionUtils
    local totalToRescan = status.failedCount
    local completedRescans = 0
    
    -- Update the group member display with current group composition
    UIContentCreators.initializeGroupMemberDisplay(uiElements)
    
    -- Set initial progress state and UI state
    UIContentCreators.updateProgress(uiElements, 0, totalToRescan)
    uiElements.progressText:SetText("Retrying...")
    UIContentCreators.updateGroupValidationState(uiElements, "scanning")
    
    InspectionUtils:RescanFailedInspections(
        function(updatedStatus)
            UIContentCreators.updateProgress(uiElements, totalToRescan, totalToRescan)
            uiElements.progressText:SetText("Complete")
            UIContentCreators.showInspectionStatus(uiElements, updatedStatus)
            UIContentCreators.updateMemberFramesWithResults(uiElements, updatedStatus.memberReports)
            UIContentCreators.updateGroupValidationState(uiElements, "completed")
        end,
        function(progress)
            -- Progress callback
            if progress.type == "rescan_complete" or progress.type == "character_complete" or progress.type == "rescan_failed" then
                completedRescans = completedRescans + 1
                UIContentCreators.updateProgress(uiElements, completedRescans, totalToRescan)
                
                -- Update member frame for this player
                local status = InspectionUtils:GetInspectionStatus()
                UIContentCreators.updateMemberFramesWithResults(uiElements, status.memberReports)
            end
        end
    )
end

local MainFrameManager = {}

function MainFrameManager.createUnifiedFrame()
    local UI_CONSTANTS = getUIConstants()
    
    local frame = CreateFrame("Frame", "MrMythicalGearCheckUnifiedFrame", UIParent, "BackdropTemplate")
    frame:SetSize(UI_CONSTANTS.FRAME.WIDTH, UI_CONSTANTS.FRAME.HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    
    MainFrameManager.setupFrameBehavior(frame)
    frame:Hide()
    
    return frame
end

function MainFrameManager.setupFrameBehavior(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            frame:Hide()
            self:SetPropagateKeyboardInput(false)
            return
        end
        self:SetPropagateKeyboardInput(true)
    end)
end

function MainFrameManager.createNavigationPanel(parentFrame)
    local UI_CONSTANTS = getUIConstants()
    
    local navPanel = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    navPanel:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.PADDING, -UI_CONSTANTS.LAYOUT.PADDING)
    navPanel:SetSize(UI_CONSTANTS.FRAME.NAV_PANEL_WIDTH, UI_CONSTANTS.FRAME.HEIGHT - (UI_CONSTANTS.LAYOUT.PADDING * 2))
    navPanel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    
    local color = UI_CONSTANTS.COLORS.NAV_BACKGROUND
    navPanel:SetBackdropColor(color.r, color.g, color.b, color.a)
    
    return navPanel
end

function MainFrameManager.createContentFrame(parentFrame)
    local UI_CONSTANTS = getUIConstants()
    
    local contentFrame = CreateFrame("Frame", nil, parentFrame)
    contentFrame:SetPoint("TOPLEFT", UI_CONSTANTS.FRAME.NAV_PANEL_WIDTH + UI_CONSTANTS.LAYOUT.PADDING * 2, -UI_CONSTANTS.LAYOUT.PADDING)
    contentFrame:SetSize(UI_CONSTANTS.FRAME.CONTENT_WIDTH, UI_CONSTANTS.FRAME.HEIGHT - (UI_CONSTANTS.LAYOUT.PADDING * 2))
    return contentFrame
end

-- Navigation button data - initialized at runtime
NavigationManager.BUTTON_DATA = nil

function NavigationManager.getButtonData()
    if not NavigationManager.BUTTON_DATA then
        local UI_CONSTANTS = getUIConstants()
        NavigationManager.BUTTON_DATA = {
            {id = "dashboard", text = "Dashboard", y = -UI_CONSTANTS.LAYOUT.LARGE_PADDING},
            {id = "personal_gear", text = "Personal Gear", y = -60},
            {id = "group_validation", text = "Group Check", y = -100},
            {id = "settings", text = "Settings", y = -140}
        }
    end
    return NavigationManager.BUTTON_DATA
end

function NavigationManager.createButtons(navPanel, contentFrame)
    local navButtons = {}
    local UI_CONSTANTS = getUIConstants()
    
    for _, buttonInfo in ipairs(NavigationManager.getButtonData()) do
        local button = NavigationManager.createNavigationButton(navPanel, buttonInfo, contentFrame, navButtons)
        navButtons[buttonInfo.id] = button
        
        if buttonInfo.id == "dashboard" then
            button:SetNormalFontObject("GameFontHighlight")
        end
    end
    
    return navButtons
end

function NavigationManager.createNavigationButton(navPanel, buttonInfo, contentFrame, navButtons)
    local UI_CONSTANTS = getUIConstants()
    
    local button = CreateFrame("Button", nil, navPanel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.PADDING, buttonInfo.y)
    button:SetSize(120, UI_CONSTANTS.LAYOUT.BUTTON_HEIGHT)
    button:SetText(buttonInfo.text)
    
    button:SetScript("OnClick", function()
        NavigationManager.handleButtonClick(buttonInfo, button, navButtons, contentFrame)
    end)
    
    return button
end

function NavigationManager.handleButtonClick(buttonInfo, button, navButtons, contentFrame)
    local UI_CONSTANTS = getUIConstants()
    
    if buttonInfo.id == "settings" then
        MainFrameManager.openSettings()
        return
    end
    
    NavigationManager.updateButtonStates(button, navButtons)
    NavigationManager.showContent(buttonInfo.id, contentFrame)
end

function MainFrameManager.openSettings()
    UnifiedUI:Hide()
    
    local registry = _G.MrMythicalSettingsRegistry
    if registry and registry.parentCategory and registry.parentCategory.GetID then
        Settings.OpenToCategory(registry.parentCategory:GetID())
    elseif MrMythicalGearCheck.Options and MrMythicalGearCheck.Options.openSettings then
        MrMythicalGearCheck.Options.openSettings()
    else
        SettingsPanel:Open()
    end
end

function NavigationManager.updateButtonStates(activeButton, navButtons)
    for _, button in pairs(navButtons) do
        button:SetNormalFontObject("GameFontNormal")
    end
    activeButton:SetNormalFontObject("GameFontHighlight")
end

function NavigationManager.clearContent(contentFrame)
    for _, child in ipairs({contentFrame:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, region in ipairs({contentFrame:GetRegions()}) do
        if region.Hide then
            region:Hide()
        end
    end
end

function NavigationManager.showContent(contentType, contentFrame)
    NavigationManager.clearContent(contentFrame)
    
    if UIContentCreators[contentType] then
        UIContentCreators[contentType](contentFrame)
        
    else
        local UIHelpers = getUIHelpers()
        if UIHelpers then
            UIHelpers.createFontString(contentFrame, "OVERLAY", "GameFontNormal",
                "Content not available: " .. contentType, "CENTER", 0, 0)
        end
    end
end

-- Delayed UI initialization to ensure all dependencies are loaded
local function initializeUI()
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS then
        -- Retry after a short delay if dependencies aren't ready
        C_Timer.After(0.1, initializeUI)
        return
    end
    
    -- Initialize the unified frame
    local unifiedFrame = MainFrameManager.createUnifiedFrame()
    local navPanel = MainFrameManager.createNavigationPanel(unifiedFrame)
    local contentFrame = MainFrameManager.createContentFrame(unifiedFrame)
    local navButtons = NavigationManager.createButtons(navPanel, contentFrame)

    -- Store reference to navButtons for access from other functions
    UnifiedUI.navButtons = navButtons
    
    -- Store references for global access
    UnifiedUI.unifiedFrame = unifiedFrame
    UnifiedUI.contentFrame = contentFrame
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, unifiedFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        UnifiedUI:Hide()
    end)
    
    -- Initialize default content
    if UI_CONSTANTS then
        NavigationManager.showContent("dashboard", contentFrame)
    end
end

-- Schedule UI initialization for after addon load
C_Timer.After(0.1, initializeUI)

function UnifiedUI:Show(contentType)
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS or not self.unifiedFrame then
        return
    end
    
    self.unifiedFrame:Show()
    
    if contentType and contentType ~= "dashboard" then
        NavigationManager.showContent(contentType, self.contentFrame)
        if self.navButtons and self.navButtons[contentType] then
            NavigationManager.updateButtonStates(self.navButtons[contentType], self.navButtons)
        end
    else
        NavigationManager.showContent("dashboard", self.contentFrame)
    end
end

function UnifiedUI:Hide()
    if self.unifiedFrame then
        self.unifiedFrame:Hide()
    end
end

function UnifiedUI:Toggle(contentType)
    if not self.unifiedFrame then
        return
    end
    
    if self.unifiedFrame:IsShown() then
        self:Hide()
    else
        self:Show(contentType)
    end
end

-- Ensure global access
_G.MrMythicalGearCheck = MrMythicalGearCheck
