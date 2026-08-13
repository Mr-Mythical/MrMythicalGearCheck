--[[
TooltipUtils.lua - Mr. Mythical Gear Check Tooltip Utilities

Purpose: Functions for scanning item tooltips for various information
Dependencies: None
Author: Braunerr
--]]

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

    local function normalizeTooltipText(text)
        -- Strip texture tags and color codes so matching works consistently.
        local cleaned = text:gsub("|T.-|t", "")
            :gsub("|c%x%x%x%x%x%x%x%x", "")
            :gsub("|r", "")
            :gsub("^%s+", "")
            :gsub("%s+$", "")
        return string.lower(cleaned)
    end

    for i = 1, tooltip:NumLines() do
        local line = _G["MrMythicalSocketTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                local normalizedText = normalizeTooltipText(text)
                for _, keyword in ipairs(socketKeywords) do
                    local normalizedKeyword = string.lower(keyword)
                    if normalizedKeyword ~= "" and normalizedText:find(normalizedKeyword, 1, true) then
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

--- Returns the item equip location (INVTYPE_*), language-independent.
--- @param itemLink string Item link to inspect
--- @return string|nil
function TooltipUtils.getEquipLocation(itemLink)
    if not itemLink then
        return nil
    end

    local equipLoc
    if C_Item and C_Item.GetItemInfo then
        local ok, result = pcall(function()
            return select(9, C_Item.GetItemInfo(itemLink))
        end)
        if ok then
            equipLoc = result
        end
    end
    if not equipLoc and GetItemInfo then
        equipLoc = select(9, GetItemInfo(itemLink))
    end

    return equipLoc
end

--- Returns true when the off-hand item should not be enchant-checked
--- (held-in-off-hand or shield). Uses equip location so this works on every client language.
--- @param itemLink string Item link to inspect
--- @return boolean
function TooltipUtils.scanTooltipForOffHandType(itemLink)
    local equipLoc = TooltipUtils.getEquipLocation(itemLink)
    return equipLoc == "INVTYPE_HOLDABLE" or equipLoc == "INVTYPE_SHIELD"
end

local function tooltipLineHasEmbellish(text)
    if not text or text == "" then
        return false
    end
    return string.lower(text):find("embellish", 1, true) ~= nil
end

--- Returns true when the item is Unique-Equipped: Embellished (or tooltip says so).
--- @param itemLink string
--- @return boolean
function TooltipUtils.IsEmbellished(itemLink)
    if not itemLink then
        return false
    end

    local itemID
    if C_Item and C_Item.GetItemInfoInstant then
        itemID = C_Item.GetItemInfoInstant(itemLink)
    end
    if not itemID then
        itemID = tonumber(itemLink:match("item:(%d+)"))
    end

    if itemID and C_Item and C_Item.GetItemUniquenessByID then
        local ok, uniqueEquipped, maxCount, category = pcall(C_Item.GetItemUniquenessByID, itemID)
        if ok then
            if type(uniqueEquipped) == "string" and tooltipLineHasEmbellish(uniqueEquipped) then
                return true
            end
            if type(maxCount) == "string" and tooltipLineHasEmbellish(maxCount) then
                return true
            end
            if type(category) == "string" and tooltipLineHasEmbellish(category) then
                return true
            end
        end
    end

    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, itemLink)
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                if tooltipLineHasEmbellish(line.leftText) or tooltipLineHasEmbellish(line.rightText) then
                    return true
                end
            end
        end
    end

    if not _G["MrMythicalEmbellishTooltip"] then
        CreateFrame("GameTooltip", "MrMythicalEmbellishTooltip", nil, "GameTooltipTemplate")
    end
    local tooltip = _G["MrMythicalEmbellishTooltip"]
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetHyperlink(itemLink)

    for i = 1, tooltip:NumLines() do
        local left = _G["MrMythicalEmbellishTooltipTextLeft" .. i]
        local right = _G["MrMythicalEmbellishTooltipTextRight" .. i]
        if left and tooltipLineHasEmbellish(left:GetText()) then
            tooltip:Hide()
            return true
        end
        if right and tooltipLineHasEmbellish(right:GetText()) then
            tooltip:Hide()
            return true
        end
    end

    tooltip:Hide()
    return false
end

-- Export the module
MrMythicalGearCheck.TooltipUtils = TooltipUtils