--[[
SeasonData.lua - Patch-day constants for gear validation

Midnight (Interface 120100). EnchantmentsData still tags this season as expansion 11.
Update this file when a new season changes enchantable slots, ilvl bands, or spec stats.

See README "Patch-day data updates".
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.SeasonData = {}

local SeasonData = MrMythicalGearCheck.SeasonData

--- Must stay in sync with scripts/generate_enchantments_lua.js CURRENT_EXPANSION
--- and EnchantmentsData.CURRENT_EXPANSION after regenerating from enchantments.json.
SeasonData.EXPANSION = 11

--- Unique-Equipped: Embellished hard cap (game-enforced; we also warn if a check is enabled)
SeasonData.MAX_EMBELLISHMENTS = 2

--- Suggested average/per-piece ilvl dropdown values. 0 = gate off.
--- Midnight Season 2 Spark crafts: Champion 292-305, Hero 305-318, Myth 318-331.
SeasonData.ILVL_PRESETS = { 0, 290, 300, 310, 320, 330 }

--- LE_UNIT_STAT_* values from GetSpecializationInfo
SeasonData.UNIT_STAT = {
    STRENGTH = 1,
    AGILITY = 2,
    STAMINA = 3,
    INTELLECT = 4,
}

SeasonData.PRIMARY_STAT_LABELS = {
    STR = "Strength",
    AGI = "Agility",
    INT = "Intellect",
    AGI_STR = "Agility/Strength",
}

--- Named Midnight enchants whose primary stat is not obvious from "Int"/"Agi"/"Str" in the title.
--- Worldsoul chest/weapon lines are adaptive primary and are intentionally omitted.
SeasonData.ENCHANT_NAME_PRIMARY = {
    nalorakk = "STR",
    rootwarden = "AGI",
    magister = "INT",
    halazzi = "STR",
}

--- Inspect fallback: specID -> primary stat. Used when GetSpecializationInfo is not available for the unit.
SeasonData.SPEC_PRIMARY_STAT = {
    -- Death Knight
    [250] = "STR", -- Blood
    [251] = "STR", -- Frost
    [252] = "STR", -- Unholy
    -- Demon Hunter
    [577] = "AGI", -- Havoc
    [581] = "AGI", -- Vengeance
    -- Druid
    [102] = "INT", -- Balance
    [103] = "AGI", -- Feral
    [104] = "AGI", -- Guardian
    [105] = "INT", -- Restoration
    -- Evoker
    [1467] = "INT", -- Devastation
    [1468] = "INT", -- Preservation
    [1473] = "INT", -- Augmentation
    -- Hunter
    [253] = "AGI", -- Beast Mastery
    [254] = "AGI", -- Marksmanship
    [255] = "AGI", -- Survival
    -- Mage
    [62] = "INT", -- Arcane
    [63] = "INT", -- Fire
    [64] = "INT", -- Frost
    -- Monk
    [268] = "AGI", -- Brewmaster
    [269] = "AGI", -- Windwalker
    [270] = "INT", -- Mistweaver
    -- Paladin
    [65] = "INT", -- Holy
    [66] = "STR", -- Protection
    [70] = "STR", -- Retribution
    -- Priest
    [256] = "INT", -- Discipline
    [257] = "INT", -- Holy
    [258] = "INT", -- Shadow
    -- Rogue
    [259] = "AGI", -- Assassination
    [260] = "AGI", -- Outlaw
    [261] = "AGI", -- Subtlety
    -- Shaman
    [262] = "INT", -- Elemental
    [263] = "AGI", -- Enhancement
    [264] = "INT", -- Restoration
    -- Warlock
    [265] = "INT", -- Affliction
    [266] = "INT", -- Demonology
    [267] = "INT", -- Destruction
    -- Warrior
    [71] = "STR", -- Arms
    [72] = "STR", -- Fury
    [73] = "STR", -- Protection
}

local function mapUnitStat(primaryStat)
    if primaryStat == SeasonData.UNIT_STAT.STRENGTH then
        return "STR"
    end
    if primaryStat == SeasonData.UNIT_STAT.AGILITY then
        return "AGI"
    end
    if primaryStat == SeasonData.UNIT_STAT.INTELLECT then
        return "INT"
    end
    return nil
end

--- @return number Expansion tag used by EnchantmentsData
function SeasonData:GetExpansion()
    return self.EXPANSION or 11
end

--- @param statKey string|nil STR/AGI/INT/AGI_STR
--- @return string
function SeasonData:GetPrimaryStatLabel(statKey)
    return (statKey and self.PRIMARY_STAT_LABELS[statKey]) or "Primary"
end

--- @param required string|nil Enchant/gem primary
--- @param unitStat string|nil Spec primary
--- @return boolean
function SeasonData:PrimaryStatsCompatible(required, unitStat)
    if not required or not unitStat then
        return true
    end
    if required == unitStat then
        return true
    end
    if required == "AGI_STR" and (unitStat == "AGI" or unitStat == "STR") then
        return true
    end
    return false
end

--- Infer a locked primary stat from enchant/gem text. Nil means any / adaptive (e.g. Primary, Worldsoul).
--- @param text string|nil
--- @return string|nil STR/AGI/INT/AGI_STR
function SeasonData:InferPrimaryStatFromText(text)
    if not text or text == "" then
        return nil
    end

    local name = string.lower(text)

    if name:find("primary", 1, true) or name:find("worldsoul", 1, true) then
        return nil
    end

    for token, stat in pairs(self.ENCHANT_NAME_PRIMARY) do
        if name:find(token, 1, true) then
            return stat
        end
    end

    if name:find("agi/str", 1, true) or name:find("str/agi", 1, true) then
        return "AGI_STR"
    end

    if name:find("intellect", 1, true) or name:find("%f[%a]int%f[%A]") then
        return "INT"
    end
    if name:find("agility", 1, true) or name:find("%f[%a]agi%f[%A]") then
        return "AGI"
    end
    if name:find("strength", 1, true) or name:find("%f[%a]str%f[%A]") then
        return "STR"
    end

    return nil
end

--- @param entry table EnchantmentsData row
--- @return string|nil
function SeasonData:InferEnchantPrimaryStat(entry)
    if not entry then
        return nil
    end
    return self:InferPrimaryStatFromText(
        table.concat({ entry.displayName or "", entry.itemName or "", entry.tokenizedName or "" }, " ")
    )
end

--- Gems use display stats only (ignore named-enchant tokens like Nalorakk).
--- @param entry table EnchantmentsData row
--- @return string|nil
function SeasonData:InferGemPrimaryStat(entry)
    if not entry then
        return nil
    end
    local name = string.lower((entry.displayName or "") .. " " .. (entry.itemName or ""))
    if name:find("primary", 1, true) then
        return nil
    end
    if name:find("agi/str", 1, true) or name:find("str/agi", 1, true) then
        return "AGI_STR"
    end
    if name:find("intellect", 1, true) or name:find("%f[%a]int%f[%A]") then
        return "INT"
    end
    if name:find("agility", 1, true) or name:find("%f[%a]agi%f[%A]") then
        return "AGI"
    end
    if name:find("strength", 1, true) or name:find("%f[%a]str%f[%A]") then
        return "STR"
    end
    return nil
end

local function getPlayerSpecIndex()
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        return C_SpecializationInfo.GetSpecialization()
    end
    if GetSpecialization then
        return GetSpecialization()
    end
    return nil
end

--- Primary stat for a unit's current (or inspected) spec.
--- @param unit string|nil
--- @return string|nil STR/AGI/INT
function SeasonData:GetUnitPrimaryStat(unit)
    local specId

    if not unit or unit == "player" then
        local specIndex = getPlayerSpecIndex()
        if specIndex and GetSpecializationInfo then
            local id, _, _, _, _, primaryStat = GetSpecializationInfo(specIndex)
            local mapped = mapUnitStat(primaryStat)
            if mapped then
                return mapped
            end
            specId = id
        end
    elseif GetInspectSpecialization then
        specId = GetInspectSpecialization(unit)
    end

    specId = tonumber(specId) or 0
    if specId > 0 then
        if self.SPEC_PRIMARY_STAT[specId] then
            return self.SPEC_PRIMARY_STAT[specId]
        end
        if GetSpecializationInfoByID then
            local _, _, _, _, _, maybePrimary = GetSpecializationInfoByID(specId)
            local mapped = mapUnitStat(maybePrimary)
            if mapped then
                return mapped
            end
        end
    end

    return nil
end

_G.MrMythicalGearCheck = MrMythicalGearCheck
