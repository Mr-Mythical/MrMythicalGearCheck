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

local function getUIConstants()
    local UIHelpers = MrMythicalGearCheck.UIHelpers
    return UIHelpers and UIHelpers.UI_CONSTANTS
end

local function getUIHelpers()
    return MrMythicalGearCheck.UIHelpers
end

function UIContentCreators.updateMemberFramesWithResults(uiElements, memberReports)
    if not uiElements.memberFrames or not memberReports then return end

    local InspectionUnits = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUnits
    
    -- Create a lookup table for quick access to results by player name
    local resultsByName = {}
    for _, report in ipairs(memberReports) do
        if report.name then
            resultsByName[report.name] = report
        end
    end

    local function findReport(playerName, unit)
        local direct = resultsByName[playerName]
        if direct then
            return direct
        end
        if unit then
            for _, report in ipairs(memberReports) do
                if report.unit == unit then
                    return report
                end
            end
        end
        if InspectionUnits and InspectionUnits.NamesMatch then
            for _, report in ipairs(memberReports) do
                if InspectionUnits:NamesMatch(report.name, playerName) then
                    return report
                end
            end
        end
        return nil
    end
    
    -- Update each member frame with existing results
    for _, memberFrame in ipairs(uiElements.memberFrames) do
        local playerName = memberFrame.playerName
        local result = findReport(playerName, memberFrame.unit)
        
        if result and result.hasData then
            memberFrame.details = result.details
            memberFrame.reportSummary = result.summary
            memberFrame.statusIcon:SetTexture("Interface/Buttons/UI-CheckBox-Check")
            memberFrame.statusIcon:SetVertexColor(0, 1, 0, 1) -- Green for success
            memberFrame.statusText:SetText(result.summary or "Complete")
            memberFrame.statusText:SetTextColor(0, 1, 0, 1)
        elseif result then
            memberFrame.details = result.details
            memberFrame.reportSummary = result.summary
            memberFrame.statusIcon:SetTexture("Interface/Buttons/UI-StopButton")
            memberFrame.statusIcon:SetVertexColor(1, 0, 0, 1) -- Red for failed
            local failText = result.reason or result.summary or "Failed"
            memberFrame.statusText:SetText(failText)
            memberFrame.statusText:SetTextColor(1, 0, 0, 1)
        else
            memberFrame.details = nil
            memberFrame.reportSummary = nil
            memberFrame.statusIcon:SetTexture("Interface/Buttons/UI-MinusButton-Up")
            memberFrame.statusIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Gray for not scanned
            memberFrame.statusText:SetText("Not scanned")
            memberFrame.statusText:SetTextColor(0.7, 0.7, 0.7, 1)
        end
    end
end

function UIContentCreators.showMemberDetails(uiElements, memberFrame)
    if not uiElements or not memberFrame then
        return
    end

    uiElements.selectedMemberFrame = memberFrame

    local name = memberFrame.playerName or "Unknown"
    local shortName = (MrMythicalGearCheck.ReportUtils and MrMythicalGearCheck.ReportUtils:GetShortName(name)) or name
    local details = memberFrame.details
    local summary = memberFrame.reportSummary or memberFrame.statusText and memberFrame.statusText:GetText() or "No scan data"
    local classLabel = details and details.className
    if classLabel then
        classLabel = " (" .. classLabel .. ")"
    else
        classLabel = ""
    end

    local lines = {
        "|cffadd8e6" .. shortName .. classLabel .. "|r",
        summary,
        ""
    }

    if details and details.gearDetails and #details.gearDetails > 0 then
        table.insert(lines, "|cffadd8e6=== GEAR ISSUES ===|r")
        for _, detail in ipairs(details.gearDetails) do
            table.insert(lines, detail)
        end
    elseif details and details.totalIssues == 0 then
        table.insert(lines, "|cff00ff00No gear issues detected.|r")
    elseif memberFrame.statusText and memberFrame.statusText:GetText() == "Not scanned" then
        table.insert(lines, "This player has not been scanned yet.")
    else
        table.insert(lines, "No detailed issue list available. Run a fresh scan.")
    end

    table.insert(lines, "")
    table.insert(lines, "|cffaaaaaaClick Whisper Selected to send these issues, or click another player.|r")

    UIContentCreators.setAnalysisMessage(uiElements, table.concat(lines, "\n"))

    if uiElements.whisperButton then
        local isSelf = memberFrame.unit and UnitIsUnit and UnitIsUnit(memberFrame.unit, "player")
        if isSelf then
            uiElements.whisperButton:Disable()
        else
            uiElements.whisperButton:Enable()
        end
    end
end

local function getReportUtils()
    return MrMythicalGearCheck and MrMythicalGearCheck.ReportUtils
end

function UIContentCreators.getCurrentMemberReports(uiElements)
    if uiElements and uiElements.lastMemberReports then
        return uiElements.lastMemberReports
    end

    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if not InspectionUtils then
        return {}
    end

    local status = InspectionUtils:GetInspectionStatus()
    return (status and status.memberReports) or {}
end

