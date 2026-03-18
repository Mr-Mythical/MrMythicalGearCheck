--[[
EnchantData.lua - Mr. Mythical Gear Check Enchant Database

Purpose: Database of enchant ranks for validation (checking if high-rank enchants are equipped)
Dependencies: None
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.EnchantData = {}

local EnchantData = MrMythicalGearCheck.EnchantData

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

local VALID_ENCHANT_CATEGORIES = {
    ["Helm Enchants"] = true,
    ["Shoulder Enchants"] = true,
    ["Chest Enchants"] = true,
    ["Leg Enchants"] = true,
    ["Boot Enchants"] = true,
    ["Rings Enchants"] = true,
    ["Weapon Enchants"] = true,
}

local PREMIUM_ENCHANT_ICON_BLUE = "inv_12_profession_enchanting_enchantedvellum_blue"
local PREMIUM_ENCHANT_ICON_PURPLE = "inv_12_profession_enchanting_enchantedvellum_purple"
local CHEAP_ENCHANT_ICON_GREEN = "inv_12_profession_enchanting_enchantedvellum_green"

local function getLegEnchantMaterialQuality(entry)
    -- Leg enchants do not use vellum icon colors for material quality.
    -- Use quality tiers normalized to cheap/premium:
    --   - Agi/Str line: quality 2 = cheap, quality 3 = premium
    --   - Int line:     quality 3 = cheap, quality 4 = premium
    if not entry or not entry.quality then
        return "unknown"
    end

    if entry.quality <= 2 then
        return "cheap"
    end

    if entry.quality >= 4 then
        return "premium"
    end

    -- quality == 3 can be cheap (Int spellthreads) or premium (Agi/Str armor kits)
    local descriptor = string.lower((entry.displayName or "") .. " " .. (entry.itemName or ""))
    if descriptor:find("agi/str", 1, true) or descriptor:find("armor kit", 1, true) then
        return "premium"
    end
    if descriptor:find("int", 1, true) or descriptor:find("spellthread", 1, true) then
        return "cheap"
    end

    -- Fallback for unknown quality-3 leg enchant families.
    return "cheap"
end

local function getMaterialQualityFromEntry(entry)
    if not entry then
        return "unknown"
    end

    if entry.categoryName == "Leg Enchants" then
        return getLegEnchantMaterialQuality(entry)
    end

    if entry.itemIcon == CHEAP_ENCHANT_ICON_GREEN then
        return "cheap"
    end

    if entry.itemIcon == PREMIUM_ENCHANT_ICON_BLUE or entry.itemIcon == PREMIUM_ENCHANT_ICON_PURPLE then
        return "premium"
    end

    return "unknown"
end

local function buildEnchantDataFromEntries()
    local rank1 = {}
    local rank2 = {}
    local runeSet = {}
    local qualityById = {}

    for _, entry in ipairs(getEnchantmentsEntries()) do
        if entry and entry.id then
            if entry.categoryName == "Runes" then
                runeSet[entry.id] = true
            end

            if entry.expansion == 11 and VALID_ENCHANT_CATEGORIES[entry.categoryName] then
                qualityById[entry.id] = getMaterialQualityFromEntry(entry)

                if entry.spellId and entry.craftingQuality == 2 then
                    table.insert(rank2, entry.id)
                elseif entry.spellId and entry.craftingQuality == 1 then
                    table.insert(rank1, entry.id)
                end
            end
        end
    end

    return {
        ENCHANT_RANKS = {
            RANK_3 = {},
            RANK_2 = uniqueSorted(rank2),
            RANK_1 = uniqueSorted(rank1),
        },
        DEATH_KNIGHT_RUNES = runeSet,
        ENCHANT_QUALITY_BY_ID = qualityById,
    }
end

--- Enchant quality/rank definitions for validation
--- Expansion 11 uses a 2-rank crafting system.
local generated = buildEnchantDataFromEntries()
EnchantData.ENCHANT_RANKS = generated.ENCHANT_RANKS

--- Valid enchant slots (which slots can/should have enchants)
EnchantData.ENCHANTABLE_SLOTS = {
    [1] = true,   -- Head
    [3] = true,   -- Shoulder
    [5] = true,   -- Chest
    [7] = true,   -- Legs
    [8] = true,   -- Feet
    [11] = true,  -- Ring 1
    [12] = true,  -- Ring 2
    [16] = true,  -- Main Hand
    [17] = true   -- Off Hand
}

EnchantData.DEATH_KNIGHT_RUNES = generated.DEATH_KNIGHT_RUNES
EnchantData.ENCHANT_QUALITY_BY_ID = generated.ENCHANT_QUALITY_BY_ID

--- Checks whether an enchant ID is a valid Death Knight rune
--- @param enchantId number Enchant ID
--- @return boolean
function EnchantData:IsDeathKnightRune(enchantId)
    if not enchantId or enchantId == 0 then
        return false
    end

    return self.DEATH_KNIGHT_RUNES[enchantId] == true
end

--- Gets the rank of an enchant by its ID
--- @param enchantId number Enchant ID
--- @return number Enchant rank (1-2) or 0 if unknown
function EnchantData:GetEnchantRank(enchantId)
    if not enchantId or enchantId == 0 then
        return 0
    end
    
    -- Check each rank tier
    for _, id in ipairs(self.ENCHANT_RANKS.RANK_3) do
        if id == enchantId then
            return 3
        end
    end
    
    for _, id in ipairs(self.ENCHANT_RANKS.RANK_2) do
        if id == enchantId then
            return 2
        end
    end
    
    for _, id in ipairs(self.ENCHANT_RANKS.RANK_1) do
        if id == enchantId then
            return 1
        end
    end
    
    return 0 -- Unknown enchant
end

--- Gets the quality label for an enchant
--- @param enchantId number Enchant ID
--- @return string "premium", "cheap", or "unknown"
function EnchantData:GetEnchantQuality(enchantId)
    if not enchantId or enchantId == 0 then
        return "unknown"
    end

    return self.ENCHANT_QUALITY_BY_ID[enchantId] or "unknown"
end

--- Gets a comprehensive enchant info
--- @param enchantId number Enchant ID
--- @return table {rank: number, quality: string, isPremium: boolean}
function EnchantData:GetEnchantInfo(enchantId)
    local rank = self:GetEnchantRank(enchantId)
    local quality = self:GetEnchantQuality(enchantId)
    
    return {
        rank = rank,
        quality = quality,
        isPremium = quality == "premium"
    }
end

--- Checks if an enchant meets the minimum rank requirement
--- @param enchantId number Enchant ID
--- @param minRank number Minimum required rank (optional, uses user setting if not provided)
--- @param requirePremium boolean Whether to require premium quality (optional, uses user setting if not provided)
--- @return boolean Whether enchant meets requirement
function EnchantData:MeetsRankRequirement(enchantId, minRank, requirePremium)
    -- If no minRank provided, get it from user settings
    if not minRank then
        local ConfigData = MrMythicalGearCheck.ConfigData
        if ConfigData and ConfigData.GetMinEnchantRank then
            minRank = ConfigData:GetMinEnchantRank()
        else
            minRank = 2 -- Fallback to highest rank requirement
        end
    end
    
    -- If requirePremium not specified, get it from user settings
    if requirePremium == nil then
        local ConfigData = MrMythicalGearCheck.ConfigData
        if ConfigData and ConfigData.RequirePremiumEnchants then
            requirePremium = ConfigData:RequirePremiumEnchants()
        else
            requirePremium = false -- Fallback to not requiring premium
        end
    end
    
    local enchantInfo = self:GetEnchantInfo(enchantId)
    
    -- Check rank requirement
    if enchantInfo.rank < minRank then
        return false
    end
    
    -- Check quality requirement if specified
    if requirePremium and not enchantInfo.isPremium then
        return false
    end
    
    return true
end

--- Gets display name for enchant rank
--- @param rank number Enchant rank
--- @return string Display name
function EnchantData:GetRankDisplayName(rank)
    local rankNames = {
        [2] = "Rank 2 (High Quality)",
        [1] = "Rank 1 (Base Quality)",
        [0] = "Unknown/No Enchant"
    }
    
    return rankNames[rank] or "Unknown"
end

--- Gets display name for enchant quality
--- @param quality string Quality ("premium", "cheap", "unknown")
--- @return string Display name
function EnchantData:GetQualityDisplayName(quality)
    local qualityNames = {
        premium = "Premium Materials",
        cheap = "Cheap Materials",
        unknown = "Unknown Quality"
    }
    
    return qualityNames[quality] or "Unknown"
end

-- Ensure global access
_G.MrMythicalGearCheck = MrMythicalGearCheck