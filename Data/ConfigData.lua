--[[
ConfigData.lua - Mr. Mythical Gear Check Configuration

Purpose: Default settings and configuration constants for gear validation
Dependencies: None
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.ConfigData = {}

local ConfigData = MrMythicalGearCheck.ConfigData

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

    -- Slots that require enchants (head, shoulder, chest, legs, feet, fingers, weapon)
    ENCHANTABLE_SLOTS = {
        [1] = true,   -- Head
        [3] = true,   -- Shoulder
        [5] = true,   -- Chest
        [7] = true,   -- Legs
        [8] = true,   -- Feet
        [11] = true,  -- Ring 1
        [12] = true,  -- Ring 2
        [16] = true,  -- Main Hand
        [17] = true   -- Off Hand
    },
    
    -- Slots where enchant material quality (premium vs cheap) matters.
    -- Expansion 11 has a 2-rank system and does not use the previous premium material split.
    QUALITY_CHECK_SLOTS = {
    },

    -- Weapon slots for Death Knight rune checking
    WEAPON_SLOTS = {
        [16] = true,  -- Main Hand
        [17] = true   -- Off Hand
    },
    
    -- Slots that can have gems in Expansion 11.
    -- Neck and ring sockets are no longer treated as expected sockets; we only validate empty sockets when present.
    GEMABLE_SLOTS = {
        [1] = 1,      -- Head (1 socket)
        [2] = 0,      -- Neck (check empty sockets only)
        [6] = 1,      -- Belt (1 socket)
        [9] = 1,      -- Wrist (1 socket)
        [11] = 0,     -- Ring 1 (check empty sockets only)
        [12] = 0      -- Ring 2 (check empty sockets only)
    },
    
    -- Gem parsing configuration
    GEM_SLOT_POSITIONS = {3, 4} -- Positions in item string where gems are stored (only 2 gems max in current gear)
}

--- Helper to get defaults from Options module
local function getDefaults()
    return (MrMythicalGearCheck.Options and MrMythicalGearCheck.Options.DEFAULTS) or {}
end

--- Gets the user's preferred minimum enchant rank setting
--- @return number Minimum enchant rank (1-2, defaults to 2)
function ConfigData:GetMinEnchantRank()
    local db = MrMythicalGearCheckDB or {}
    return db.MIN_ENCHANT_RANK or getDefaults().MIN_ENCHANT_RANK or 2
end

--- Gets whether high quality enchant materials are required
--- @return boolean Whether to require high quality materials (defaults to false)
function ConfigData:RequirePremiumEnchants()
    local db = MrMythicalGearCheckDB or {}
    return db.REQUIRE_PREMIUM_ENCHANTS or getDefaults().REQUIRE_PREMIUM_ENCHANTS or false
end

--- Gets the minimum gem rank requirement
--- @return number Minimum gem rank (defaults to 2)
function ConfigData:GetMinGemRank()
    local db = MrMythicalGearCheckDB or {}
    return db.MIN_GEM_RANK or getDefaults().MIN_GEM_RANK or 2
end

--- Gets the low durability threshold percentage
--- @return number Percentage below which durability is considered low (defaults to 50)
function ConfigData:GetLowDurabilityThreshold()
    local db = MrMythicalGearCheckDB or {}
    return db.LOW_DURABILITY_THRESHOLD or getDefaults().LOW_DURABILITY_THRESHOLD or 50
end

-- Ensure global access
_G.MrMythicalGearCheck = MrMythicalGearCheck
