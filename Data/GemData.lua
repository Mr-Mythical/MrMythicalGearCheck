--[[
GemData.lua - Mr. Mythical Gear Check Gem Database

Purpose: Database of gem ranks for validation (checking if high-rank gems are equipped)
Dependencies: None
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.GemData = {}

local GemData = MrMythicalGearCheck.GemData

local function uniqueSorted(list)
    local seen = {}
    local result = {}

    for _, value in ipairs(list) do
        if value and not seen[value] then
            seen[value] = true
            table.insert(result, value)
        end
    end

    table.sort(result)
    return result
end

local function getEnchantmentsEntries()
    local shared = (MrMythicalGearCheck.EnchantmentsData and MrMythicalGearCheck.EnchantmentsData.ENTRIES)
        or (_G.MrMythicalGearCheck and _G.MrMythicalGearCheck.EnchantmentsData and
            _G.MrMythicalGearCheck.EnchantmentsData.ENTRIES)
    return shared or {}
end

local function buildGemRanksFromEntries()
    local rank1 = {}
    local rank2 = {}
    local qualityById = {}
    local singleStatSet = {}

    for _, entry in ipairs(getEnchantmentsEntries()) do
        if entry and entry.expansion == 11 and entry.itemId and entry.slot == "socket" and entry.socketType == "PRISMATIC" then
            if entry.quality then
                if entry.quality >= 3 then
                    qualityById[entry.itemId] = "premium"
                else
                    qualityById[entry.itemId] = "cheap"
                end
            end

            if entry.craftingQuality == 2 then
                table.insert(rank2, entry.itemId)
            elseif entry.craftingQuality == 1 then
                table.insert(rank1, entry.itemId)
            elseif entry.craftingQuality == nil and entry.quality == 4 then
                -- Some unique expansion-11 gems have no craftingQuality but should count as highest quality.
                table.insert(rank2, entry.itemId)
            end

            -- Single-stat check: only warn for secondary-stat gems.
            -- Primary-stat gems (str/agi/int) are intentionally single-stat and should not warn.
            local statCount = entry.statCount
            local hasPrimaryStat = entry.hasPrimaryStat

            -- Fallback inference when generated stat metadata is missing.
            if statCount == nil then
                local display = entry.displayName or ""
                if display:find(" / ", 1, true) or display:find("&", 1, true) then
                    statCount = 2
                else
                    statCount = 1
                end
            end

            if hasPrimaryStat == nil then
                local descriptor = string.lower((entry.displayName or "") .. " " .. (entry.itemName or ""))
                hasPrimaryStat = descriptor:find("primary", 1, true) ~= nil
            end

            if statCount == 1 and not hasPrimaryStat then
                singleStatSet[entry.itemId] = true
            end
        end
    end

    return {
        RANK_3 = {},
        RANK_2 = uniqueSorted(rank2),
        RANK_1 = uniqueSorted(rank1),
        QUALITY_BY_ID = qualityById,
        SINGLE_STAT_BY_ID = singleStatSet,
    }
end

--- Gem quality/rank definitions for validation
--- We only care about detecting if someone has high-rank gems, not which specific gems
local generated = buildGemRanksFromEntries()
GemData.GEM_RANKS = {
    RANK_3 = generated.RANK_3,
    RANK_2 = generated.RANK_2,
    RANK_1 = generated.RANK_1,
}
GemData.GEM_QUALITY_BY_ID = generated.QUALITY_BY_ID
GemData.SINGLE_STAT_BY_ID = generated.SINGLE_STAT_BY_ID

--- Gets the rank of a gem by its ID
--- @param gemId number Gem item ID
--- @return number Gem rank (1-2) or 0 if unknown
function GemData:GetGemRank(gemId)
    if not gemId or gemId == 0 then
        return 0
    end
    
    -- Check each rank tier
    for _, id in ipairs(self.GEM_RANKS.RANK_3) do
        if id == gemId then
            return 3
        end
    end
    
    for _, id in ipairs(self.GEM_RANKS.RANK_2) do
        if id == gemId then
            return 2
        end
    end
    
    for _, id in ipairs(self.GEM_RANKS.RANK_1) do
        if id == gemId then
            return 1
        end
    end
    
    return 0 -- Unknown gem
end

--- Checks if a gem meets the minimum rank requirement
--- @param gemId number Gem item ID
--- @param minRank number Minimum required rank (default 2)
--- @return boolean Whether gem meets requirement
function GemData:MeetsRankRequirement(gemId, minRank)
    minRank = minRank or 2 -- Default to highest rank requirement
    local gemRank = self:GetGemRank(gemId)
    return gemRank >= minRank
end

--- Gets material quality for a gem by item ID based on its quality field
--- @param gemId number Gem item ID
--- @return string "premium", "cheap", or "unknown"
function GemData:GetGemQuality(gemId)
    if not gemId or gemId == 0 then
        return "unknown"
    end

    return self.GEM_QUALITY_BY_ID[gemId] or "unknown"
end

--- Checks if a gem is premium quality
--- @param gemId number Gem item ID
--- @return boolean
function GemData:IsPremiumGem(gemId)
    return self:GetGemQuality(gemId) == "premium"
end

--- Gets display name for gem rank
--- @param rank number Gem rank
--- @return string Display name
function GemData:GetRankDisplayName(rank)
    local rankNames = {
        [2] = "Rank 2 (High Quality)",
        [1] = "Rank 1 (Base Quality)",
        [0] = "Unknown/No Gem"
    }
    
    return rankNames[rank] or "Unknown"
end

--- Checks if a gem has a recognized effect in the current database
--- @param gemId number Gem item ID
--- @return boolean Whether gem is a known gem ID
function GemData:HasEnhancedEffect(gemId)
    if not gemId or gemId == 0 then
        return false
    end

    -- If the gem is recognized by rank data, treat it as valid.
    local gemRank = self:GetGemRank(gemId)
    return gemRank > 0
end

--- Checks if a gem has only one stat (less efficient than dual-stat gems)
--- @param gemId number Gem item ID
--- @return boolean Whether gem has only one stat
function GemData:IsSingleStatGem(gemId)
    if not gemId or gemId == 0 then
        return false
    end

    return self.SINGLE_STAT_BY_ID[gemId] == true
end

--- Gets a warning message for known suboptimal gems
--- @param gemId number Gem item ID
--- @return string|nil Warning message or nil if no warning needed
function GemData:GetGemWarning(gemId)
    if not gemId or gemId == 0 then
        return nil
    end

    -- Check if this is a single-stat gem (less efficient)
    if self:IsSingleStatGem(gemId) then
        if self:GetGemQuality(gemId) == "cheap" then
            return "Cheap single-stat gem - consider a premium dual-stat alternative"
        end
        return "Single-stat gem - consider dual-stat alternative for better total stats"
    end

    if self:GetGemQuality(gemId) == "cheap" then
        return "Cheap quality gem - consider premium quality version"
    end
    
    return nil
end

-- Ensure GemData is available globally for other modules to access
_G.MrMythicalGearCheck = _G.MrMythicalGearCheck or {}
_G.MrMythicalGearCheck.GemData = GemData