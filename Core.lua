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
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("SOCKET_INFO_UPDATE")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

local characterHooksAttached = false
local characterReportFrame
local characterReportText

-- Returns the frame whose right edge is the actual visible boundary of the
-- character panel.  Any addon that widens CharacterFrameBg (or a similar
-- child) beyond CharacterFrame itself will be detected automatically at
-- runtime — no addon-name checks required.
local function getCharacterFrameRightAnchor()
    if CharacterFrame and _G.CharacterFrameBg then
        local cfRight = CharacterFrame:GetRight()
        local bgRight = _G.CharacterFrameBg:GetRight()
        if cfRight and bgRight and bgRight > cfRight + 1 then
            return _G.CharacterFrameBg
        end
    end
    return CharacterFrame
end

local function ensureCharacterReportFrame()
    if not CharacterFrame then
        return false
    end

    if not characterReportFrame then
        local panel = CreateFrame("Frame", "MrMythicalGearCheckCharacterReportFrame", CharacterFrame)
        panel:SetSize(340, 370)

        local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
        text:SetWidth(330)
        -- Use a slightly larger non-default UI font for cleaner readability.
        text:SetFont("Fonts\\ARIALN.TTF", 13, "")
        text:SetText("Loading...")

        characterReportFrame = panel
        characterReportText = text
    end

    -- Re-anchor every call so changes made by other addons (e.g. ChonkyCharacterSheet
    -- widening CharacterFrameBg) are always reflected.
    characterReportFrame:ClearAllPoints()
    characterReportFrame:SetPoint("TOPLEFT", getCharacterFrameRightAnchor(), "TOPRIGHT", 10, -26)

    return true
end

local function refreshCharacterReport()
    local configData = _G.MrMythicalGearCheck and _G.MrMythicalGearCheck.ConfigData
    if configData and not configData:GetShowCharacterPanel() then
        if characterReportFrame then
            characterReportFrame:Hide()
        end
        return
    end

    if not CharacterFrame or not CharacterFrame:IsShown() then
        if characterReportFrame then
            characterReportFrame:Hide()
        end
        return
    end

    if not ensureCharacterReportFrame() then
        return
    end

    local gearUtils = _G.MrMythicalGearCheck and _G.MrMythicalGearCheck.GearUtils
    if not gearUtils or not gearUtils.GetPersonalGemEnchantIssuesReport then
        characterReportText:SetText("Gear report is unavailable.")
        characterReportFrame:Show()
        return
    end

    local success, report = pcall(gearUtils.GetPersonalGemEnchantIssuesReport, gearUtils)
    if not success or not report then
        characterReportText:SetText("Failed to build gear report.")
        characterReportFrame:Show()
        return
    end

    local lines = report.reportLines or { "No gear report available." }

    characterReportText:SetText(table.concat(lines, "\n"))
    characterReportFrame:Show()
end

local function attachCharacterFrameHooks()
    if characterHooksAttached then
        return
    end

    if not CharacterFrame then
        return
    end

    CharacterFrame:HookScript("OnShow", function()
        refreshCharacterReport()
    end)

    CharacterFrame:HookScript("OnHide", function()
        if characterReportFrame then
            characterReportFrame:Hide()
        end
    end)

    characterHooksAttached = true
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MrMythicalGearCheck" then
            if MrMythicalGearCheck.Options then
                MrMythicalGearCheck.Options.initializeSettings()
            end
        elseif addonName == "Blizzard_CharacterUI" then
            attachCharacterFrameHooks()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
        local loadAddOn = rawget(_G, "LoadAddOn")
        if isAddOnLoaded and loadAddOn and not isAddOnLoaded("Blizzard_CharacterUI") then
            pcall(loadAddOn, "Blizzard_CharacterUI")
        end
        attachCharacterFrameHooks()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "SOCKET_INFO_UPDATE" then
        refreshCharacterReport()
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if unit == "player" then
            refreshCharacterReport()
        end
    end
end)

_G.MrMythicalGearCheck = MrMythicalGearCheck