function UIContentCreators.refreshMemberListDisplay(uiElements)
    if not uiElements then
        return
    end

    local ReportUtils = getReportUtils()
    local reports = UIContentCreators.getCurrentMemberReports(uiElements)
    uiElements.lastMemberReports = reports

    local sortMode = uiElements.sortMode or "issues_first"
    local filterMode = uiElements.filterMode or "all"
    local displayReports = reports
    if ReportUtils and ReportUtils.SortAndFilterReports then
        displayReports = ReportUtils:SortAndFilterReports(reports, sortMode, filterMode)
    end

    -- Clear existing frames
    if uiElements.memberFrames then
        for _, frame in ipairs(uiElements.memberFrames) do
            frame:Hide()
            frame:SetParent(nil)
        end
    end
    uiElements.memberFrames = {}

    local yOffset = -10
    for i, report in ipairs(displayReports) do
        local unit = report.unit
        if unit and UnitExists(unit) then
            local memberFrame = UIContentCreators.createMemberDisplayFrame(uiElements.scrollChild, unit, i, yOffset)
            if memberFrame then
                memberFrame.uiElements = uiElements
                memberFrame.details = report.details
                memberFrame.reportSummary = report.summary
                memberFrame.playerName = report.name or memberFrame.playerName
                table.insert(uiElements.memberFrames, memberFrame)
                yOffset = yOffset - 25
            end
        end
    end

    UIContentCreators.updateMemberFramesWithResults(uiElements, displayReports)
    uiElements.scrollChild:SetHeight(math.max(#displayReports * 25 + 20, 320))
    UIContentCreators.updateGroupScanLayout(uiElements)
    UIContentCreators.updateSortFilterLabels(uiElements)
end

function UIContentCreators.updateSortFilterLabels(uiElements)
    if not uiElements then
        return
    end

    local ReportUtils = getReportUtils()
    local sortMode = uiElements.sortMode or "issues_first"
    local filterMode = uiElements.filterMode or "all"

    if uiElements.sortButton and ReportUtils then
        uiElements.sortButton:SetText("Sort: " .. (ReportUtils.SORT_MODES[sortMode] or "Issues First"))
    end
    if uiElements.filterButton and ReportUtils then
        uiElements.filterButton:SetText("Filter: " .. (ReportUtils.FILTER_MODES[filterMode] or "All"))
    end
end

function UIContentCreators.cycleSortMode(uiElements)
    local order = { "issues_first", "name", "class", "unscanned_first" }
    local current = uiElements.sortMode or "issues_first"
    local nextMode = order[1]
    for i, mode in ipairs(order) do
        if mode == current then
            nextMode = order[(i % #order) + 1]
            break
        end
    end
    uiElements.sortMode = nextMode
    UIContentCreators.refreshMemberListDisplay(uiElements)
end

function UIContentCreators.cycleFilterMode(uiElements)
    local order = { "all", "issues_only", "perfect_only", "unscanned_only" }
    local current = uiElements.filterMode or "all"
    local nextMode = order[1]
    for i, mode in ipairs(order) do
        if mode == current then
            nextMode = order[(i % #order) + 1]
            break
        end
    end
    uiElements.filterMode = nextMode
    UIContentCreators.refreshMemberListDisplay(uiElements)
end

function UIContentCreators.announceGroupResults(uiElements)
    local ReportUtils = getReportUtils()
    if not ReportUtils then
        UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Report module unavailable.|r")
        return
    end

    local reports = UIContentCreators.getCurrentMemberReports(uiElements)
    if not reports or #reports == 0 then
        UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000No scan results to announce. Run a Fresh Scan first.|r")
        return
    end

    local ok, message = ReportUtils:AnnounceToGroup(reports)
    if ok then
        UIContentCreators.setAnalysisMessage(uiElements, "|cff00ff00" .. message .. "|r")
    else
        UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000" .. (message or "Announce failed.") .. "|r")
    end
end

function UIContentCreators.whisperSelectedMember(uiElements)
    local ReportUtils = getReportUtils()
    if not ReportUtils then
        UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Report module unavailable.|r")
        return
    end

    local memberFrame = uiElements.selectedMemberFrame
    if not memberFrame then
        UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Select a player first (click their name).|r")
        return
    end

    local reports = UIContentCreators.getCurrentMemberReports(uiElements)
    local report = nil
    local InspectionUnits = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUnits
    for _, candidate in ipairs(reports) do
        if candidate.unit == memberFrame.unit
            or (InspectionUnits and InspectionUnits.NamesMatch and InspectionUnits:NamesMatch(candidate.name, memberFrame.playerName)) then
            report = candidate
            break
        end
    end

    if not report then
        report = {
            name = memberFrame.playerName,
            unit = memberFrame.unit,
            summary = memberFrame.reportSummary,
            details = memberFrame.details,
            hasData = memberFrame.details ~= nil,
            reason = memberFrame.reportSummary,
        }
    end

    local ok, message = ReportUtils:WhisperPlayerReport(report)
    if ok then
        UIContentCreators.showMemberDetails(uiElements, memberFrame)
        local detailsText = uiElements.analysisText and uiElements.analysisText:GetText() or ""
        UIContentCreators.setAnalysisMessage(uiElements, "|cff00ff00" .. message .. "|r\n\n" .. detailsText)
    else
        UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000" .. (message or "Whisper failed.") .. "|r")
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
        if uiElements.scrollFrame and uiElements.scrollFrame._UpdateScrollRange then
            uiElements.scrollFrame:_UpdateScrollRange()
        end
    end
end

function UIContentCreators.updateTextHeight(uiElements)
    local textHeight = uiElements.analysisText:GetStringHeight()
    uiElements.scrollChild:SetHeight(math.max(textHeight + 20, uiElements.scrollFrame:GetHeight()))
    if uiElements.scrollFrame and uiElements.scrollFrame._UpdateScrollRange then
        uiElements.scrollFrame:_UpdateScrollRange()
    end
    
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

    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if not InspectionUtils then
        return
    end

    local status = InspectionUtils:GetInspectionStatus()
    local reports = (status and status.memberReports) or {}

    -- If there are no scan reports yet, synthesize placeholder rows from current group.
    if #reports == 0 then
        local groupMembers = InspectionUtils:GetGroupMembers()
        local InspectionUnits = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUnits
        for _, unit in ipairs(groupMembers) do
            local name = (InspectionUnits and InspectionUnits.GetUnitFullName and InspectionUnits:GetUnitFullName(unit))
                or UnitName(unit)
            table.insert(reports, {
                name = name,
                unit = unit,
                summary = "Not scanned",
                hasData = false,
            })
        end
    end

    uiElements.lastMemberReports = reports
    uiElements.sortMode = uiElements.sortMode or "issues_first"
    uiElements.filterMode = uiElements.filterMode or "all"
    UIContentCreators.refreshMemberListDisplay(uiElements)
end

function UIContentCreators.createMemberDisplayFrame(parent, unit, index, yOffset)
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS then
        return nil
    end

    local InspectionUnits = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUnits
    local fullName = (InspectionUnits and InspectionUnits.GetUnitFullName and InspectionUnits:GetUnitFullName(unit))
        or UnitName(unit)
        or "Unknown"
    local shortName = UnitName(unit) or "Unknown"
    local className, classFile = UnitClass(unit)
    
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(UI_CONSTANTS.FRAME.CONTENT_WIDTH - 60, 20)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:SetHighlightTexture("Interface/Buttons/UI-Listbox-Highlight", "ADD")
    
    -- Member name (show short name; store full name for stable matching)
    local nameLabel = UIHelpers.createFontString(frame, "OVERLAY", "GameFontNormal",
        shortName, "LEFT", 0, 0)
    if classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
        local color = RAID_CLASS_COLORS[classFile]
        nameLabel:SetTextColor(color.r, color.g, color.b)
    end
    
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
    frame.playerName = fullName
    frame.className = className
    frame.classFile = classFile
    frame.details = nil
    frame.reportSummary = nil

    frame:SetScript("OnClick", function(_, button)
        local uiElements = frame.uiElements
        if not uiElements then
            return
        end
        if button == "RightButton" then
            uiElements.selectedMemberFrame = frame
            UIContentCreators.whisperSelectedMember(uiElements)
            return
        end
        UIContentCreators.showMemberDetails(uiElements, frame)
    end)

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(shortName, 1, 1, 1)
        if className then
            GameTooltip:AddLine(className, 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine("Left-click: view issues", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: whisper issues", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return frame
end

function UIContentCreators.updateMemberStatus(uiElements, unit, status, resultText, details)
    local InspectionUnits = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUnits
    local fullName = (InspectionUnits and InspectionUnits.GetUnitFullName and InspectionUnits:GetUnitFullName(unit))
        or UnitName(unit)

    for _, memberFrame in ipairs(uiElements.memberFrames) do
        local matches = memberFrame.unit == unit
        if not matches and InspectionUnits and InspectionUnits.NamesMatch and fullName then
            matches = InspectionUnits:NamesMatch(memberFrame.playerName, fullName)
        end

        if matches then
            if details ~= nil then
                memberFrame.details = details
            end
            if resultText then
                memberFrame.reportSummary = resultText
            end

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

function UIContentCreators.dashboard(parentFrame)
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS then
        return
    end
    
    local title = UIHelpers.createTitle(parentFrame, "Mr. Mythical Gear Check",
        "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING, 520)

    local inGroup = IsInGroup() or IsInRaid()
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    local status = InspectionUtils and InspectionUtils:GetInspectionStatus()
    local statusLine = "Ready to check your gear."
    if inGroup and status and status.totalMembers and status.totalMembers > 0 then
        local issues = 0
        local ReportUtils = getReportUtils()
        if status.memberReports and ReportUtils then
            for _, report in ipairs(status.memberReports) do
                if ReportUtils:HasIssues(report) then
                    issues = issues + 1
                end
            end
        end
        statusLine = string.format(
            "Group: %d/%d scanned%s",
            status.inspectedMembers or 0,
            status.totalMembers,
            issues > 0 and string.format(" — %d with issues", issues) or ""
        )
    elseif inGroup then
        statusLine = "In a group — open Group Check to scan members."
    end

    local subtitle = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontHighlight",
        statusLine, "TOP", 0, -5)
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -8)
    subtitle:SetWidth(520)
    subtitle:SetJustifyH("CENTER")

    local personalButton = UIHelpers.createButton(parentFrame, "Check My Gear", 180, 32)
    personalButton:SetPoint("TOP", subtitle, "BOTTOM", -100, -30)
    personalButton:SetScript("OnClick", function()
        NavigationManager.showContent("personal_gear", UnifiedUI.contentFrame)
        if UnifiedUI.navButtons and UnifiedUI.navButtons.personal_gear then
            NavigationManager.updateButtonStates(UnifiedUI.navButtons.personal_gear, UnifiedUI.navButtons)
        end
    end)

    local groupButton = UIHelpers.createButton(parentFrame, "Check Group", 180, 32)
    groupButton:SetPoint("TOP", subtitle, "BOTTOM", 100, -30)
    groupButton:SetScript("OnClick", function()
        NavigationManager.showContent("group_validation", UnifiedUI.contentFrame)
        if UnifiedUI.navButtons and UnifiedUI.navButtons.group_validation then
            NavigationManager.updateButtonStates(UnifiedUI.navButtons.group_validation, UnifiedUI.navButtons)
        end
    end)

    local tip = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontDisableSmall",
        "Tip: from Group Check, announce results to chat or right-click a player to whisper their issues.",
        "TOP", 0, -5)
    tip:SetPoint("TOP", personalButton, "BOTTOM", 100, -24)
    tip:SetWidth(520)
    tip:SetJustifyH("CENTER")
    
    local version = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontDisableSmall",
        "Mr. Mythical: Gear Check by Braunerr", "BOTTOM", 0, UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    UIHelpers.setTextColor(version, "DISABLED")
end

function UIContentCreators.personal_gear(parentFrame)
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS then
        return
    end
    
    local title = UIHelpers.createTitle(parentFrame, "Personal Gear Check",
        "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING, 400)

    local pad = UI_CONSTANTS.LAYOUT.LARGE_PADDING
    local refreshButton = UIHelpers.createButton(parentFrame, "Refresh Check", 120, 25)
    refreshButton:SetPoint("BOTTOMRIGHT", -pad, pad)

    -- Leave room above the refresh button so the scrollbar doesn't overlap it
    local scrollBottom = pad + 25 + 8
    local scrollFrame, scrollChild = UIHelpers.createScrollFrame(parentFrame,
        UI_CONSTANTS.FRAME.CONTENT_WIDTH - 40, 1,
        pad, -60)
    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT", pad, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -pad, scrollBottom)

    local analysisText = UIHelpers.createFontString(scrollChild, "OVERLAY", "GameFontNormal",
        "Loading gear check...", "TOPLEFT", 10, -10)
    analysisText:SetWidth(UI_CONSTANTS.FRAME.CONTENT_WIDTH - 80)
    analysisText:SetJustifyH("LEFT")
    analysisText:SetJustifyV("TOP")

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
    if scrollFrame._UpdateScrollRange then
        scrollFrame:_UpdateScrollRange()
    end
end

function UIContentCreators.group_validation(parentFrame)
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS then
        return
    end
    
    local title = UIHelpers.createTitle(parentFrame, "Group Gear Validation",
        "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING, 400)

    local hint = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontDisableSmall",
        "Click a player for details. Right-click to whisper. Announce posts a summary to party/raid.", "TOP", 0, -5)
    hint:SetPoint("TOP", title, "BOTTOM", 0, -2)
    
    local Lib = LibStub and LibStub("LibMrMythicalUI-1.0", true)
    local controlPanel
    if Lib then
        controlPanel = CreateFrame("Frame", nil, parentFrame)
        local bg = Lib:CreateColorTexture(controlPanel, Lib.Theme.COLORS.NAV_BACKGROUND, "BACKGROUND")
        bg:SetAllPoints()
    else
        controlPanel = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
        controlPanel:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        controlPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    end
    controlPanel:SetPoint("TOP", hint, "BOTTOM", 0, -8)
    controlPanel:SetSize(UI_CONSTANTS.FRAME.CONTENT_WIDTH - 40, 95)    
    local scanButton = UIHelpers.createButton(controlPanel, "Fresh Scan", 95, 28)
    scanButton:SetPoint("TOPLEFT", controlPanel, "TOPLEFT", 10, -10)
    
    local pauseButton = UIHelpers.createButton(controlPanel, "Pause", 70, 28)
    pauseButton:SetPoint("LEFT", scanButton, "RIGHT", 6, 0)
    pauseButton:Disable()
    
    local rescanButton = UIHelpers.createButton(controlPanel, "Retry Failed", 100, 28)
    rescanButton:SetPoint("LEFT", pauseButton, "RIGHT", 6, 0)
    rescanButton:Disable()
    
    local refreshButton = UIHelpers.createButton(controlPanel, "Refresh Members", 110, 28)
    refreshButton:SetPoint("LEFT", rescanButton, "RIGHT", 6, 0)
    refreshButton:SetScript("OnClick", function()
        UIContentCreators.refreshGroupData(parentFrame.uiElements)
    end)
    
    local progressBar = UIHelpers.createStatusBar(controlPanel, 120, 18, false)
    progressBar:ClearAllPoints()
    progressBar:SetPoint("LEFT", refreshButton, "RIGHT", 12, 0)
    progressBar:SetPoint("RIGHT", controlPanel, "RIGHT", -10, 0)
    progressBar:SetHeight(18)
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(0)
    
    local progressText = UIHelpers.createFontString(progressBar, "OVERLAY", "GameFontNormalSmall",
        "Ready", "CENTER", 0, 0)

    local announceButton = UIHelpers.createButton(controlPanel, "Announce", 95, 28)
    announceButton:SetPoint("TOPLEFT", scanButton, "BOTTOMLEFT", 0, -8)

    local whisperButton = UIHelpers.createButton(controlPanel, "Whisper Selected", 120, 28)
    whisperButton:SetPoint("LEFT", announceButton, "RIGHT", 6, 0)
    whisperButton:Disable()

    local sortButton = UIHelpers.createButton(controlPanel, "Sort: Issues First", 150, 28)
    sortButton:SetPoint("LEFT", whisperButton, "RIGHT", 6, 0)

    local filterButton = UIHelpers.createButton(controlPanel, "Filter: All Players", 160, 28)
    filterButton:SetPoint("LEFT", sortButton, "RIGHT", 6, 0)
    
    -- Create scroll frame for checking results
    local scrollFrame, scrollChild = UIHelpers.createScrollFrame(parentFrame, 
        UI_CONSTANTS.FRAME.CONTENT_WIDTH - 40, 270, 
        UI_CONSTANTS.LAYOUT.LARGE_PADDING, -175)
    
    local analysisText = UIHelpers.createFontString(scrollChild, "OVERLAY", "GameFontNormal",
        "", "TOPLEFT", 10, -10)
    analysisText:SetWidth(UI_CONSTANTS.FRAME.CONTENT_WIDTH - 80)
    analysisText:SetJustifyH("LEFT")
    analysisText:SetJustifyV("TOP")
    
    local uiElements = {
        scanButton = scanButton,
        pauseButton = pauseButton,
        rescanButton = rescanButton,
        refreshButton = refreshButton,
        announceButton = announceButton,
        whisperButton = whisperButton,
        sortButton = sortButton,
        filterButton = filterButton,
        progressBar = progressBar,
        progressText = progressText,
        analysisText = analysisText,
        scrollChild = scrollChild,
        scrollFrame = scrollFrame,
        memberFrames = {},
        sortMode = "issues_first",
        filterMode = "all",
        selectedMemberFrame = nil,
        lastMemberReports = nil,
    }

    announceButton:SetScript("OnClick", function()
        UIContentCreators.announceGroupResults(uiElements)
    end)
    whisperButton:SetScript("OnClick", function()
        UIContentCreators.whisperSelectedMember(uiElements)
    end)
    sortButton:SetScript("OnClick", function()
        UIContentCreators.cycleSortMode(uiElements)
    end)
    filterButton:SetScript("OnClick", function()
        UIContentCreators.cycleFilterMode(uiElements)
    end)
    
    UIContentCreators.initializeGroupMemberDisplay(uiElements)
    UIContentCreators.setupGroupValidationHandlers(uiElements)
    parentFrame.uiElements = uiElements
    
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if InspectionUtils then
        local status = InspectionUtils:GetInspectionStatus()
        if status and status.memberReports and #status.memberReports > 0 then
            uiElements.lastMemberReports = status.memberReports
            UIContentCreators.refreshMemberListDisplay(uiElements)
            UIContentCreators.updateGroupValidationState(uiElements, "completed")
            UIContentCreators.setAnalysisMessage(uiElements,
                "Scan results loaded. Click a player for details, or Announce to party/raid.")
            return
        end
    end
    
    UIContentCreators.updateGroupValidationState(uiElements, "ready")
end

function UIContentCreators.refreshGroupData(uiElements)
    if not uiElements then return end

    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if InspectionUtils then
        local status = InspectionUtils:GetInspectionStatus()
        if status and status.memberReports then
            uiElements.lastMemberReports = status.memberReports
        end
    end

    UIContentCreators.refreshMemberListDisplay(uiElements)

    local InspectionUtils2 = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if InspectionUtils2 then
        local status = InspectionUtils2:GetInspectionStatus()
        if status and status.memberReports and #status.memberReports > 0 then
            UIContentCreators.updateGroupValidationState(uiElements, "completed")
        end
    end
end

-- Group checking control handlers
function UIContentCreators.setupGroupValidationHandlers(uiElements)
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if not InspectionUtils then return end
    
    -- Fresh Scan button - always does a complete fresh scan
    uiElements.scanButton:SetScript("OnClick", function()
        -- Check if in combat
        if InCombatLockdown() then
            UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Cannot scan while you are in combat.|r")
            return
        end
        
        if not IsInGroup() and not IsInRaid() then
            UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Join a party or raid before starting a group scan.|r")
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
            UIContentCreators.setAnalysisMessage(uiElements, "Scan paused. Click Resume to continue.")
        else -- Resume
            -- Clear pause flag and continue scanning
            uiElements.scanPaused = false
            UIContentCreators.updateGroupValidationState(uiElements, "scanning")
            UIContentCreators.setAnalysisMessage(uiElements, "Resuming scan...")
            -- Note: The scanning will continue on the next timer tick
        end
    end)
    
    -- Retry Failed button - only retries failed inspections
    uiElements.rescanButton:SetScript("OnClick", function()
        -- Check if in combat
        if InCombatLockdown() then
            UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Cannot retry while you are in combat.|r")
            return
        end
        
        -- Check if there are failed inspections to retry
        local status = InspectionUtils:GetInspectionStatus()
        if status.failedCount == 0 then
            UIContentCreators.setAnalysisMessage(uiElements, "No failed inspections to retry.")
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
    local InspectionUnits = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUnits
    if not InspectionUtils then
        UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Inspection module unavailable.|r")
        return
    end

    local function fullNameFor(unit)
        if InspectionUnits and InspectionUnits.GetUnitFullName then
            return InspectionUnits:GetUnitFullName(unit) or UnitName(unit) or "Unknown"
        end
        return UnitName(unit) or "Unknown"
    end

    local function inspectFailureReason(unit)
        -- Important: nil means "ok to attempt inspect". Do not coerce nil into a failure string.
        if InspectionUnits and InspectionUnits.GetInspectFailureReason then
            return InspectionUnits:GetInspectFailureReason(unit)
        end
        if unit ~= "player" and UnitExists(unit) and not CanInspect(unit) then
            if CheckInteractDistance and not CheckInteractDistance(unit, 1) then
                return "Out of inspect range"
            end
        end
        return nil
    end

    -- Clear scan state for current group members (fresh scan)
    InspectionUtils:ClearGroupScanState()
    
    -- Clear WoW's inspection cache for fresh scan
    InspectionUtils:ClearInspectionState()
    
    -- Reset member frames to "Not scanned" status
    for _, memberFrame in ipairs(uiElements.memberFrames) do
        memberFrame.details = nil
        memberFrame.reportSummary = nil
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
        UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000No group members found to scan.|r")
        UIContentCreators.updateGroupValidationState(uiElements, "ready")
        return
    end

    UIContentCreators.setAnalysisMessage(uiElements, "Scanning group... Click a player after the scan to view details.")
    
    -- Reset progress bar and pause flag
    UIContentCreators.updateProgress(uiElements, 0, totalMembers)
    uiElements.scanPaused = false
    
    local scannedCount = 0
    local results = {
        totalMembers = totalMembers,
        inspectedMembers = 0,
        memberReports = {}
    }

    local function storeFailure(unit, name, reason)
        InspectionUtils.groupScanState[name] = {
            hasData = false,
            summary = "Failed - " .. reason,
            reason = reason,
            timestamp = time()
        }

        table.insert(results.memberReports, {
            name = name,
            unit = unit,
            summary = "Failed - " .. reason,
            reason = reason,
            hasData = false
        })

        UIContentCreators.updateMemberStatus(uiElements, unit, "failed", reason)
    end

    local function storeSuccess(unit, name, summary, details, gearInfo)
        results.inspectedMembers = results.inspectedMembers + 1

        InspectionUtils.groupScanState[name] = {
            hasData = true,
            summary = summary or "Analysis completed",
            details = details,
            gearInfo = gearInfo,
            timestamp = time()
        }

        table.insert(results.memberReports, {
            name = name,
            unit = unit,
            summary = summary or "Analysis completed",
            details = details,
            hasData = true
        })

        UIContentCreators.updateMemberStatus(uiElements, unit, "success", summary or "Complete", details)
    end
    
    -- Function to scan a single member
    local function scanMember(index)
        if index > totalMembers then
            -- All members scanned, show final results
            uiElements.lastMemberReports = results.memberReports
            UIContentCreators.refreshMemberListDisplay(uiElements)
            UIContentCreators.showGroupScanResults(uiElements, results)
            UIContentCreators.setAnalysisMessage(uiElements,
                "Group scan finished. Click a player for details, Announce to chat, or right-click to whisper.")
            return
        end

        if InCombatLockdown() then
            UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Scan waiting - you are in combat.|r")
            uiElements.scanPaused = true
            UIContentCreators.updateGroupValidationState(uiElements, "paused")
            C_Timer.After(0.5, function()
                if InCombatLockdown() or uiElements.scanPaused then
                    scanMember(index)
                else
                    UIContentCreators.updateGroupValidationState(uiElements, "scanning")
                    scanMember(index)
                end
            end)
            return
        end
        
        -- If paused, wait and try again
        if uiElements.scanPaused then
            C_Timer.After(0.5, function()
                scanMember(index)
            end)
            return
        end
        
        local unit = groupMembers[index]
        if not UnitExists(unit) then
            storeFailure(unit, "Unknown", "Player left the group")
            scannedCount = scannedCount + 1
            UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
            C_Timer.After(0.5, function()
                scanMember(index + 1)
            end)
            return
        end

        local name = fullNameFor(unit)
        
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
            local summary, details = InspectionUtils:CreatePlayerSummary(unit, name, gearInfo)
            if not summary then
                uiElements.memberLoadRetryCount = uiElements.memberLoadRetryCount or {}
                local loadTries = (uiElements.memberLoadRetryCount[index] or 0) + 1
                uiElements.memberLoadRetryCount[index] = loadTries
                if loadTries <= 8 then
                    UIContentCreators.updateMemberStatus(uiElements, unit, "scanning", "Loading items...")
                    C_Timer.After(0.35, function()
                        scanMember(index)
                    end)
                    return
                end
                -- Fall through to inspect/retry path rather than publishing a partial snapshot.
                gearInfo = nil
            else
                storeSuccess(unit, name, summary, details, gearInfo)
                
                scannedCount = scannedCount + 1
                UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
                
                C_Timer.After(0.5, function()
                    scanMember(index + 1)
                end)
                return
            end
        end

        if not gearInfo then
            local reason = inspectFailureReason(unit)
            if reason then
                storeFailure(unit, name, reason)
                
                scannedCount = scannedCount + 1
                UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
                
                C_Timer.After(0.5, function()
                    scanMember(index + 1)
                end)
                return
            end
            
            -- Request inspection (NotifyInspect preferred; falls back to InspectUnit)
            UIContentCreators.updateMemberStatus(uiElements, unit, "scanning", "Inspecting...")
            local notify = rawget(_G, "NotifyInspect")
            local success, errorMsg
            if type(notify) == "function" then
                success, errorMsg = pcall(notify, unit)
            else
                success, errorMsg = pcall(InspectUnit, unit)
            end
            
            if not success then
                storeFailure(unit, name, "Inspection request failed" .. (errorMsg and (": " .. tostring(errorMsg)) or ""))
                
                scannedCount = scannedCount + 1
                UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
                
                C_Timer.After(0.5, function()
                    scanMember(index + 1)
                end)
                return
            end
            
            -- Set up exponential backoff for inspection delay
            local memberRetryCount = 0
            local memberMaxRetries = 8
            local memberBaseDelay = 0.4 -- Starting delay in seconds
            
            local function attemptMemberInspectionCheck()
                if InCombatLockdown() then
                    UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Scan waiting - you are in combat.|r")
                    uiElements.scanPaused = true
                    UIContentCreators.updateGroupValidationState(uiElements, "paused")
                    C_Timer.After(0.5, function()
                        attemptMemberInspectionCheck()
                    end)
                    return
                end

                if uiElements.scanPaused then
                    C_Timer.After(0.5, function()
                        attemptMemberInspectionCheck()
                    end)
                    return
                end

                if not UnitExists(unit) then
                    storeFailure(unit, name, "Player left the group")
                    scannedCount = scannedCount + 1
                    UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
                    C_Timer.After(0.5, function()
                        scanMember(index + 1)
                    end)
                    return
                end

                memberRetryCount = memberRetryCount + 1
                
                local retryGearInfo = MrMythicalGearCheck.GearUtils:GetUnitGear(unit)
                local summary, details
                if retryGearInfo then
                    summary, details = InspectionUtils:CreatePlayerSummary(unit, name, retryGearInfo)
                end

                if retryGearInfo and summary then
                    storeSuccess(unit, name, summary, details, retryGearInfo)

                    scannedCount = scannedCount + 1
                    UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
                    
                    C_Timer.After(0.5, function()
                        scanMember(index + 1)
                    end)
                elseif memberRetryCount < memberMaxRetries then
                    -- Re-request inspect periodically in case the first notify was dropped.
                    if memberRetryCount == 3 and type(notify) == "function" then
                        pcall(notify, unit)
                    end
                    local delay = memberBaseDelay * (2 ^ math.min(memberRetryCount - 1, 3))
                    
                    C_Timer.After(delay, function()
                        attemptMemberInspectionCheck()
                    end)
                else
                    local finalReason = "Timed out waiting for inspect data"
                    if CheckInteractDistance and not CheckInteractDistance(unit, 1) then
                        finalReason = "Out of inspect range"
                    elseif not CanInspect(unit) then
                        finalReason = "Cannot inspect this player"
                    end
                    storeFailure(unit, name, finalReason)
                    
                    scannedCount = scannedCount + 1
                    UIContentCreators.updateProgress(uiElements, scannedCount, totalMembers)
                    
                    C_Timer.After(0.5, function()
                        scanMember(index + 1)
                    end)
                end
            end
            
            -- Start the first check after initial delay
            C_Timer.After(memberBaseDelay, function()
                attemptMemberInspectionCheck()
            end)
        end
    end
    
    -- Start scanning the first member
    scanMember(1)
end

function UIContentCreators.startRescan(uiElements)
    local InspectionUtils = MrMythicalGearCheck and MrMythicalGearCheck.InspectionUtils
    if not InspectionUtils then
        UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Inspection module unavailable.|r")
        return
    end

    if InCombatLockdown() then
        UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000Cannot retry while you are in combat.|r")
        UIContentCreators.updateGroupValidationState(uiElements, "completed")
        return
    end

    -- Check if there are failed inspections to retry
    local status = InspectionUtils:GetInspectionStatus()
    if status.failedCount == 0 then
        UIContentCreators.setAnalysisMessage(uiElements, "No failed inspections to retry.")
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
            if updatedStatus and updatedStatus.memberReports then
                uiElements.lastMemberReports = updatedStatus.memberReports
            end
            UIContentCreators.refreshMemberListDisplay(uiElements)
            UIContentCreators.showInspectionStatus(uiElements, updatedStatus)
            UIContentCreators.updateGroupValidationState(uiElements, "completed")
            UIContentCreators.setAnalysisMessage(uiElements,
                "Retry finished. Click a player for details, or Announce to party/raid.")
        end,
        function(progress)
            -- Progress callback
            if progress.type == "rescan_complete" or progress.type == "character_complete" or progress.type == "rescan_failed" then
                completedRescans = completedRescans + 1
                UIContentCreators.updateProgress(uiElements, completedRescans, totalToRescan)
                
                -- Update member frame for this player
                local status = InspectionUtils:GetInspectionStatus()
                UIContentCreators.updateMemberFramesWithResults(uiElements, status.memberReports)
            elseif progress.type == "error" and progress.message then
                UIContentCreators.setAnalysisMessage(uiElements, "|cffff8000" .. progress.message .. "|r")
            end
        end
    )
end

local MainFrameManager = {}

local function getUILib()
    return LibStub and LibStub("LibMrMythicalUI-1.0", true) or nil
end

function MainFrameManager.createUnifiedFrame()
    local UI_CONSTANTS = getUIConstants()
    local Lib = getUILib()
    local frame

    if Lib then
        frame = Lib:CreatePanel(UIParent, {
            name = "MrMythicalGearCheckUnifiedFrame",
            title = "Mr. Mythical: Gear Check",
            width = UI_CONSTANTS.FRAME.WIDTH,
            height = UI_CONSTANTS.FRAME.HEIGHT,
            movable = true,
            frameStrata = "DIALOG",
        })
        frame:SetFrameLevel(100)

        local close = Lib:CreateCloseButton(frame, function()
            UnifiedUI:Hide()
        end)
        close:SetPoint("TOPRIGHT", -8, -8)
        frame.CloseButton = close
    else
        frame = CreateFrame("Frame", "MrMythicalGearCheckUnifiedFrame", UIParent, "BackdropTemplate")
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
    end

    if not frame:GetPoint() then
        frame:SetPoint("CENTER")
    end

    MainFrameManager.setupFrameBehavior(frame)
    frame:Hide()

    return frame
end

function MainFrameManager.setupFrameBehavior(frame)
    local Lib = getUILib()
    if Lib and Lib.RegisterMovable then
        Lib:RegisterMovable(frame, {
            get = function()
                MrMythicalGearCheckDB = MrMythicalGearCheckDB or {}
                local pos = MrMythicalGearCheckDB.framePosition
                if not pos or not pos.point then
                    return nil
                end
                return {
                    point = pos.point,
                    relativePoint = pos.relativePoint or pos.point,
                    x = pos.xOffset or pos.x or 0,
                    y = pos.yOffset or pos.y or 0,
                }
            end,
            set = function(pos)
                MrMythicalGearCheckDB = MrMythicalGearCheckDB or {}
                MrMythicalGearCheckDB.framePosition = {
                    point = pos.point,
                    relativePoint = pos.relativePoint or pos.point,
                    xOffset = pos.x or 0,
                    yOffset = pos.y or 0,
                }
            end,
        })
        if not frame:GetPoint() then
            frame:SetPoint("CENTER")
        end
    else
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            MainFrameManager.saveFramePosition(frame)
        end)
    end
    
    frame:EnableKeyboard(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            frame:Hide()
            return
        end
        if self.SetPropagateKeyboardInput and not InCombatLockdown() then
            self:SetPropagateKeyboardInput(true)
        end
    end)
end

function MainFrameManager.createNavigationPanel(parentFrame)
    local UI_CONSTANTS = getUIConstants()
    local Lib = getUILib()

    local navPanel
    if Lib then
        navPanel = CreateFrame("Frame", nil, parentFrame)
        navPanel:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.PADDING, -40)
        navPanel:SetSize(UI_CONSTANTS.FRAME.NAV_PANEL_WIDTH, UI_CONSTANTS.FRAME.HEIGHT - 50)
        local bg = Lib:CreateColorTexture(navPanel, Lib.Theme.COLORS.NAV_BACKGROUND, "BACKGROUND")
        bg:SetAllPoints()
    else
        navPanel = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
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
    end

    return navPanel
end

function MainFrameManager.createContentFrame(parentFrame)
    local UI_CONSTANTS = getUIConstants()

    local contentFrame = CreateFrame("Frame", nil, parentFrame)
    contentFrame:SetPoint("TOPLEFT", UI_CONSTANTS.FRAME.NAV_PANEL_WIDTH + UI_CONSTANTS.LAYOUT.PADDING * 2, -40)
    contentFrame:SetSize(UI_CONSTANTS.FRAME.CONTENT_WIDTH, UI_CONSTANTS.FRAME.HEIGHT - 50)
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
    
    for _, buttonInfo in ipairs(NavigationManager.getButtonData()) do
        local button = NavigationManager.createNavigationButton(navPanel, buttonInfo, contentFrame, navButtons)
        navButtons[buttonInfo.id] = button
    end
    
    return navButtons
end

function NavigationManager.createNavigationButton(navPanel, buttonInfo, contentFrame, navButtons)
    local UI_CONSTANTS = getUIConstants()
    local Lib = getUILib()
    local button

    if Lib then
        button = Lib:CreateNavTab(navPanel, {
            text = buttonInfo.text,
            id = buttonInfo.id,
            width = 120,
            height = UI_CONSTANTS.LAYOUT.BUTTON_HEIGHT,
            selected = false,
        })
        button:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.PADDING, buttonInfo.y)
    else
        button = CreateFrame("Button", nil, navPanel, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.PADDING, buttonInfo.y)
        button:SetSize(120, UI_CONSTANTS.LAYOUT.BUTTON_HEIGHT)
        button:SetText(buttonInfo.text)
    end

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
    local Lib = getUILib()
    for _, button in pairs(navButtons) do
        if Lib and button.SetSelected then
            button:SetSelected(button == activeButton)
        else
            button:SetNormalFontObject(button == activeButton and "GameFontHighlight" or "GameFontNormal")
        end
    end
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

local function getDefaultContentType()
    if IsInGroup() or IsInRaid() then
        return "group_validation"
    end
    return "personal_gear"
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
    
    if not unifiedFrame.CloseButton then
        local closeButton = CreateFrame("Button", nil, unifiedFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", -5, -5)
        closeButton:SetScript("OnClick", function()
            UnifiedUI:Hide()
        end)
    end
    
    -- Default to Group Check when grouped, otherwise Personal Gear
    local defaultContent = getDefaultContentType()
    NavigationManager.showContent(defaultContent, contentFrame)
    if navButtons[defaultContent] then
        NavigationManager.updateButtonStates(navButtons[defaultContent], navButtons)
    end
end

-- Schedule UI initialization for after addon load
C_Timer.After(0.1, initializeUI)

function MainFrameManager.saveFramePosition(frame)
    if frame.SaveLibPosition then
        frame:SaveLibPosition()
        return
    end
    MrMythicalGearCheckDB = MrMythicalGearCheckDB or {}
    local point, relativeTo, relativePoint, xOffset, yOffset = frame:GetPoint()
    MrMythicalGearCheckDB.framePosition = {
        point = point,
        relativePoint = relativePoint,
        xOffset = xOffset,
        yOffset = yOffset
    }
end

function MainFrameManager.restoreFramePosition(frame)
    if frame.RestoreLibPosition and frame:RestoreLibPosition() then
        return
    end
    MrMythicalGearCheckDB = MrMythicalGearCheckDB or {}
    if MrMythicalGearCheckDB.framePosition then
        local pos = MrMythicalGearCheckDB.framePosition
        if pos.point and pos.relativePoint and pos.xOffset and pos.yOffset then
            frame:ClearAllPoints()
            frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOffset, pos.yOffset)
        end
    end
end

function UnifiedUI:Show(contentType)
    local UIHelpers = getUIHelpers()
    local UI_CONSTANTS = getUIConstants()
    
    if not UIHelpers or not UI_CONSTANTS or not self.unifiedFrame then
        return
    end
    
    MainFrameManager.restoreFramePosition(self.unifiedFrame)
    self.unifiedFrame:Show()

    local target = contentType
    if not target or target == "dashboard" then
        target = getDefaultContentType()
    end

    NavigationManager.showContent(target, self.contentFrame)
    if self.navButtons and self.navButtons[target] then
        NavigationManager.updateButtonStates(self.navButtons[target], self.navButtons)
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
