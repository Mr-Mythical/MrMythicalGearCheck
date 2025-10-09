--[[
GemData.lua - Mr. Mythical Gear Check Gem Database

Purpose: Database of gem ranks for validation (checking if high-rank gems are equipped)
Dependencies: None
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.GemData = {}

local GemData = MrMythicalGearCheck.GemData

--- Gem quality/rank definitions for validation
--- We only care about detecting if someone has high-rank gems, not which specific gems
GemData.GEM_RANKS = {
    -- Rank 3 (Highest quality gems - what guilds typically require)
    RANK_3 = {
        -- Primary Stat Gems (Unique-Equipped - only one can be equipped)
        217115, -- Cubic Blasphemia +181 primary stat (Intellect/Strength/Agility)
        213743, -- Culminating Blasphemite +181 primary stat + 0.15% Crit effect
        213746, -- Elusive Blasphemite +181 primary stat + 2% move speed
        213740, -- Insightful Blasphemite +181 primary stat + 1% max mana
        
        -- Secondary Stat Gems (Multiple can be equipped)
        213512, -- Versatile Amber +205 stamina + 49 versatility
        213509, -- Masterful Amber +205 stamina + 49 mastery
        213503, -- Deadly Amber +205 stamina + 49 critical strike
        213506, -- Quick Amber +205 stamina + 49 haste
        213517, -- Solid Amber +275 stamina
        
        -- Onyx Gems (Mastery-focused secondary gems)
        213500, -- Masterful Onyx +176 mastery
        213494, -- Quick Onyx +147 mastery + 49 haste
        213491, -- Deadly Onyx +147 mastery + 49 critical strike
        213497, -- Versatile Onyx +147 mastery + 49 versatility
        
        -- Sapphire Gems (Versatility-focused secondary gems)
        213476, -- Versatile Sapphire +176 versatility
        213467, -- Deadly Sapphire +147 versatility + 49 critical strike
        213470, -- Quick Sapphire +147 versatility + 49 haste
        213473, -- Masterful Sapphire +147 versatility + 49 mastery
        
        -- Ruby Gems (Critical Strike-focused secondary gems)
        213464, -- Deadly Ruby +176 critical strike
        213461, -- Versatile Ruby +147 critical strike + 49 versatility
        213455, -- Quick Ruby +147 critical strike + 49 haste
        213458, -- Masterful Ruby +147 critical strike + 49 mastery
        
        -- Emerald Gems (Haste-focused secondary gems)
        213488, -- Quick Emerald +176 haste
        213485, -- Versatile Emerald +147 haste + 49 versatility
        213479, -- Deadly Emerald +147 haste + 49 critical strike
        213482, -- Masterful Emerald +147 haste + 49 mastery
    },
    
    -- Rank 2 (Medium quality gems)
    RANK_2 = {
        -- Primary Stat Gems (Unique-Equipped - only one can be equipped)
        217114, -- Cubic Blasphemia +159 primary stat (Intellect/Strength/Agility)
        213742, -- Culminating Blasphemite +159 primary stat + 0.15% Crit effect
        213745, -- Elusive Blasphemite +159 primary stat + 2% move speed
        213739, -- Insightful Blasphemite +159 primary stat + 1% max mana
        
        -- Secondary Stat Gems (Multiple can be equipped)
        213511, -- Versatile Amber +190 stamina + 44 versatility
        213508, -- Masterful Amber +190 stamina + 44 mastery
        213502, -- Deadly Amber +190 stamina + 44 critical strike
        213505, -- Quick Amber +190 stamina + 44 haste
        213516, -- Solid Amber +250 stamina
        
        -- Onyx Gems (Mastery-focused secondary gems)
        213499, -- Masterful Onyx +159 mastery
        213493, -- Quick Onyx +132 mastery + 44 haste
        213490, -- Deadly Onyx +132 mastery + 44 critical strike
        213496, -- Versatile Onyx +132 mastery + 44 versatility
        
        -- Sapphire Gems (Versatility-focused secondary gems)
        213475, -- Versatile Sapphire +159 versatility
        213466, -- Deadly Sapphire +132 versatility + 44 critical strike
        213469, -- Quick Sapphire +132 versatility + 44 haste
        213472, -- Masterful Sapphire +132 versatility + 44 mastery
        
        -- Ruby Gems (Critical Strike-focused secondary gems)
        213463, -- Deadly Ruby +159 critical strike
        213460, -- Versatile Ruby +132 critical strike + 44 versatility
        213454, -- Quick Ruby +132 critical strike + 44 haste
        213457, -- Masterful Ruby +132 critical strike + 44 mastery
        
        -- Emerald Gems (Haste-focused secondary gems)
        213487, -- Quick Emerald +159 haste
        213484, -- Versatile Emerald +132 haste + 44 versatility
        213478, -- Deadly Emerald +132 haste + 44 critical strike
        213481, -- Masterful Emerald +132 haste + 44 mastery
    },
    
    -- Rank 1 (Low quality gems)
    RANK_1 = {
        -- Primary Stat Gems (Unique-Equipped - only one can be equipped)
        217113, -- Cubic Blasphemia +136 primary stat (Intellect/Strength/Agility)
        213741, -- Culminating Blasphemite +136 primary stat + 0.15% Crit effect
        213744, -- Elusive Blasphemite +136 primary stat + 2% move speed
        213738, -- Insightful Blasphemite +136 primary stat + 1% max mana
        
        -- Secondary Stat Gems (Multiple can be equipped)
        -- Amber Gems (Stamina-focused secondary gems)
        213510, -- Versatile Amber +175 stamina + 39 versatility
        213507, -- Masterful Amber +175 stamina + 39 mastery
        213501, -- Deadly Amber +175 stamina + 39 critical strike
        213504, -- Quick Amber +175 stamina + 39 haste
        213515, -- Solid Amber +225 stamina
        
        -- Onyx Gems (Mastery-focused secondary gems)
        213498, -- Masterful Onyx +141 mastery
        213492, -- Quick Onyx +118 mastery + 39 haste
        213489, -- Deadly Onyx +118 mastery + 39 critical strike
        213495, -- Versatile Onyx +118 mastery + 39 versatility
        
        -- Sapphire Gems (Versatility-focused secondary gems)
        213474, -- Versatile Sapphire +141 versatility
        213465, -- Deadly Sapphire +118 versatility + 39 critical strike
        213468, -- Quick Sapphire +118 versatility + 39 haste
        213471, -- Masterful Sapphire +118 versatility + 39 mastery
        
        -- Ruby Gems (Critical Strike-focused secondary gems)
        213462, -- Deadly Ruby +141 critical strike
        213459, -- Versatile Ruby +118 critical strike + 39 versatility
        213453, -- Quick Ruby +118 critical strike + 39 haste
        213456, -- Masterful Ruby +118 critical strike + 39 mastery
        
        -- Emerald Gems (Haste-focused secondary gems)
        213486, -- Quick Emerald +141 haste
        213483, -- Versatile Emerald +118 haste + 39 versatility
        213477, -- Deadly Emerald +118 haste + 39 critical strike
        213480, -- Masterful Emerald +118 haste + 39 mastery
    }
}

--- Gets the rank of a gem by its ID
--- @param gemId number Gem item ID
--- @return number Gem rank (1-3) or 0 if unknown
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
--- @param minRank number Minimum required rank (default 3)
--- @return boolean Whether gem meets requirement
function GemData:MeetsRankRequirement(gemId, minRank)
    minRank = minRank or 3 -- Default to rank 3 requirement
    local gemRank = self:GetGemRank(gemId)
    return gemRank >= minRank
end

--- Gets display name for gem rank
--- @param rank number Gem rank
--- @return string Display name
function GemData:GetRankDisplayName(rank)
    local rankNames = {
        [3] = "Rank 3 (High Quality)",
        [2] = "Rank 2 (Medium Quality)", 
        [1] = "Rank 1 (Low Quality)",
        [0] = "Unknown/No Gem"
    }
    
    return rankNames[rank] or "Unknown"
end

--- Checks if a gem has an enhanced effect (recommended over basic Cubic Blasphemia)
--- @param gemId number Gem item ID
--- @return boolean Whether gem has an enhanced effect
function GemData:HasEnhancedEffect(gemId)
    if not gemId or gemId == 0 then
        return false
    end
    
    -- Basic Cubic Blasphemia gems (no enhanced effect)
    local basicCubicBlasphemia = {
        217115, -- Rank 3 Cubic Blasphemia
        217114, -- Rank 2 Cubic Blasphemia
        217113, -- Rank 1 Cubic Blasphemia
    }
    
    -- Check if this is a basic Cubic Blasphemia
    for _, id in ipairs(basicCubicBlasphemia) do
        if id == gemId then
            return false -- This is basic, no enhanced effect
        end
    end
    
    -- If it's any other gem ID we recognize, assume it has enhanced effect
    local gemRank = self:GetGemRank(gemId)
    return gemRank > 0 -- If we recognize it and it's not basic Cubic, it's enhanced
end

--- Checks if a gem has only one stat (less efficient than dual-stat gems)
--- @param gemId number Gem item ID
--- @return boolean Whether gem has only one stat
function GemData:IsSingleStatGem(gemId)
    if not gemId or gemId == 0 then
        return false
    end
    
    -- Single-stat gems (less efficient than dual-stat alternatives)
    local singleStatGems = {
        -- Solid Amber (stamina only)
        213517, -- Rank 3 Solid Amber +275 stamina
        213516, -- Rank 2 Solid Amber +250 stamina
        213515, -- Rank 1 Solid Amber +225 stamina
        
        -- Pure secondary stat gems (single stat focus)
        213500, -- Rank 3 Masterful Onyx +176 mastery
        213499, -- Rank 2 Masterful Onyx +159 mastery
        213498, -- Rank 1 Masterful Onyx +141 mastery
        
        213476, -- Rank 3 Versatile Sapphire +176 versatility
        213475, -- Rank 2 Versatile Sapphire +159 versatility
        213474, -- Rank 1 Versatile Sapphire +141 versatility
        
        213464, -- Rank 3 Deadly Ruby +176 critical strike
        213463, -- Rank 2 Deadly Ruby +159 critical strike
        213462, -- Rank 1 Deadly Ruby +141 critical strike
        
        213488, -- Rank 3 Quick Emerald +176 haste
        213487, -- Rank 2 Quick Emerald +159 haste
        213486, -- Rank 1 Quick Emerald +141 haste
    }
    
    for _, id in ipairs(singleStatGems) do
        if id == gemId then
            return true
        end
    end
    
    return false
end

--- Gets a warning message for basic gems that could be upgraded
--- @param gemId number Gem item ID
--- @return string|nil Warning message or nil if no warning needed
function GemData:GetGemWarning(gemId)
    if not gemId or gemId == 0 then
        return nil
    end
    
    -- Check if this is a basic Cubic Blasphemia that should be upgraded
    local basicCubicBlasphemia = {
        [217115] = "Consider upgrading to Culminating/Elusive/Insightful Blasphemite for bonus effects",
        [217114] = "Consider upgrading to Culminating/Elusive/Insightful Blasphemite for bonus effects", 
        [217113] = "Consider upgrading to Culminating/Elusive/Insightful Blasphemite for bonus effects"
    }
    
    local basicWarning = basicCubicBlasphemia[gemId]
    if basicWarning then
        return basicWarning
    end
    
    -- Check if this is a single-stat gem (less efficient)
    if self:IsSingleStatGem(gemId) then
        return "Single-stat gem - consider dual-stat alternative for better total stats"
    end
    
    return nil
end

-- Ensure GemData is available globally for other modules to access
_G.MrMythicalGearCheck = _G.MrMythicalGearCheck or {}
_G.MrMythicalGearCheck.GemData = GemData