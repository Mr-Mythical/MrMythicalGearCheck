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
    MISSING_SOCKET = "MISSING_SOCKET",
    EMPTY_SLOT = "EMPTY_SLOT",
    NOT_SPECIAL_CLOAK = "NOT_SPECIAL_CLOAK"
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

    -- Death Knights use rune engraving instead of enchants on weapons
    local config = getDependency("ConfigData")
    local weaponSlots = (config and config.CONSTANTS and config.CONSTANTS.WEAPON_SLOTS) or {}
    if isDeathKnight(playerClass) and weaponSlots[slotId] then
        return false
    end
    return true
end



--- Gets display name for enchant quality based on slot type
--- @param slotId number Equipment slot ID
--- @param isRequired boolean Whether this is for the "required" quality (true) or current quality (false)
--- @return string Display name
local function getQualityDisplayName(slotId, isRequired)
    -- Rings (slots 11, 12)
    if slotId == 11 or slotId == 12 then
        return isRequired and "Radiant" or "Glimmering"
        -- Wrist (slot 9) and Cloak (slot 15)
    elseif slotId == 9 or slotId == 15 then
        return isRequired and "Chant" or "Whisper"
        -- Default fallback
    else
        return isRequired and "High Quality" or "Low Quality"
    end
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

    validate = function(self, itemAnalysis, slotId, config)
        local issues = {}

        -- Skip validation if no item analysis (empty slot)
        if not itemAnalysis then
            return issues
        end

        if not itemAnalysis.enchant or not itemAnalysis.enchant.id or itemAnalysis.enchant.id == 0 then
            table.insert(issues, {
                type = ISSUE_TYPES.MISSING_ENCHANT,
                message = "Missing enchant"
            })
        else
            local enchantData = getDependency("EnchantData")
            if enchantData then
                local enchantInfo = enchantData:GetEnchantInfo(itemAnalysis.enchant.id)
                if enchantInfo then
                    local minRank = config:GetMinEnchantRank()
                    local requirePremium = config:RequirePremiumEnchants()

                    local hasRankIssue = enchantInfo.rank < minRank
                    -- Only check quality for slots that have quality variations (rings, wrist, cloak)
                    local qualityCheckSlots = config.CONSTANTS and config.CONSTANTS.QUALITY_CHECK_SLOTS or {}
                    local hasQualityIssue = requirePremium and qualityCheckSlots[slotId] and not enchantInfo.isPremium

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
    appliesTo = function(self, slotId)
        local config = getDependency("ConfigData")
        return config and config.CONSTANTS and config.CONSTANTS.GEMABLE_SLOTS and
            config.CONSTANTS.GEMABLE_SLOTS[slotId]
    end,

    validate = function(self, itemAnalysis, slotId, config)
        local issues = {}

        -- Skip validation if no item analysis (empty slot)
        if not itemAnalysis then
            return issues
        end

        if itemAnalysis.sockets and itemAnalysis.sockets.total > itemAnalysis.sockets.filled then
            local emptyCount = itemAnalysis.sockets.total - itemAnalysis.sockets.filled
            table.insert(issues, {
                type = ISSUE_TYPES.EMPTY_SOCKETS,
                message = emptyCount .. " empty gem socket" .. (emptyCount > 1 and "s" or "")
            })
        end

        -- Check gem quality if we have gem data
        if itemAnalysis.gems then
            local minGemRank = config:GetMinGemRank() or 3
            for _, gem in ipairs(itemAnalysis.gems) do
                if gem.rank and gem.rank > 0 and gem.rank < minGemRank then
                    table.insert(issues, {
                        type = ISSUE_TYPES.LOW_RANK_GEM,
                        message = "Low rank gem (rank " .. gem.rank .. ", need " .. minGemRank .. ")"
                    })
                end

                if gem.warning then
                    table.insert(issues, {
                        type = ISSUE_TYPES.SUBOPTIMAL_GEM,
                        message = gem.warning
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

--- Special cloak validation rule (extensible for special item types)
local SpecialCloakValidationRule = {
    appliesTo = function(self, itemAnalysis, slotId)
        local config = getDependency("ConfigData")
        local cloakSlot = (config and config.CONSTANTS and config.CONSTANTS.SLOT_IDS and config.CONSTANTS.SLOT_IDS.CLOAK) or 15
        return slotId == cloakSlot and itemAnalysis.itemLink -- Cloak slot
    end,

    validate = function(self, itemAnalysis, slotId, config)
        local issues = {}
        local gearUtils = getDependency("GearUtils")

        if gearUtils and gearUtils.IsSpecialCloak and gearUtils:IsSpecialCloak(itemAnalysis.itemLink) then
            -- Special cloak validation logic
            local socketInfo = itemAnalysis.sockets
            if socketInfo then
                local actualSockets = socketInfo.total
                local filledSockets = socketInfo.filled

                -- Check for missing socket
                if actualSockets == 0 then
                    table.insert(issues, {
                        type = ISSUE_TYPES.MISSING_SOCKET,
                        message = "Missing socket (special cloak should have gem slot)"
                    })
                end

                -- Check for empty sockets
                if actualSockets > 0 and filledSockets < actualSockets then
                    local missingGems = actualSockets - filledSockets
                    table.insert(issues, {
                        type = ISSUE_TYPES.EMPTY_SOCKETS,
                        message = "Missing " .. missingGems .. " gem" .. (missingGems > 1 and "s" or "")
                    })
                end

                -- Check gem quality and purity
                if itemAnalysis.gems then
                    for _, gem in ipairs(itemAnalysis.gems) do
                        if gem.rank and gem.rank > 0 and gem.rank < (config:GetMinGemRank() or 3) then
                            table.insert(issues, {
                                type = ISSUE_TYPES.LOW_RANK_GEM,
                                message = "Low rank gem (rank " .. gem.rank .. ")"
                            })
                        end

                        if gearUtils.IsNonPureGem and gearUtils:IsNonPureGem(gem.id) then
                            table.insert(issues, {
                                type = ISSUE_TYPES.SUBOPTIMAL_GEM,
                                message = "Non-pure gem (should use pure version)"
                            })
                        end
                    end
                end
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

--- Missing socket validation rule for regular slots (not special cloak)
local MissingSocketValidationRule = {
    appliesTo = function(self, itemAnalysis, slotId)
        local config = getDependency("ConfigData")
        -- Apply to all slots except special cloak that have expected sockets
        local cloakSlot = (config and config.CONSTANTS and config.CONSTANTS.SLOT_IDS and config.CONSTANTS.SLOT_IDS.CLOAK) or 15
        return slotId ~= cloakSlot and itemAnalysis and 
               config and config.CONSTANTS and config.CONSTANTS.GEMABLE_SLOTS and
               config.CONSTANTS.GEMABLE_SLOTS[slotId]
    end,

    validate = function(self, itemAnalysis, slotId, config)
        local issues = {}
        
        local optionalSlots = config.CONSTANTS and config.CONSTANTS.OPTIONAL_GEM_SLOTS or {}
        local isOptionalSlot = optionalSlots[slotId] or false
        local expectedSockets = config.CONSTANTS.GEMABLE_SLOTS[slotId] or 0
        
        if expectedSockets > 0 then
            local shouldWarnAboutMissingSockets = true
            if isOptionalSlot then
                local excludeOptional = config:ShouldExcludeOptionalGemSlots()
                shouldWarnAboutMissingSockets = not excludeOptional
            end
            
            local actualSockets = itemAnalysis.sockets.total
            local missingSocketCount = expectedSockets - actualSockets
            if missingSocketCount > 0 and shouldWarnAboutMissingSockets then
                table.insert(issues, {
                    type = ISSUE_TYPES.MISSING_SOCKET,
                    message = "Missing " .. missingSocketCount .. " socket" .. (missingSocketCount > 1 and "s" or "")
                })
            end
        end
        
        return issues
    end
}

--- Non-special cloak validation rule (checks if wearing correct cloak type)
local NonSpecialCloakValidationRule = {
    appliesTo = function(self, itemAnalysis, slotId, playerClass)
        local config = getDependency("ConfigData")
        local cloakSlot = (config and config.CONSTANTS and config.CONSTANTS.SLOT_IDS and config.CONSTANTS.SLOT_IDS.CLOAK) or 15
        return slotId == cloakSlot and itemAnalysis -- Only apply to cloak slot when item is equipped
    end,

    validate = function(self, itemAnalysis, slotId, config)
        local issues = {}
        local gearUtils = getDependency("GearUtils")
        
        if gearUtils and gearUtils.IsSpecialCloak then
            local isSpecialCloak = gearUtils:IsSpecialCloak(itemAnalysis.itemLink)
            if not isSpecialCloak then
                table.insert(issues, {
                    type = ISSUE_TYPES.NOT_SPECIAL_CLOAK,
                    message = "Not wearing special cloak"
                })
            end
        end
        
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
                local issues = rule:validate(itemAnalysis, slotId, config)
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
ValidationEngine:registerRule(SpecialCloakValidationRule)
ValidationEngine:registerRule(EmptySlotValidationRule)
ValidationEngine:registerRule(MissingSocketValidationRule)
ValidationEngine:registerRule(NonSpecialCloakValidationRule)



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
            specialCloakIssue = 0,
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
                             results.lowRankGems + results.suboptimalGems + results.missingSockets + 
                             results.emptyGems + results.specialCloakIssue

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
            table.insert(results.gearDetails, "|cffff8000- " .. issue.message .. " in " .. slotName .. "|r")
        elseif issue.type == ISSUE_TYPES.SUBOPTIMAL_GEM then
            results.suboptimalGems = results.suboptimalGems + 1
            table.insert(results.gearDetails, "|cffff8000- " .. issue.message .. " in " .. slotName .. "|r")
        elseif issue.type == ISSUE_TYPES.MISSING_SOCKET then
            results.missingSockets = results.missingSockets + 1
            table.insert(results.gearDetails, "|cffff8000- " .. issue.message .. " in " .. slotName .. "|r")
        elseif issue.type == ISSUE_TYPES.LOW_DURABILITY then
            -- Only show durability message once globally (not per-item)
            if not results.hasLowDurability then
                results.hasLowDurability = true
                table.insert(results.gearDetails, "|cffff8000- Gear needs repair|r")
            end
        elseif issue.type == ISSUE_TYPES.EMPTY_SLOT then
            results.emptySlots = results.emptySlots + 1
            table.insert(results.gearDetails, "|cffff8000- Empty slot: " .. slotName .. "|r")
        elseif issue.type == ISSUE_TYPES.NOT_SPECIAL_CLOAK then
            results.specialCloakIssue = 1
            table.insert(results.gearDetails, "|cffff8000- " .. issue.message .. "|r")
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
            end

            table.insert(gems, {
                id = gemID,
                name = gemName,
                rank = gemRank,
                socket = socketIndex,
                hasEnhancedEffect = hasEnhancedEffect,
                warning = warning
            })
        end
    end

    return gems
end



--- Checks if a gem is a non-pure version (for special cloak gems)
--- @param gemID number The gem item ID
--- @return boolean True if the gem is non-pure
function GearUtils:IsNonPureGem(gemID)
    local configData = getDependency("ConfigData")
    local nonPureGems = (configData and configData.CONSTANTS and configData.CONSTANTS.NON_PURE_GEMS) or {}
    return nonPureGems[gemID] or false
end

--- Checks if an item is a special cloak (uses modern API if available)
--- @param itemLink string Item link to check
--- @return boolean True if the item is a special cloak
function GearUtils:IsSpecialCloak(itemLink)
    if not itemLink then
        return false
    end

    -- Try modern C_Item API first
    if C_Item and C_Item.GetItemID then
        local itemLocation = C_Item.GetItemLocation and C_Item.GetItemLocation(itemLink)
        if itemLocation then
            local itemID = C_Item.GetItemID(itemLocation)
            if itemID then
                local configData = getDependency("ConfigData")
                local specialCloakID = (configData and configData.CONSTANTS and configData.CONSTANTS.SPECIAL_CLOAK_ITEM_ID) or
                0
                return itemID == specialCloakID
            end
        end
    end

    -- Fall back to string parsing
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if itemID then
        local configData = getDependency("ConfigData")
        local specialCloakID = (configData and configData.CONSTANTS and configData.CONSTANTS.SPECIAL_CLOAK_ITEM_ID) or 0
        return itemID == specialCloakID
    end

    return false
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
    local socketKeywords = {
        "Socket"
    }

    -- Use tooltip utility for tooltip scanning
    local TooltipUtils = getDependency("TooltipUtils")
    if TooltipUtils and TooltipUtils.scanTooltipForSockets then
        emptySocketCount = TooltipUtils.scanTooltipForSockets(itemLink, socketKeywords)
    end

    -- Total sockets = filled + empty
    totalSockets = filledSockets + emptySocketCount

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
