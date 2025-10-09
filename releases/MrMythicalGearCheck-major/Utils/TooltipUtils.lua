--- TooltipUtils.lua - Tooltip scanning utilities for Mr. Mythical Gear Check
---
--- Purpose: Functions for scanning item tooltips for various information
--- Dependencies: None
--- Author: Braunerr

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.TooltipUtils = {}

local TooltipUtils = MrMythicalGearCheck.TooltipUtils

--- Scan item tooltip for socket information
--- @param itemLink string Item link to scan
--- @param socketKeywords table Array of keywords to search for
--- @return number Number of empty sockets found
function TooltipUtils.scanTooltipForSockets(itemLink, socketKeywords)
    if not itemLink or not socketKeywords then
        return 0
    end

    if not _G["MrMythicalSocketTooltip"] then
        CreateFrame("GameTooltip", "MrMythicalSocketTooltip", nil, "GameTooltipTemplate")
    end
    local tooltip = _G["MrMythicalSocketTooltip"]
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetHyperlink(itemLink)

    local emptySocketCount = 0

    for i = 1, tooltip:NumLines() do
        local line = _G["MrMythicalSocketTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                for _, keyword in ipairs(socketKeywords) do
                    if text:find(keyword) then
                        emptySocketCount = emptySocketCount + 1
                        break -- Only count once per line
                    end
                end
            end
        end
    end

    tooltip:Hide()
    return emptySocketCount
end

--- Scan item tooltip for off-hand related text
--- @param itemLink string Item link to scan
--- @return boolean True if item has any off-hand related text
function TooltipUtils.scanTooltipForOffHandType(itemLink)
    if not itemLink then
        return false
    end

    if not _G["MrMythicalScanTooltip"] then
        CreateFrame("GameTooltip", "MrMythicalScanTooltip", nil, "GameTooltipTemplate")
    end
    local tooltip = _G["MrMythicalScanTooltip"]
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetHyperlink(itemLink)

    for i = 1, tooltip:NumLines() do
        local line = _G["MrMythicalScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and (text:find("Held In Off%-hand") or text:find("Off Hand")) then
                tooltip:Hide()
                return true
            end
        end
    end
    tooltip:Hide()
    return false
end

-- Export the module
MrMythicalGearCheck.TooltipUtils = TooltipUtils