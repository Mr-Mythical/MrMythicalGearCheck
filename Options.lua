--[[
Mr. Mythical Gear Check Options Panel

This module handles the creation and management of the settings panel for the 
Mr. Mythical Gear Check addon. It uses a global registry pattern to coordinate
with other Mr. Mythical addons to avoid duplicate category creation.

Author: Braunerr
--]]

_G.MrMythicalGearCheck = _G.MrMythicalGearCheck or {}

local Options = {}

-- Export the Options module immediately so it's available to other files
_G.MrMythicalGearCheck.Options = Options

-- Configuration data
local DEFAULTS = {
    MIN_ENCHANT_RANK = 3,
    REQUIRE_PREMIUM_ENCHANTS = false,
    MIN_GEM_RANK = 3,
    EXCLUDE_OPTIONAL_GEM_SLOTS = true
}

local DROPDOWN_OPTIONS = {
    MIN_ENCHANT_RANK = {
        { text = "Rank 1 or higher (Any Quality)", value = 1 },
        { text = "Rank 2 or higher (Medium+ Quality)", value = 2 },
        { text = "Rank 3 only (High Quality)", value = 3 }
    },
    MIN_GEM_RANK = {
        { text = "Rank 1 or higher (Any Quality)", value = 1 },
        { text = "Rank 2 or higher (Medium+ Quality)", value = 2 },
        { text = "Rank 3 only (High Quality)", value = 3 }
    }
}

local TOOLTIPS = {
    MIN_ENCHANT_RANK = "Set the minimum required enchant quality rank for gear validation.\n\n" ..
        "|cffffffffRank 1:|r Basic quality enchants (Tier 1)\n" ..
        "|cffffffffRank 2:|r Medium quality enchants (Tier 2)\n" ..
        "|cffffffffRank 3:|r High quality enchants (Tier 3)",
    
    MIN_GEM_RANK = "Set the minimum required gem quality rank for gear validation.\n\n" ..
        "|cffffffffRank 1:|r Basic quality gems (Tier 1)\n" ..
        "|cffffffffRank 2:|r Medium quality gems (Tier 2)\n" ..
        "|cffffffffRank 3:|r High quality gems (Tier 3)"
}

--- Creates a setting with appropriate UI element
--- @param category table The settings category
--- @param name string Display name for the setting
--- @param key string Database key for the setting
--- @param settingType string "boolean", "string", or "number"
--- @param tooltip string Tooltip text
--- @param options? table For dropdown settings only
--- @return table Setting object with setting and initializer
local function createSetting(category, name, key, settingType, tooltip, options)
    local defaultValue = DEFAULTS[key]
    local setting = Settings.RegisterAddOnSetting(category, name, key, MrMythicalGearCheckDB, settingType, name, defaultValue)
    setting:SetValueChangedCallback(function(_, value)
        MrMythicalGearCheckDB[key] = value
    end)

    local initializer
    if settingType == "boolean" then
        initializer = Settings.CreateCheckbox(category, setting, tooltip)
    else -- dropdown for string/number
        local function getOptions()
            local dropdownOptions = {}
            for _, option in ipairs(options) do
                table.insert(dropdownOptions, {
                    text = option.text,
                    label = option.text,
                    value = option.value,
                })
            end
            return dropdownOptions
        end
        initializer = Settings.CreateDropdown(category, setting, getOptions, tooltip)
    end
    
    initializer:SetSetting(setting)
    return { setting = setting, initializer = initializer }
end

--- Initialize the addon settings panel
function Options.initializeSettings()
    MrMythicalGearCheckDB = MrMythicalGearCheckDB or {}
    
    -- Set defaults for any missing values
    for key, default in pairs(DEFAULTS) do
        if MrMythicalGearCheckDB[key] == nil then
            MrMythicalGearCheckDB[key] = default
        end
    end

    -- Call settings panel creation directly
    Options.createSettingsPanel()
end

function Options.createSettingsPanel()
    -- Use a global registry to coordinate with the sibling Mr. Mythical addon
    if not _G.MrMythicalSettingsRegistry then
        _G.MrMythicalSettingsRegistry = {}
    end
    
    local registry = _G.MrMythicalSettingsRegistry
    local parentCategory = nil
    
    -- Check if the sibling addon already created the parent category
    if registry.parentCategory then
        parentCategory = registry.parentCategory
    else
        -- Create the parent category
        parentCategory = Settings.RegisterVerticalLayoutCategory("Mr. Mythical")
        registry.parentCategory = parentCategory
        registry.createdBy = "MrMythicalGearCheck"
        Settings.RegisterAddOnCategory(parentCategory)
    end
    
    -- Create our subcategory under the parent
    local category = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Gear Check")
    
    registry.subCategories = registry.subCategories or {}
    registry.subCategories["GearCheck"] = category
    
    local layout = SettingsPanel:GetLayout(category)

    -- Helper function to add section header
    local function addHeader(name, tooltip)
        local headerData = { name = name, tooltip = tooltip }
        local headerInitializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", headerData)
        layout:AddInitializer(headerInitializer)
    end
    
    -- Define all settings in a table-driven way
    local settingsConfig = {
        {
            header = { name = "Detection Settings", tooltip = "Settings that control what gear issues are detected and reported" },
            settings = {
                { name = "Minimum Enchant Rank", key = "MIN_ENCHANT_RANK", type = "number", 
                  tooltip = TOOLTIPS.MIN_ENCHANT_RANK, options = DROPDOWN_OPTIONS.MIN_ENCHANT_RANK },
                { name = "Require High Quality Enchant Materials", key = "REQUIRE_PREMIUM_ENCHANTS", type = "boolean", 
                  tooltip = "When enabled, requires high quality enchant materials (e.g., 'Radiant' instead of 'Glimmering' for rings, 'Chant' instead of 'Whisper' for wrist/cloak)." },
                { name = "Minimum Gem Rank", key = "MIN_GEM_RANK", type = "number", 
                  tooltip = TOOLTIPS.MIN_GEM_RANK, options = DROPDOWN_OPTIONS.MIN_GEM_RANK },
                { name = "Exclude Optional Gem Slots", key = "EXCLUDE_OPTIONAL_GEM_SLOTS", type = "boolean", 
                  tooltip = "When enabled, head/wrist/belt slots won't count as 'missing gems' in the summary.\n\n" ..
                            "|cffffffffThis is useful early in seasons when these gems are harder to obtain.|r\n\n" ..
                            "|cffffffffNote:|r Quality of gems in these slots will still be checked if present." }
            }
        }
    }
    
    -- Create all settings
    for _, section in ipairs(settingsConfig) do
        if section.header then
            addHeader(section.header.name, section.header.tooltip)
        end
        
        for _, setting in ipairs(section.settings) do
            createSetting(category, setting.name, setting.key, setting.type, setting.tooltip, setting.options)
        end
    end
end

-- Utility function for other addons to check integration status
function Options.getIntegrationInfo()
    local registry = _G.MrMythicalSettingsRegistry
    if not registry then
        return {
            integrated = false,
            reason = "No global registry found"
        }
    end
    
    return {
        integrated = registry.parentCategory ~= nil,
        parentExists = registry.parentCategory ~= nil,
        createdBy = registry.createdBy,
        gearCheckExists = registry.subCategories and registry.subCategories["Gear Check"] ~= nil,
        parentName = registry.parentCategory and registry.parentCategory.GetName and registry.parentCategory:GetName() or nil
    }
end
