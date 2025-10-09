--[[
ConfigData.lua - Mr. Mythical Gear Check Configuration

Purpose: Default settings and configuration constants for gear validation
Dependencies: None
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.ConfigData = {}

local ConfigData = MrMythicalGearCheck.ConfigData

--- Default saved variables for the addon
ConfigData.DEFAULTS = {
    -- Quality Requirements
    MIN_ENCHANT_RANK = 3, -- Require rank 3 enchants by default
    REQUIRE_PREMIUM_ENCHANTS = true, -- Require high quality materials by default
    MIN_GEM_RANK = 3,     -- Require rank 3 gems by default
    
    -- Durability Settings
    LOW_DURABILITY_THRESHOLD = 50, -- Percentage below which durability is considered low
    
    -- Gem Checking Options
    EXCLUDE_OPTIONAL_GEM_SLOTS = true, -- Don't count head/wrist/belt as missing gems
}

--- Configuration constants for gear validation
ConfigData.CONSTANTS = {
    -- Equipment slot IDs (single source of truth)
    SLOT_IDS = {
        HEAD = 1,
        NECK = 2,
        SHOULDER = 3,
        BODY = 4,
        CHEST = 5,
        BELT = 6,
        LEGS = 7,
        FEET = 8,
        WRIST = 9,
        HANDS = 10,
        RING1 = 11,
        RING2 = 12,
        TRINKET1 = 13,
        TRINKET2 = 14,
        CLOAK = 15,
        MAIN_HAND = 16,
        OFF_HAND = 17
    },

    -- Slots that require enchants (rings, cloak, wrist, chest, legs, feet, weapon)
    ENCHANTABLE_SLOTS = {
        [5] = true,   -- Chest
        [7] = true,   -- Legs
        [8] = true,   -- Feet
        [9] = true,   -- Wrist
        [11] = true,  -- Ring 1
        [12] = true,  -- Ring 2
        [15] = true,  -- Back (Cloak)
        [16] = true,  -- Main Hand
        [17] = true   -- Off Hand
    },
    
    -- Slots where enchant quality (premium vs cheap) matters
    QUALITY_CHECK_SLOTS = {
        [9] = true,   -- Wrist
        [11] = true,  -- Ring 1
        [12] = true,  -- Ring 2
        [15] = true   -- Back (Cloak)
    },

    -- Optional gem slots (can be excluded from missing socket warnings)
    OPTIONAL_GEM_SLOTS = {
        [1] = true,   -- Head
        [6] = true,   -- Belt  
        [9] = true    -- Wrist
    },

    -- Weapon slots for Death Knight rune checking
    WEAPON_SLOTS = {
        [16] = true,  -- Main Hand
        [17] = true   -- Off Hand
    },
    
    -- Slots that can have gems (head=1, belt=1, wrist=1, neck=2, rings=2 each)
    GEMABLE_SLOTS = {
        [1] = 1,      -- Head (1 socket)
        [2] = 2,      -- Neck (2 sockets)
        [6] = 1,      -- Belt (1 socket)
        [9] = 1,      -- Wrist (1 socket)
        [11] = 2,     -- Ring 1 (2 sockets)
        [12] = 2      -- Ring 2 (2 sockets)
    },
    
    -- Special item IDs
    SPECIAL_CLOAK_ITEM_ID = 235499, -- Cloak that can have gem sockets
    
    -- Gem parsing configuration
    GEM_SLOT_POSITIONS = {3, 4, 5, 6}, -- Positions in item string where gems are stored
    
    -- Pure cloak gems (preferred versions)
    PURE_GEMS = {
        [238044] = true, -- Precise Fiber Pure
        [238046] = true, -- Energizing Fiber Pure  
        [238042] = true, -- Dexterous Fiber Pure
        [238045] = true  -- Chronomantic Fiber Pure
    },
    
    -- Non-pure cloak gems (should be upgraded to pure)
    NON_PURE_GEMS = {
        [238040] = true, -- Precise Fiber (non-pure)
        [238037] = true, -- Energizing Fiber (non-pure)
        [238041] = true, -- Dexterous Fiber (non-pure)
        [238039] = true  -- Chronomantic Fiber (non-pure)
    }
}

--- Gets the user's preferred minimum enchant rank setting
--- @return number Minimum enchant rank (1-3, defaults to 3)
function ConfigData:GetMinEnchantRank()
    local db = MrMythicalGearCheckDB or {}
    return db.MIN_ENCHANT_RANK or self.DEFAULTS.MIN_ENCHANT_RANK or 3
end

--- Gets whether high quality enchant materials are required
--- @return boolean Whether to require high quality materials (defaults to false)
function ConfigData:RequirePremiumEnchants()
    local db = MrMythicalGearCheckDB or {}
    return db.REQUIRE_PREMIUM_ENCHANTS or self.DEFAULTS.REQUIRE_PREMIUM_ENCHANTS or false
end

--- Gets the minimum gem rank requirement
--- @return number Minimum gem rank (defaults to 3)
function ConfigData:GetMinGemRank()
    local db = MrMythicalGearCheckDB or {}
    return db.MIN_GEM_RANK or self.DEFAULTS.MIN_GEM_RANK or 3
end

--- Checks if optional gem slots (head/wrist/belt) should be excluded from missing gem count
--- @return boolean True if optional slots should be excluded
function ConfigData:ShouldExcludeOptionalGemSlots()
    local db = MrMythicalGearCheckDB or {}
    
    -- If the setting is explicitly set in the database, use that
    if db.EXCLUDE_OPTIONAL_GEM_SLOTS ~= nil then
        local result = db.EXCLUDE_OPTIONAL_GEM_SLOTS
        return result
    end
    
    -- Otherwise, use the default
    local result = self.DEFAULTS.EXCLUDE_OPTIONAL_GEM_SLOTS
    return result
end

--- Gets the low durability threshold percentage
--- @return number Percentage below which durability is considered low (defaults to 50)
function ConfigData:GetLowDurabilityThreshold()
    local db = MrMythicalGearCheckDB or {}
    return db.LOW_DURABILITY_THRESHOLD or self.DEFAULTS.LOW_DURABILITY_THRESHOLD or 50
end

-- Ensure global access
_G.MrMythicalGearCheck = MrMythicalGearCheck
