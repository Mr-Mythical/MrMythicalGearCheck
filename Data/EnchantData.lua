--[[
EnchantData.lua - Mr. Mythical Gear Check Enchant Database

Purpose: Database of enchant ranks for validation (checking if high-rank enchants are equipped)
Dependencies: None
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.EnchantData = {}

local EnchantData = MrMythicalGearCheck.EnchantData

--- Enchant quality/rank definitions for validation
--- We only care about detecting if someone has high-rank enchants, not which specific enchants
--- Within each rank, there are often 2 qualities: low quality materials (lower ID) vs high quality materials (higher ID)
--- Examples: Glimmering (low quality) vs Radiant (high quality) for rings, Whisper (low quality) vs Chant (high quality) for wrist/cloak
EnchantData.ENCHANT_RANKS = {
    RANK_3 = {
        7331, -- +Critical Strike (Tier 3)
        7334, -- +Critical Strike (Tier 3)
        7337, -- +Haste (Tier 3)
        7340, -- +Haste (Tier 3)
        7343, -- +Mastery (Tier 3)
        7346, -- +Mastery (Tier 3)
        7349, -- +Versatility (Tier 3)
        7352, -- +Versatility (Tier 3)
        7355, -- Stormrider's Agility (Tier 3)
        7358, -- Council's Intellect (Tier 3)
        7361, -- Oathsworn's Strength (Tier 3)
        7364, -- Crystalline Radiance (Tier 3)
        7382, -- +Avoidance (Tier 3)
        7385, -- +Avoidance (Tier 3)
        7388, -- +Leech (Tier 3)
        7391, -- +Leech (Tier 3)
        7394, -- +Speed (Tier 3)
        7397, -- +Speed (Tier 3)
        7400, -- +Avoidance (Tier 3)
        7403, -- Chant of Winged Grace (Tier 3)
        7406, -- +Leech (Tier 3)
        7409, -- Chant of Leeching Fangs (Tier 3)
        7412, -- +Speed (Tier 3)
        7415, -- Chant of Burrowing Rapidity (Tier 3)
        7418, -- Scout's March (Tier 3)
        7421, -- Cavalry's March (Tier 3)
        7424, -- Defender's March (Tier 3)
        7439, -- Council's Guile (Tier 3)
        7442, -- Stormrider's Fury (Tier 3)
        7445, -- Stonebound Artistry (Tier 3)
        7448, -- Oathsworn's Tenacity (Tier 3)
        7451, -- Authority of Air (Tier 3)
        7454, -- Authority of Fiery Resolve (Tier 3)
        7457, -- Authority of Storms (Tier 3)
        7460, -- Authority of the Depths (Tier 3)
        7463, -- Authority of Radiant Power (Tier 3)
        7470, -- Cursed Critical Strike (Tier 3)
        7473, -- Cursed Haste (Tier 3)
        7476, -- Cursed Versatility (Tier 3)
        7479, -- Cursed Mastery (Tier 3)
        7495, -- Algari Mana Oil (Tier 3)
        7498, -- Oil of Deep Toxins (Tier 3)
        7502, -- Oil of Beledar's Grace (Tier 3)
        7531, -- +Intellect & +Mana (Tier 3)
        7534, -- +Intellect & +Stamina (Tier 3)
        7595, -- +Agility/Strength & +Armor (Tier 3)
        7598, -- +Agility/Strength (Tier 3)
        7601, -- +Agility/Strength & +Stamina (Tier 3)
        7654, -- +Agility/Strength/Intellect & +Stamina (Tier 3)
    },
    
    -- Rank 2 (Medium quality enchants)
    RANK_2 = {
        7330, -- +Critical Strike (Tier 2)
        7333, -- +Critical Strike (Tier 2)
        7336, -- +Haste (Tier 2)
        7339, -- +Haste (Tier 2)
        7342, -- +Mastery (Tier 2)
        7345, -- +Mastery (Tier 2)
        7348, -- +Versatility (Tier 2)
        7351, -- +Versatility (Tier 2)
        7354, -- Stormrider's Agility (Tier 2)
        7357, -- Council's Intellect (Tier 2)
        7360, -- Oathsworn's Strength (Tier 2)
        7363, -- Crystalline Radiance (Tier 2)
        7381, -- +Avoidance (Tier 2)
        7384, -- +Avoidance (Tier 2)
        7387, -- +Leech (Tier 2)
        7390, -- +Leech (Tier 2)
        7393, -- +Speed (Tier 2)
        7396, -- +Speed (Tier 2)
        7399, -- +Avoidance (Tier 2)
        7402, -- Chant of Winged Grace (Tier 2)
        7405, -- +Leech (Tier 2)
        7408, -- Chant of Leeching Fangs (Tier 2)
        7411, -- +Speed (Tier 2)
        7414, -- Chant of Burrowing Rapidity (Tier 2)
        7417, -- Scout's March (Tier 2)
        7420, -- Cavalry's March (Tier 2)
        7423, -- Defender's March (Tier 2)
        7438, -- Council's Guile (Tier 2)
        7441, -- Stormrider's Fury (Tier 2)
        7444, -- Stonebound Artistry (Tier 2)
        7447, -- Oathsworn's Tenacity (Tier 2)
        7450, -- Authority of Air (Tier 2)
        7453, -- Authority of Fiery Resolve (Tier 2)
        7456, -- Authority of Storms (Tier 2)
        7459, -- Authority of the Depths (Tier 2)
        7462, -- Authority of Radiant Power (Tier 2)
        7469, -- Cursed Critical Strike (Tier 2)
        7472, -- Cursed Haste (Tier 2)
        7475, -- Cursed Versatility (Tier 2)
        7478, -- Cursed Mastery (Tier 2)
        7494, -- Algari Mana Oil (Tier 2)
        7497, -- Oil of Deep Toxins (Tier 2)
        7501, -- Oil of Beledar's Grace (Tier 2)
        7530, -- +Intellect & +Mana (Tier 2)
        7533, -- +Intellect & +Stamina (Tier 2)
        7594, -- +Agility/Strength & +Armor (Tier 2)
        7597, -- +Agility/Strength (Tier 2)
        7600, -- +Agility/Strength & +Stamina (Tier 2)
        7653, -- +Agility/Strength/Intellect & +Stamina (Tier 2)
    },
    
    -- Rank 1 (Low quality enchants)
    RANK_1 = {
        7329, -- +Critical Strike (Tier 1)
        7332, -- +Critical Strike (Tier 1)
        7335, -- +Haste (Tier 1)
        7338, -- +Haste (Tier 1)
        7341, -- +Mastery (Tier 1)
        7344, -- +Mastery (Tier 1)
        7347, -- +Versatility (Tier 1)
        7350, -- +Versatility (Tier 1)
        7353, -- Stormrider's Agility (Tier 1)
        7356, -- Council's Intellect (Tier 1)
        7359, -- Oathsworn's Strength (Tier 1)
        7362, -- Crystalline Radiance (Tier 1)
        7380, -- +Avoidance (Tier 1)
        7383, -- +Avoidance (Tier 1)
        7386, -- +Leech (Tier 1)
        7389, -- +Leech (Tier 1)
        7392, -- +Speed (Tier 1)
        7395, -- +Speed (Tier 1)
        7398, -- +Avoidance (Tier 1)
        7401, -- Chant of Winged Grace (Tier 1)
        7404, -- +Leech (Tier 1)
        7407, -- Chant of Leeching Fangs (Tier 1)
        7410, -- +Speed (Tier 1)
        7413, -- Chant of Burrowing Rapidity (Tier 1)
        7416, -- Scout's March (Tier 1)
        7419, -- Cavalry's March (Tier 1)
        7422, -- Defender's March (Tier 1)
        7437, -- Council's Guile (Tier 1)
        7440, -- Stormrider's Fury (Tier 1)
        7443, -- Stonebound Artistry (Tier 1)
        7446, -- Oathsworn's Tenacity (Tier 1)
        7449, -- Authority of Air (Tier 1)
        7452, -- Authority of Fiery Resolve (Tier 1)
        7455, -- Authority of Storms (Tier 1)
        7458, -- Authority of the Depths (Tier 1)
        7461, -- Authority of Radiant Power (Tier 1)
        7468, -- Cursed Critical Strike (Tier 1)
        7471, -- Cursed Haste (Tier 1)
        7474, -- Cursed Versatility (Tier 1)
        7477, -- Cursed Mastery (Tier 1)
        7493, -- Algari Mana Oil (Tier 1)
        7496, -- Oil of Deep Toxins (Tier 1)
        7500, -- Oil of Beledar's Grace (Tier 1)
        7529, -- +Intellect & +Mana (Tier 1)
        7532, -- +Intellect & +Stamina (Tier 1)
        7593, -- +Agility/Strength & +Armor (Tier 1)
        7596, -- +Agility/Strength (Tier 1)
        7599, -- +Agility/Strength & +Stamina (Tier 1)
        7652, -- +Agility/Strength/Intellect & +Stamina (Tier 1)
    }
}

--- Valid enchant slots (which slots can/should have enchants)
EnchantData.ENCHANTABLE_SLOTS = {
    [5] = true,   -- Chest
    [7] = true,   -- Legs
    [8] = true,   -- Feet
    [9] = true,   -- Wrist
    [11] = true,  -- Ring 1
    [12] = true,  -- Ring 2
    [15] = true,  -- Back (Cloak)
    [16] = true,  -- Main Hand
    [17] = true   -- Off Hand
}

--- Gets the rank of an enchant by its ID
--- @param enchantId number Enchant ID
--- @return number Enchant rank (1-3) or 0 if unknown
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

--- Gets the quality within a rank (high quality vs low quality materials)
--- @param enchantId number Enchant ID
--- @return string "premium", "cheap", or "unknown"
function EnchantData:GetEnchantQuality(enchantId)
    if not enchantId or enchantId == 0 then
        return "unknown"
    end
    
    -- Get the rank first
    local rank = self:GetEnchantRank(enchantId)
    if rank == 0 then
        return "unknown"
    end
    
    -- Find paired enchants (same stats, different quality)
    local rankTable = nil
    if rank == 3 then
        rankTable = self.ENCHANT_RANKS.RANK_3
    elseif rank == 2 then
        rankTable = self.ENCHANT_RANKS.RANK_2
    elseif rank == 1 then
        rankTable = self.ENCHANT_RANKS.RANK_1
    end
    
    if not rankTable then
        return "unknown"
    end
    
    -- Look for pairs in the rank table
    for i = 1, #rankTable - 1 do
        local lowerId = rankTable[i]
        local higherId = rankTable[i + 1]
        
        -- Check if these are likely a pair (close IDs, suggesting same enchant type)
        if higherId - lowerId <= 5 then -- Reasonable gap for paired enchants
            if enchantId == lowerId then
                return "cheap" -- Lower ID = cheaper materials
            elseif enchantId == higherId then
                return "premium" -- Higher ID = premium materials
            end
        end
    end
    
    -- If no pair found, assume it's premium (single enchant type)
    return "premium"
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
            minRank = 3 -- Fallback to rank 3 requirement
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
        [3] = "Rank 3 (High Quality)",
        [2] = "Rank 2 (Medium Quality)", 
        [1] = "Rank 1 (Low Quality)",
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