--[[
ReportUtils.lua - Group scan announce, whisper, and sort/filter helpers

Purpose: Build chat-safe gear reports and organize scan results for the UI.
Dependencies: InspectionUnits (optional)
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.ReportUtils = MrMythicalGearCheck.ReportUtils or {}

local ReportUtils = MrMythicalGearCheck.ReportUtils

local MAX_CHAT_LEN = 240
local ADDON_PREFIX = "MrMythical Gear Check"

local SORT_MODES = {
    issues_first = "Issues First",
    name = "Name",
    class = "Class",
    unscanned_first = "Unscanned First",
}

local FILTER_MODES = {
    all = "All Players",
    issues_only = "Has Issues",
    perfect_only = "Perfect",
    unscanned_only = "Not Scanned / Failed",
}

ReportUtils.SORT_MODES = SORT_MODES
ReportUtils.FILTER_MODES = FILTER_MODES

local function getInspectionUnits()
    return (_G.MrMythicalGearCheck and _G.MrMythicalGearCheck.InspectionUnits)
        or MrMythicalGearCheck.InspectionUnits
end

--- Strip WoW UI escape sequences for chat output
--- @param text string|nil
--- @return string
function ReportUtils:StripColorCodes(text)
    if not text or text == "" then
        return ""
    end

    local cleaned = tostring(text)
    cleaned = cleaned:gsub("|c%x%x%x%x%x%x%x%x", "")
    cleaned = cleaned:gsub("|r", "")
    cleaned = cleaned:gsub("|T.-|t", "")
    cleaned = cleaned:gsub("|A.-|a", "")
    cleaned = cleaned:gsub("|H.-|h(.-)|h", "%1")
    cleaned = cleaned:gsub("|n", " ")
    cleaned = cleaned:gsub("%s+", " ")
    return cleaned:match("^%s*(.-)%s*$") or cleaned
end

--- Short display name for chat (no realm when same-realm)
--- @param fullName string|nil
--- @return string
function ReportUtils:GetShortName(fullName)
    if not fullName or fullName == "" then
        return "Unknown"
    end
    if Ambiguate then
        return Ambiguate(fullName, "short")
    end
    return fullName:match("^([^%-]+)") or fullName
end

--- @param report table
--- @return number
function ReportUtils:GetIssueCount(report)
    if not report then
        return 0
    end
    if report.details and report.details.totalIssues then
        return tonumber(report.details.totalIssues) or 0
    end
    if report.hasData and report.summary and report.summary:find("PERFECT", 1, true) then
        return 0
    end
    if report.hasData then
        local count = report.summary and tonumber(report.summary:match("(%d+)%s+ISSUES"))
        return count or 0
    end
    return 0
end

--- @param report table
--- @return boolean
function ReportUtils:HasIssues(report)
    return report and report.hasData == true and self:GetIssueCount(report) > 0
end

--- @param report table
--- @return boolean
function ReportUtils:IsPerfect(report)
    return report and report.hasData == true and self:GetIssueCount(report) == 0
end

--- @param report table
--- @return boolean
function ReportUtils:IsUnscanned(report)
    return not report or report.hasData ~= true
end

local function getClassSortKey(report)
    if report and report.details and report.details.className then
        return string.lower(report.details.className)
    end
    if report and report.unit and UnitClass then
        local className = UnitClass(report.unit)
        if className then
            return string.lower(className)
        end
    end
    return "zzz"
end

--- Sort and filter member reports for display
--- @param reports table
--- @param sortMode string
--- @param filterMode string
--- @return table
function ReportUtils:SortAndFilterReports(reports, sortMode, filterMode)
    sortMode = sortMode or "issues_first"
    filterMode = filterMode or "all"

    local filtered = {}
    for _, report in ipairs(reports or {}) do
        local include = true
        if filterMode == "issues_only" then
            include = self:HasIssues(report)
        elseif filterMode == "perfect_only" then
            include = self:IsPerfect(report)
        elseif filterMode == "unscanned_only" then
            include = self:IsUnscanned(report)
        end
        if include then
            table.insert(filtered, report)
        end
    end

    table.sort(filtered, function(a, b)
        if sortMode == "name" then
            return self:GetShortName(a.name) < self:GetShortName(b.name)
        elseif sortMode == "class" then
            local classA = getClassSortKey(a)
            local classB = getClassSortKey(b)
            if classA ~= classB then
                return classA < classB
            end
            return self:GetIssueCount(b) < self:GetIssueCount(a)
        elseif sortMode == "unscanned_first" then
            local ua = self:IsUnscanned(a) and 0 or 1
            local ub = self:IsUnscanned(b) and 0 or 1
            if ua ~= ub then
                return ua < ub
            end
            return self:GetIssueCount(b) > self:GetIssueCount(a)
        else -- issues_first
            local ia = self:GetIssueCount(a)
            local ib = self:GetIssueCount(b)
            local ua = self:IsUnscanned(a)
            local ub = self:IsUnscanned(b)
            -- Scanned players with issues first, then unscanned, then perfect
            local rankA = ua and 1 or (ia > 0 and 0 or 2)
            local rankB = ub and 1 or (ib > 0 and 0 or 2)
            if rankA ~= rankB then
                return rankA < rankB
            end
            if ia ~= ib then
                return ia > ib
            end
            return self:GetShortName(a.name) < self:GetShortName(b.name)
        end
    end)

    return filtered
end

--- Build a plain-text issue list for whisper/announce
--- @param report table
--- @param maxItems number|nil
--- @return table array of plain strings
function ReportUtils:BuildIssueLines(report, maxItems)
    maxItems = maxItems or 8
    local lines = {}

    if not report then
        return { "No scan data available." }
    end

    if self:IsUnscanned(report) then
        table.insert(lines, report.reason or report.summary or "Not scanned")
        return lines
    end

    if self:IsPerfect(report) then
        table.insert(lines, "No gear issues detected.")
        return lines
    end

    local details = report.details
    if details and details.gearDetails then
        for _, detail in ipairs(details.gearDetails) do
            if #lines >= maxItems then
                local remaining = #details.gearDetails - maxItems
                if remaining > 0 then
                    table.insert(lines, string.format("(+%d more)", remaining))
                end
                break
            end
            local cleaned = self:StripColorCodes(detail)
            cleaned = cleaned:gsub("^%- ", "")
            if cleaned ~= "" then
                table.insert(lines, cleaned)
            end
        end
    end

    if #lines == 0 then
        local summary = self:StripColorCodes(report.summary or "Gear issues found")
        table.insert(lines, summary)
    end

    return lines
end

--- Build announce chat lines for the group
--- @param memberReports table
--- @return table array of chat-safe strings
function ReportUtils:BuildAnnounceLines(memberReports)
    local reports = memberReports or {}
    local withIssues = {}
    local perfect = 0
    local failed = 0
    local scanned = 0

    for _, report in ipairs(reports) do
        if self:IsUnscanned(report) then
            failed = failed + 1
        elseif self:IsPerfect(report) then
            perfect = perfect + 1
            scanned = scanned + 1
        elseif self:HasIssues(report) then
            scanned = scanned + 1
            table.insert(withIssues, report)
        else
            scanned = scanned + 1
        end
    end

    table.sort(withIssues, function(a, b)
        return self:GetIssueCount(a) > self:GetIssueCount(b)
    end)

    local lines = {}
    local total = #reports
    if #withIssues == 0 and failed == 0 then
        table.insert(lines, string.format("%s: all %d scanned players look good.", ADDON_PREFIX, scanned))
        return lines
    end

    table.insert(lines, string.format(
        "%s: %d/%d players have issues%s.",
        ADDON_PREFIX,
        #withIssues,
        total,
        failed > 0 and string.format(" (%d unscanned)", failed) or ""
    ))

    for _, report in ipairs(withIssues) do
        local shortName = self:GetShortName(report.name)
        local issueCount = self:GetIssueCount(report)
        local issueLines = self:BuildIssueLines(report, 3)
        local preview = table.concat(issueLines, "; ")
        local line = string.format("%s: %d issue%s - %s", shortName, issueCount, issueCount == 1 and "" or "s", preview)
        if #line > MAX_CHAT_LEN then
            line = line:sub(1, MAX_CHAT_LEN - 3) .. "..."
        end
        table.insert(lines, line)
    end

    return lines
end

--- Build whisper body for one player
--- @param report table
--- @return table array of chat-safe strings
function ReportUtils:BuildWhisperLines(report)
    local shortName = self:GetShortName(report and report.name)
    local lines = {}

    if self:IsUnscanned(report) then
        table.insert(lines, string.format("[%s] Could not scan your gear (%s).", ADDON_PREFIX, report.reason or "not scanned"))
        return lines
    end

    if self:IsPerfect(report) then
        table.insert(lines, string.format("[%s] Your gear looks good - no issues found.", ADDON_PREFIX))
        return lines
    end

    table.insert(lines, string.format("[%s] Gear issues found:", ADDON_PREFIX))
    for _, issue in ipairs(self:BuildIssueLines(report, 10)) do
        table.insert(lines, "- " .. issue)
    end

    return lines
end

local function sendChatLines(channel, lines, target)
    for _, line in ipairs(lines or {}) do
        local text = ReportUtils:StripColorCodes(line)
        if text ~= "" then
            if #text > MAX_CHAT_LEN then
                text = text:sub(1, MAX_CHAT_LEN - 3) .. "..."
            end
            if channel == "WHISPER" then
                SendChatMessage(text, "WHISPER", nil, target)
            else
                SendChatMessage(text, channel)
            end
        end
    end

    return true
end

--- Announce scan results to party or raid chat
--- @param memberReports table
--- @return boolean success
--- @return string|nil errorOrInfo
function ReportUtils:AnnounceToGroup(memberReports)
    if not IsInGroup() and not IsInRaid() then
        return false, "You are not in a party or raid."
    end

    local channel = IsInRaid() and "RAID" or "PARTY"
    local lines = self:BuildAnnounceLines(memberReports)
    local ok, err = sendChatLines(channel, lines)
    if not ok then
        return false, err
    end
    return true, string.format("Announced to %s (%d line%s).", string.lower(channel), #lines, #lines == 1 and "" or "s")
end

--- Whisper a player their gear issues
--- @param report table
--- @return boolean success
--- @return string|nil errorOrInfo
function ReportUtils:WhisperPlayerReport(report)
    if not report or not report.name then
        return false, "No player selected."
    end

    local target = report.name
    local InspectionUnits = getInspectionUnits()
    if report.unit and UnitIsUnit and UnitIsUnit(report.unit, "player") then
        return false, "Use Personal Gear for your own report."
    end

    -- Prefer Name-Realm for cross-realm whispers
    if report.unit and InspectionUnits and InspectionUnits.GetUnitFullName then
        target = InspectionUnits:GetUnitFullName(report.unit) or target
    end

    local lines = self:BuildWhisperLines(report)
    local ok, err = sendChatLines("WHISPER", lines, target)
    if not ok then
        return false, err
    end
    return true, string.format("Whispered %s.", self:GetShortName(target))
end

_G.MrMythicalGearCheck = MrMythicalGearCheck
