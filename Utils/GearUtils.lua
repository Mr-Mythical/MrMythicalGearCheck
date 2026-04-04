--[[
GearUtils.lua - Mr. Mythical Gear Check Utilities

Purpose: Utilities for inspecting and analyzing player gear for validation
Dependencies: ConfigData, GearData, EnchantData, GemData, TooltipUtils
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.GearUtils = {}

local GearUtils = MrMythicalGearCheck.GearUtils

local function getDependency(name)
    return (_G.MrMythicalGearCheck and _G.MrMythicalGearCheck[name]) or MrMythicalGearCheck[name]
end

local function isDeathKnight(playerClass)
    if not playerClass then return false end
    local upperClass = string.upper(playerClass)
    return upperClass == "DEATHKNIGHT" or upperClass == "DEATH KNIGHT" or playerClass == "Death Knight"
end

local ISSUE_TYPES = {
    MISSING_ENCHANT = "MISSING_ENCHANT",
    LOW_RANK_ENCHANT = "LOW_RANK_ENCHANT",
    EMPTY_SOCKETS = "EMPTY_SOCKETS",
    LOW_DURABILITY = "LOW_DURABILITY",
    LOW_RANK_GEM = "LOW_RANK_GEM",
    SUBOPTIMAL_GEM = "SUBOPTIMAL_GEM",
    EMPTY_SLOT = "EMPTY_SLOT"
}

--- Helper function to check if a slot should be enchant-checked based on class and weapon setup
--- @param slotId number Equipment slot ID
--- @param playerClass string The class of the unit being analyzed
--- @return boolean True if slot should be checked for enchants
local function shouldCheckEnchant(slotId, playerClass)
    local config = getDependency("ConfigData")
    if not (config and config.CONSTANTS and config.CONSTANTS.ENCHANTABLE_SLOTS and
            config.CONSTANTS.ENCHANTABLE_SLOTS[slotId]) then
        return false
    end

    -- Wrist enchants are intentionally ignored for warning generation.
    local wristSlot = (config and config.CONSTANTS and config.CONSTANTS.SLOT_IDS and config.CONSTANTS.SLOT_IDS.WRIST) or 9
    if slotId == wristSlot then
        return false
    end

    return true
end

--- Gets display name for enchant quality
--- @param slotId number Equipment slot ID
--- @param isRequired boolean Whether this is for the "required" quality (true) or current quality (false)
--- @return string Display name
local function getQualityDisplayName(slotId, isRequired)
    return isRequired and "Premium Materials" or "Cheap Materials"
end

local EnchantValidationRule = {
    appliesTo = function(self, itemAnalysis, slotId, playerClass)
        if not shouldCheckEnchant(slotId, playerClass) then
            return false
        end

        -- Special handling for off-hand slot
        local config = getDependency("ConfigData")
        local offHandSlot = (config and config.CONSTANTS and config.CONSTANTS.SLOT_IDS and config.CONSTANTS.SLOT_IDS.OFF_HAND) or 17
        if slotId == offHandSlot and itemAnalysis and itemAnalysis.itemLink then
            local TooltipUtils = getDependency("TooltipUtils")
            if TooltipUtils and TooltipUtils.scanTooltipForOffHandType then
                local isOffHandRelated = TooltipUtils.scanTooltipForOffHandType(itemAnalysis.itemLink)
                if isOffHandRelated then
                    return false
                end
            end
        end

        return true
    end,

    validate = function(self, itemAnalysis, slotId, config, playerClass)
        local issues = {}

        -- Skip validation if no item analysis (empty slot)
        if not itemAnalysis then
            return issues
        end

        local weaponSlots = (config and config.CONSTANTS and config.CONSTANTS.WEAPON_SLOTS) or {}
        local enchantData = getDependency("EnchantData")
        local enchantId = itemAnalysis.enchant and itemAnalysis.enchant.id or 0

        -- Death Knights require rune enchants on weapon slots.
        if isDeathKnight(playerClass) and weaponSlots[slotId] then
            if enchantId == 0 then
                table.insert(issues, {
                    type = ISSUE_TYPES.MISSING_ENCHANT,
                    message = "Missing rune"
                })
            elseif enchantData and enchantData.IsDeathKnightRune and not enchantData:IsDeathKnightRune(enchantId) then
                table.insert(issues, {
                    type = ISSUE_TYPES.LOW_RANK_ENCHANT,
                    message = "Invalid Death Knight weapon enchant (expected a rune)"
                })
            end

            return issues
        end

        if not itemAnalysis.enchant or not itemAnalysis.enchant.id or itemAnalysis.enchant.id == 0 then
            table.insert(issues, {
                type = ISSUE_TYPES.MISSING_ENCHANT,
                message = "Missing enchant"
            })
        else
            if enchantData then
                local enchantInfo = enchantData:GetEnchantInfo(itemAnalysis.enchant.id)
                if enchantInfo then
                    local minRank = config:GetMinEnchantRank()
                    local requirePremium = config:RequirePremiumEnchants()

                    local hasRankIssue = enchantInfo.rank < minRank
                    local hasQualityIssue = requirePremium and enchantInfo.quality == "cheap"

                    if hasRankIssue or hasQualityIssue then
                        local message = ""

                        local gearData = getDependency("GearData")
                        local slotName = gearData and gearData.SLOT_NAMES and gearData.SLOT_NAMES[slotId] or
                        "Unknown Slot"

                        if hasRankIssue and hasQualityIssue then
                            message = "Low rank (rank " ..
                            enchantInfo.rank ..
                            "/" ..
                            minRank ..
                            ") and low quality (" ..
                            getQualityDisplayName(slotId, false) ..
                            ") upgrade to higher quality (" .. getQualityDisplayName(slotId, true) .. ") on " .. slotName
                        elseif hasRankIssue then
                            message = "Low rank enchant (rank " ..
                            enchantInfo.rank .. ", need " .. minRank .. ") on " .. slotName
                        elseif hasQualityIssue then
                            message = "Low quality (" ..
                            getQualityDisplayName(slotId, false) ..
                            ") upgrade to higher quality (" .. getQualityDisplayName(slotId, true) .. ") on " .. slotName
                        end

                        table.insert(issues, {
                            type = ISSUE_TYPES.LOW_RANK_ENCHANT,
                            message = message
                        })
                    end
                end
            end
        end

        return issues
    end
}

--- Gem validation rule
local GemValidationRule = {
    appliesTo = function(self, itemAnalysis, slotId)
        -- Only validate gem issues on items that actually have sockets.
        return itemAnalysis and itemAnalysis.sockets and itemAnalysis.sockets.total > 0
    end,

    validate = function(self, itemAnalysis, slotId, config)
        local issues = {}

        -- Skip validation if no item analysis (empty slot)
        if not itemAnalysis then
            return issues
        end

        -- Only warn about empty gem sockets if the item actually has sockets (not just based on slot type)
        if itemAnalysis.sockets and itemAnalysis.sockets.total > 0 then
            local emptyCount = itemAnalysis.sockets.total - itemAnalysis.sockets.filled
            if emptyCount > 0 then
                table.insert(issues, {
                    type = ISSUE_TYPES.EMPTY_SOCKETS,
                    message = emptyCount .. " empty gem socket" .. (emptyCount > 1 and "s" or "")
                })
            end
        end

        -- Check gem quality if we have gem data
        if itemAnalysis.gems then
            local minGemRank = config:GetMinGemRank() or 3
            local gearData = getDependency("GearData")
            local slotName = gearData and gearData.SLOT_NAMES and gearData.SLOT_NAMES[slotId] or "Unknown Slot"

            for _, gem in ipairs(itemAnalysis.gems) do
                local hasRankIssue = gem.rank and gem.rank > 0 and gem.rank < minGemRank
                local hasQualityIssue = gem.quality == "cheap"
                local warningText = gem.warning or ""
                local warningLower = string.lower(warningText)
                local hasSingleStatWarning = warningLower:find("single%-stat") ~= nil
                local hasSuboptimalIssue = warningText ~= "" and (not hasQualityIssue or hasSingleStatWarning)

                if hasRankIssue and hasQualityIssue then
                    table.insert(issues, {
                        type = ISSUE_TYPES.LOW_RANK_GEM,
                        message = "Low rank (rank " ..
                            gem.rank ..
                            "/" ..
                            minGemRank ..
                            ") and low quality (" ..
                            getQualityDisplayName(slotId, false) ..
                            ") upgrade to higher quality (" .. getQualityDisplayName(slotId, true) .. ") on " .. slotName
                    })
                elseif hasRankIssue then
                    table.insert(issues, {
                        type = ISSUE_TYPES.LOW_RANK_GEM,
                        message = "Low rank gem (rank " .. gem.rank .. ", need " .. minGemRank .. ") on " .. slotName
                    })
                elseif hasQualityIssue then
                    table.insert(issues, {
                        type = ISSUE_TYPES.SUBOPTIMAL_GEM,
                        message = "Low quality (" ..
                            getQualityDisplayName(slotId, false) ..
                            ") upgrade to higher quality (" .. getQualityDisplayName(slotId, true) .. ") on " .. slotName
                    })
                end

                if hasSuboptimalIssue then
                    table.insert(issues, {
                        type = ISSUE_TYPES.SUBOPTIMAL_GEM,
                        message = warningText
                    })
                end
            end
        end

        return issues
    end
}



--- Durability validation rule (global state tracking to show message only once)
local DurabilityValidationRule = {
    appliesTo = function(self, itemAnalysis)
        return itemAnalysis and itemAnalysis.durability ~= nil -- Apply to any item with durability info
    end,

    validate = function(self, itemAnalysis, slotId, config)
        local issues = {}
        
        if itemAnalysis.durability then
            local threshold = config:GetLowDurabilityThreshold()
            if itemAnalysis.durability.percentage < threshold then
                table.insert(issues, {
                    type = ISSUE_TYPES.LOW_DURABILITY,
                    message = "Low durability (" .. math.floor(itemAnalysis.durability.percentage) .. "%)"
                })
            end
        end
        
        return issues
    end
}

--- Empty slot validation rule 
local EmptySlotValidationRule = {
    appliesTo = function(self, itemAnalysis, slotId)
        -- Apply to empty slots, but skip off-hand as it's often intentionally empty
        local config = getDependency("ConfigData")
        local offHandSlot = (config and config.CONSTANTS and config.CONSTANTS.SLOT_IDS and config.CONSTANTS.SLOT_IDS.OFF_HAND) or 17
        return itemAnalysis == nil and slotId ~= offHandSlot
    end,

    validate = function(self, itemAnalysis, slotId, config)
        local issues = {}
        table.insert(issues, {
            type = ISSUE_TYPES.EMPTY_SLOT,
            message = "Empty equipment slot"
        })
        return issues
    end
}

--- Validation engine that applies rules without knowing their specifics
local ValidationEngine = {
    rules = {},

    --- Register a new validation rule
    --- @param rule table Validation rule that implements the ValidationRule interface
    registerRule = function(self, rule)
        table.insert(self.rules, rule)
    end,

    --- Validate an item using all applicable rules
    --- @param itemAnalysis table|nil Item analysis data (nil for empty slots)
    --- @param slotId number Equipment slot ID
    --- @param config table Configuration data
    --- @param playerClass string Player class name
    --- @return table Array of all issues found
    validateItem = function(self, itemAnalysis, slotId, config, playerClass)
        local allIssues = {}

        for _, rule in ipairs(self.rules) do
            if rule:appliesTo(itemAnalysis, slotId, playerClass) then
                local issues = rule:validate(itemAnalysis, slotId, config, playerClass)
                for _, issue in ipairs(issues) do
                    table.insert(allIssues, issue)
                end
            end
        end

        return allIssues
    end
}

-- Initialize the validation engine with default rules
ValidationEngine:registerRule(EnchantValidationRule)
ValidationEngine:registerRule(GemValidationRule)
ValidationEngine:registerRule(DurabilityValidationRule)
ValidationEngine:registerRule(EmptySlotValidationRule)



--- Gets item durability information
--- @param slot number Inventory slot
--- @return table|nil Durability information
function GearUtils:GetItemDurability(slot)
    local current, maximum = GetInventoryItemDurability(slot)
    if not current or not maximum then
        return nil
    end

    local percentage = (current / maximum) * 100

    return {
        current = current,
        maximum = maximum,
        percentage = percentage
    }
end

--- Unified gear analysis function that supports both basic and detailed modes
--- @param unit string Unit ID ("player", "party1", "target", etc.)
--- @param mode string "basic" for simple data collection, "detailed" for full analysis
--- @return table|nil Gear analysis results or nil if failed  
function GearUtils:AnalyzeGear(unit, mode)
    if not unit or not UnitExists(unit) then
        return nil
    end

    mode = mode or "basic"
    
    -- For non-player units, handle inspection
    if unit ~= "player" then
        if not self:CanInspectUnit(unit) then
            return nil
        end
        
        -- Trigger inspection if needed
        if not self:IsUnitInspected(unit) then
            self:RequestInspection(unit)
            return nil
        end
    end

    -- Get dependencies
    local ConfigData = getDependency("ConfigData")
    local GearData = getDependency("GearData")
    
    if not GearData or not GearData.SLOT_NAMES then
        return nil
    end

    -- Get player class
    local _, playerClass = UnitClass(unit)
    
    -- Initialize results based on mode
    local results = {}
    
    if mode == "basic" then
        results.playerClass = playerClass
    else -- detailed mode
        results = {
            summaryLines = {},
            gearDetails = {},
            unenchantedItems = 0,
            hasLowDurability = false,
            emptySlots = 0,
            lowRankGems = 0,
            suboptimalGems = 0,
            lowRankEnchants = 0,
            missingSockets = 0,
            emptyGems = 0,
            totalIssues = 0
        }
    end

    -- Process each equipment slot
    for slotId, slotName in pairs(GearData.SLOT_NAMES) do
        local itemLink = GetInventoryItemLink(unit, slotId)
        local itemAnalysis = nil
        
        if itemLink then
            -- Analyze the item
            itemAnalysis = self:AnalyzeItemInternal(itemLink, slotId, playerClass)
        end
        
        if mode == "basic" then
            -- Store basic item info (nil for empty slots)
            results[slotId] = itemAnalysis
        else
            -- Detailed analysis - check for issues (including empty slots)
            self:ProcessSlotIssues(itemAnalysis, slotId, slotName, playerClass, results)
        end
    end
    
    if mode == "detailed" then
        -- Calculate total issues and generate summary
        results.totalIssues = results.unenchantedItems + results.lowRankEnchants + 
                     (results.hasLowDurability and 1 or 0) + results.emptySlots + 
                     results.lowRankGems + results.suboptimalGems + results.emptyGems

        if results.totalIssues == 0 then
            table.insert(results.summaryLines, "|cff00ff00PERFECT GEAR! No issues detected.|r")
            table.insert(results.summaryLines, "")
            table.insert(results.summaryLines, "|cff00ff00 All equipment slots filled|r")
            table.insert(results.summaryLines, "|cff00ff00 All enchantable items properly enchanted|r")
            table.insert(results.summaryLines, "|cff00ff00 All gem slots filled with quality gems|r")
            table.insert(results.summaryLines, "|cff00ff00 Equipment durability is good|r")
        end

        if #results.gearDetails > 0 then
            table.insert(results.summaryLines, "")
            table.insert(results.summaryLines, "|cffadd8e6=== GEAR ISSUES ===|r")
            for _, detail in ipairs(results.gearDetails) do
                table.insert(results.summaryLines, detail)
            end
        end
    end
    
    return results
end

--- Internal item analysis function (shared logic)
--- @param itemLink string Item link to analyze
--- @param slotId number Equipment slot ID
--- @param playerClass string Player class name
--- @return table Item analysis results
function GearUtils:AnalyzeItemInternal(itemLink, slotId, playerClass)
    local _, _, _, itemLevel, _, _, _, _, _, _, _, itemClassID, itemSubClassID = GetItemInfo(itemLink)

    local analysis = {
        itemLink = itemLink,
        itemLevel = itemLevel or 0,
        slotId = slotId,
        enchant = self:GetItemEnchant(itemLink),
        gems = self:GetItemGems(itemLink),
        sockets = self:GetItemSockets(itemLink, slotId),
        durability = self:GetItemDurability(slotId),
        classID = itemClassID,
        subClassID = itemSubClassID
    }

    return analysis
end

--- Process slot-specific issues for detailed analysis using validation engine
--- @param itemAnalysis table|nil Item analysis data (nil for empty slots)
--- @param slotId number Equipment slot ID
--- @param slotName string Equipment slot name
--- @param playerClass string Player class name
--- @param results table Results accumulator
function GearUtils:ProcessSlotIssues(itemAnalysis, slotId, slotName, playerClass, results)
    local ConfigData = getDependency("ConfigData")
    if not ConfigData then
        return
    end
    
    -- Use the validation engine to get all issues for this slot (including empty slots)
    local issues = ValidationEngine:validateItem(itemAnalysis, slotId, ConfigData, playerClass)

    local function formatIssueWithSlot(message)
        if type(message) ~= "string" then
            return ""
        end

        local suffix = " on " .. slotName
        local altSuffix = " in " .. slotName
        if message:find(suffix, 1, true) or message:find(altSuffix, 1, true) then
            return message
        end

        return message .. " in " .. slotName
    end
    
    -- Process each issue and update counters
    for _, issue in ipairs(issues) do
        if issue.type == ISSUE_TYPES.MISSING_ENCHANT then
            results.unenchantedItems = results.unenchantedItems + 1
            table.insert(results.gearDetails, "|cffff8000- Missing enchant: " .. slotName .. "|r")
        elseif issue.type == ISSUE_TYPES.LOW_RANK_ENCHANT then
            results.lowRankEnchants = results.lowRankEnchants + 1
            table.insert(results.gearDetails, "|cffff8000- " .. issue.message .. "|r")
        elseif issue.type == ISSUE_TYPES.EMPTY_SOCKETS then
            results.emptyGems = results.emptyGems + (tonumber(issue.message:match("(%d+)")) or 1)
            table.insert(results.gearDetails, "|cffff8000- " .. issue.message .. " in " .. slotName .. "|r")
        elseif issue.type == ISSUE_TYPES.LOW_RANK_GEM then
            results.lowRankGems = results.lowRankGems + 1
            table.insert(results.gearDetails, "|cffff8000- " .. formatIssueWithSlot(issue.message) .. "|r")
        elseif issue.type == ISSUE_TYPES.SUBOPTIMAL_GEM then
            results.suboptimalGems = results.suboptimalGems + 1
            table.insert(results.gearDetails, "|cffff8000- " .. formatIssueWithSlot(issue.message) .. "|r")
        elseif issue.type == ISSUE_TYPES.LOW_DURABILITY then
            -- Only show durability message once globally (not per-item)
            if not results.hasLowDurability then
                results.hasLowDurability = true
                table.insert(results.gearDetails, "|cffff8000- Gear needs repair|r")
            end
        elseif issue.type == ISSUE_TYPES.EMPTY_SLOT then
            results.emptySlots = results.emptySlots + 1
            table.insert(results.gearDetails, "|cffff8000- Empty slot: " .. slotName .. "|r")
        end
    end
end



--- Gets the current player's gear information
--- @return table|nil Gear information for all slots
function GearUtils:GetPlayerGear()
    return self:AnalyzeGear("player", "basic")
end

--- Gets gear information for a specific unit
--- @param unit string Unit ID ("player", "party1", etc.)
--- @return table|nil Gear information or nil if inspection failed
function GearUtils:GetUnitGear(unit)
    return self:AnalyzeGear(unit, "basic")
end

--- Analyzes a single item for common issues and validation (kept for backward compatibility)
--- @param itemLink string Item link to analyze
--- @param slotId number Equipment slot ID
--- @param playerClass string Player class name
--- @return table Item analysis results
function GearUtils:AnalyzeItem(itemLink, slotId, playerClass)
    if not itemLink then
        return nil
    end

    local analysis = self:AnalyzeItemInternal(itemLink, slotId, playerClass)
    analysis.issues = {}

    -- Check for common issues using validation engine
    self:CheckForGearIssues(analysis, playerClass)

    return analysis
end

--- Checks for common gear issues and flags them using the extensible validation engine
--- @param analysis table Item analysis data
--- @param playerClass string Player class name
function GearUtils:CheckForGearIssues(analysis, playerClass)
    local config = getDependency("ConfigData")
    analysis.issues = ValidationEngine:validateItem(analysis, analysis.slotId, config, playerClass)
end

--- Gets enchant information from an item
--- @param itemLink string Item link to check
--- @return table Enchant information {id, name} or nil
function GearUtils:GetItemEnchant(itemLink)
    if not itemLink then
        return nil
    end

    local itemString = itemLink:match("item:([%d:%-]+)")
    if not itemString then
        return nil
    end

    local parts = { strsplit(":", itemString) }
    local enchantID = tonumber(parts[2])

    if not enchantID or enchantID == 0 then
        return nil
    end

    return {
        id = enchantID,
        name = "Enchant ID: " .. enchantID
    }
end

--- Gets gem information from an item
--- @param itemLink string Item link to check
--- @return table Array of gem information
function GearUtils:GetItemGems(itemLink)
    if not itemLink then
        return {}
    end

    local gems = {}

    -- Extract item string and parse it directly
    local itemString = itemLink:match("item:([%d:%-]+)")
    if not itemString then
        return {}
    end

    local parts = { strsplit(":", itemString) }

    local config = getDependency("ConfigData")
    local gemPositions = config and config.CONSTANTS and config.CONSTANTS.GEM_SLOT_POSITIONS
    local gemData = getDependency("GemData")
    
    if not gemPositions then
        return {}
    end

    for socketIndex, position in ipairs(gemPositions) do
        local gemID = tonumber(parts[position])

        if gemID and gemID > 0 then
            local gemRank = 0
            local hasEnhancedEffect = false
            local warning = nil
            local gemName = "Gem ID: " .. gemID
            local gemQuality = "unknown"

            local _, gemLink = C_Item.GetItemGem(itemLink, socketIndex)
            if gemLink then
                local itemName = C_Item.GetItemInfo(gemLink)
                if itemName then
                    gemName = itemName
                end
            end

            -- Get additional gem data if available
            if gemData then
                if gemData.GetGemRank then
                    gemRank = gemData:GetGemRank(gemID)
                end
                if gemData.HasEnhancedEffect then
                    hasEnhancedEffect = gemData:HasEnhancedEffect(gemID)
                end
                if gemData.GetGemWarning then
                    warning = gemData:GetGemWarning(gemID)
                end
                if gemData.GetGemQuality then
                    gemQuality = gemData:GetGemQuality(gemID)
                end
            end

            table.insert(gems, {
                id = gemID,
                name = gemName,
                rank = gemRank,
                socket = socketIndex,
                quality = gemQuality,
                hasEnhancedEffect = hasEnhancedEffect,
                warning = warning
            })
        end
    end

    return gems
end



--- Gets socket information from an item
--- @param itemLink string Item link to check
--- @param slotId number Optional slot ID for equipped items
--- @return table Socket information {total, filled}
function GearUtils:GetItemSockets(itemLink, slotId)
    if not itemLink then
        return { total = 0, filled = 0 }
    end

    local totalSockets = 0
    local filledSockets = 0

    -- Extract item string and parse it directly for gems
    local itemString = itemLink:match("item:([%d:%-]+)")
    if itemString then
        local parts = { strsplit(":", itemString) }

        -- Check gem positions from config
        local config = getDependency("ConfigData")
        local gemPositions = config and config.CONSTANTS and config.CONSTANTS.GEM_SLOT_POSITIONS
        if gemPositions then
            for _, position in ipairs(gemPositions) do
                local gemID = tonumber(parts[position])
                if gemID and gemID > 0 then
                    filledSockets = filledSockets + 1
                end
            end
        end
    end

    -- Also try C_Item.GetItemGem to cross-check (may not work for inspected units)
    local gemFromAPI = 0
    if C_Item and C_Item.GetItemGem then
        for i = 1, 2 do  -- Only check for 2 gems since all current gear can only have 2 gems max
            local gemName, gemLink = C_Item.GetItemGem(itemLink, i)
            if gemName and gemName ~= "" then
                gemFromAPI = gemFromAPI + 1
            end
        end
    end

    -- Use the higher count
    filledSockets = math.max(filledSockets, gemFromAPI)

    -- Use tooltip scanning for socket detection (this is what you asked for)
    local emptySocketCount = 0
    local socketKeywords = {}

    local function addKeyword(value, isSpecific)
        if type(value) == "string" and value ~= "" then
            table.insert(socketKeywords, {word = value, specific = isSpecific})
        end
    end

    -- Prefer localized global strings when available (mark as specific).
    addKeyword(rawget(_G, "EMPTY_SOCKET_PRISMATIC"), true)
    addKeyword(rawget(_G, "EMPTY_SOCKET_META"), true)
    addKeyword(rawget(_G, "EMPTY_SOCKET_COGWHEEL"), true)
    addKeyword(rawget(_G, "EMPTY_SOCKET_HYDRAULIC"), true)

    -- Fallback keywords for clients/versions without those globals (mark as specific).
    addKeyword("Prismatic Socket", true)
    addKeyword("Meta Socket", true)
    addKeyword("Cogwheel Socket", true)
    addKeyword("Hydraulic Socket", true)
    -- Add generic as non-specific
    addKeyword("Socket", false)

    -- Use tooltip utility for tooltip scanning
    local TooltipUtils = getDependency("TooltipUtils")
    local foundSpecific = false
    if TooltipUtils and TooltipUtils.scanTooltipForSockets then
        -- Scan for each keyword, but only count if a specific one is found
        for _, keyword in ipairs(socketKeywords) do
            local count = TooltipUtils.scanTooltipForSockets(itemLink, {keyword.word})
            if count > 0 then
                if keyword.specific then
                    emptySocketCount = emptySocketCount + count
                    foundSpecific = true
                end
            end
        end
    end

    -- Only count sockets if we actually detect them and a specific keyword was found
    if (emptySocketCount > 0 and foundSpecific) or filledSockets > 0 then
        totalSockets = filledSockets + (foundSpecific and emptySocketCount or 0)
    else
        totalSockets = 0
        filledSockets = 0
    end

    return { total = totalSockets, filled = filledSockets }
end

--- Checks if a unit can be inspected
--- @param unit string Unit ID to check
--- @return boolean True if unit can be inspected
function GearUtils:CanInspectUnit(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
        return false
    end

    -- Group members can generally be inspected
    return UnitInParty(unit) or UnitInRaid(unit) or true
end

--- Checks if a unit has been recently inspected
--- @param unit string Unit ID to check
--- @return boolean True if unit was recently inspected
function GearUtils:IsUnitInspected(unit)
    if not unit then return false end

    -- Check if we can get inventory data for this unit
    -- This is a simple way to detect if inspection data is available
    local hasData = false
    for slotId = 1, 17 do
        local itemLink = GetInventoryItemLink(unit, slotId)
        if itemLink then
            hasData = true
            break
        end
    end

    return hasData
end

--- Safely requests inspection of a unit
--- @param unit string Unit ID to inspect
function GearUtils:RequestInspection(unit)
    if not self:CanInspectUnit(unit) or InCombatLockdown() then
        return
    end

    local unitName = UnitName(unit)
    if not unitName then
        return
    end

    -- Safely request inspection
    local success, err = pcall(InspectUnit, unit)
    if not success then
    end
end

--- Perform detailed personal gear analysis for UI display
--- @return table Detailed gear analysis results
function GearUtils:AnalyzePersonalGear()
    local analysis = self:AnalyzeGear("player", "detailed")
    
    if not analysis then
        return {
            summaryLines = {},
            playerName = UnitName("player")
        }
    end

    return {
        summaryLines = analysis.summaryLines,
        playerName = UnitName("player")
    }
end

local function getEnchantDisplayName(enchantId)
    if not enchantId or enchantId == 0 then
        return nil
    end

    local enchantmentsData = getDependency("EnchantmentsData")
    local byCategory = enchantmentsData and enchantmentsData.BY_CATEGORY_NAME
    if not byCategory then
        return nil
    end

    for _, entries in pairs(byCategory) do
        for _, entry in ipairs(entries) do
            if entry and entry.id == enchantId then
                local name = entry.displayName or entry.itemName
                if type(name) == "string" and name ~= "" then
                    -- Strip common "Enchant <Slot> - " prefixes (e.g. "Enchant Chest - Nature's Wrath").
                    name = name:gsub("^[Ee]nchant%s+%a+%s+%-%s*", "")
                    -- Generated enchant names can end with quality digits (e.g. "Nature's Wrath 2").
                    name = name:gsub("%s+%d+$", "")
                end
                return name
            end
        end
    end

    return nil
end

--- Builds a detailed personal report for gems/enchants and detected issues.
--- @return table
function GearUtils:GetPersonalGemEnchantIssuesReport()
    local GearData = getDependency("GearData")
    local EnchantData = getDependency("EnchantData")
    local ConfigData = getDependency("ConfigData")

    if not GearData or not GearData.SLOT_NAMES then
        return {
            reportLines = { "Unable to load slot data." },
            issueLines = {},
            issueCount = 0
        }
    end

    local _, playerClass = UnitClass("player")

    local slotIds = {}
    for slotId in pairs(GearData.SLOT_NAMES) do
        table.insert(slotIds, slotId)
    end
    table.sort(slotIds)

    local reportLines = {}
    local hasReportEntries = false
    local issueCount = 0

    for _, slotId in ipairs(slotIds) do
        local slotName = GearData.SLOT_NAMES[slotId] or ("Slot " .. tostring(slotId))
        local itemLink = GetInventoryItemLink("player", slotId)

        if itemLink then
            local itemAnalysis = self:AnalyzeItemInternal(itemLink, slotId, playerClass)
            local slotIssues = ValidationEngine:validateItem(itemAnalysis, slotId, ConfigData, playerClass)

            local enchantText = nil
            local enchantId = itemAnalysis and itemAnalysis.enchant and itemAnalysis.enchant.id or 0
            local isEnchantSlot = EnchantData and EnchantData.ENCHANTABLE_SLOTS and EnchantData.ENCHANTABLE_SLOTS[slotId]
            if isEnchantSlot then
                if enchantId and enchantId > 0 then
                    enchantText = getEnchantDisplayName(enchantId) or "Unknown enchant"
                else
                    enchantText = "Missing"
                end
            end

            local gemsText = nil
            if itemAnalysis and itemAnalysis.sockets and itemAnalysis.sockets.total and itemAnalysis.sockets.total > 0 then
                if itemAnalysis.gems and #itemAnalysis.gems > 0 then
                    local gemParts = {}
                    for _, gem in ipairs(itemAnalysis.gems) do
                        table.insert(gemParts, gem.name or ("Gem " .. tostring(gem.id or 0)))
                    end
                    gemsText = table.concat(gemParts, "; ")
                end

                local emptySockets = math.max(0, (itemAnalysis.sockets.total or 0) - (itemAnalysis.sockets.filled or 0))
                if emptySockets > 0 then
                    gemsText = "Missing"
                elseif not gemsText then
                    gemsText = "Missing"
                end
            end

            local slotIssueLines = {}
            if slotIssues and #slotIssues > 0 then
                for _, issue in ipairs(slotIssues) do
                    if issue and issue.message and issue.message ~= "" and issue.type ~= ISSUE_TYPES.LOW_DURABILITY then
                        issueCount = issueCount + 1
                        table.insert(slotIssueLines, "  |cffff8000Issue: " .. issue.message .. "|r")
                    end
                end
            end

            -- Skip slots that have nothing meaningful to display.
            local shouldShowSlot = enchantText ~= nil or gemsText ~= nil or #slotIssueLines > 0
            if shouldShowSlot then
                hasReportEntries = true
                table.insert(reportLines, string.format("|cffadd8e6%s|r", slotName))
                if enchantText then
                    table.insert(reportLines, "  Enchant: " .. enchantText)
                end
                if gemsText then
                    table.insert(reportLines, "  Gems: " .. gemsText)
                end
                for _, issueLine in ipairs(slotIssueLines) do
                    table.insert(reportLines, issueLine)
                end
                table.insert(reportLines, "")
            end
        end
    end

    if not hasReportEntries then
        table.insert(reportLines, "No gem or enchant data found on equipped items.")
    end

    return {
        reportLines = reportLines,
        issueLines = {},
        issueCount = issueCount
    }
end
