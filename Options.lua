--[[
Mr. Mythical Gear Check Options Panel

This module handles the creation and management of the settings panel for the 
Mr. Mythical Gear Check addon. It uses a global registry pattern to coordinate
with other Mr. Mythical addons to avoid duplicate category creation.

Author: Braunerr
--]]

_G.MrMythicalGearCheck = _G.MrMythicalGearCheck or {}
local ConfigData = _G.MrMythicalGearCheck.ConfigData

local Options = {}

-- Export the Options module immediately so it's available to other files
_G.MrMythicalGearCheck.Options = Options

--- Creates a boolean setting with a checkbox
--- @param category table The settings category
--- @param name string Display name for the setting
--- @param key string Database key for the setting
--- @param defaultValue boolean Default value
--- @param tooltip string Tooltip text
--- @return table Setting object with setting and checkbox
local function createSetting(category, name, key, defaultValue, tooltip)
    local setting = Settings.RegisterAddOnSetting(category, name, key, MrMythicalGearCheckDB, "boolean", name, defaultValue)
    setting:SetValueChangedCallback(function(_, value)
        MrMythicalGearCheckDB[key] = value
    end)

    local initializer = Settings.CreateCheckbox(category, setting, tooltip)
    initializer:SetSetting(setting)

    return { setting = setting, checkbox = initializer }
end

--- Creates a dropdown setting
--- @param category table The settings category
--- @param name string Display name for the setting
--- @param key string Database key for the setting
--- @param defaultValue any Default value (type matches settingType)
--- @param tooltip string Tooltip text
--- @param options table Array of options with text and value
--- @param settingType string Type of the setting ("string", "number", "boolean")
--- @return table Setting object with setting and dropdown
local function createDropdownSetting(category, name, key, defaultValue, tooltip, options, settingType)
    local setting = Settings.RegisterAddOnSetting(category, name, key, MrMythicalGearCheckDB, settingType, name, defaultValue)
    setting:SetValueChangedCallback(function(_, value)
        MrMythicalGearCheckDB[key] = value
    end)

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

    local initializer = Settings.CreateDropdown(category, setting, getOptions, tooltip)

    return { setting = setting, dropdown = initializer }
end

--- Initialize the addon settings panel
function Options.initializeSettings()
    local defaults = {
        SHOW_ENCHANT_STATUS = true,
        SHOW_GEM_STATUS = true,
        SHOW_GROUP_GEAR = true,
        NOTIFY_MISSING_ENCHANTS = true,
        NOTIFY_MISSING_GEMS = true,
        INSPECT_DELAY = 2,

        MIN_ENCHANT_RANK = 3,
        REQUIRE_PREMIUM_ENCHANTS = false,
        MIN_GEM_RANK = 3,
        EXCLUDE_OPTIONAL_GEM_SLOTS = true,
        enabled = true
    }

    MrMythicalGearCheckDB = MrMythicalGearCheckDB or {}
    for key, default in pairs(defaults) do
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

    -- General Settings Header
    local generalHeaderData = {
        name = "General Settings",
        tooltip = "Main gear check functionality settings"
    }
    local generalHeaderInitializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", generalHeaderData)
    layout:AddInitializer(generalHeaderInitializer)

    -- Enable/Disable addon
    createSetting(
        category,
        "Enable Gear Check",
        "enabled",
        true,
        "Enable or disable the Mr. Mythical Gear Check addon functionality."
    )

    -- Detection Settings Header
    local detectionHeaderData = {
        name = "Detection Settings",
        tooltip = "Settings that control what gear issues are detected and reported"
    }
    local detectionHeaderInitializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", detectionHeaderData)
    layout:AddInitializer(detectionHeaderInitializer)

    -- Minimum enchant rank dropdown
    local enchantRankOptions = {
        { text = "Rank 1 or higher (Any Quality)", value = 1 },
        { text = "Rank 2 or higher (Medium+ Quality)", value = 2 },
        { text = "Rank 3 only (High Quality)", value = 3 }
    }

    createDropdownSetting(
        category,
        "Minimum Enchant Rank",
        "MIN_ENCHANT_RANK",
        3,
        "Set the minimum required enchant quality rank for gear validation.\n\n" ..
        "|cffffffffRank 1:|r Basic quality enchants (Tier 1)\n" ..
        "|cffffffffRank 2:|r Medium quality enchants (Tier 2)\n" ..
        "|cffffffffRank 3:|r High quality enchants (Tier 3)\n\n" ..
        "|cffffffffRecommended:|r Rank 3 for competitive content, Rank 2 for casual play.",
        enchantRankOptions,
        "number"
    )

    -- Require premium enchant materials checkbox
    createSetting(
        category,
        "Require High Quality Enchant Materials",
        "REQUIRE_PREMIUM_ENCHANTS",
        false,
        "When enabled, requires high quality enchant materials (e.g., 'Radiant' instead of 'Glimmering' for rings, 'Chant' instead of 'Whisper' for wrist/cloak).\n\n" ..
        "|cffffffffHigh quality materials:|r Provide the same stats but cost more to craft.\n" ..
        "|cffffffffRecommended:|r Enable for high-end mythic content, disable for casual play."
    )

    -- Minimum gem rank dropdown
    local gemRankOptions = {
        { text = "Rank 1 or higher (Any Quality)", value = 1 },
        { text = "Rank 2 or higher (Medium+ Quality)", value = 2 },
        { text = "Rank 3 only (High Quality)", value = 3 }
    }

    createDropdownSetting(
        category,
        "Minimum Gem Rank",
        "MIN_GEM_RANK",
        3,
        "Set the minimum required gem quality rank for gear validation.\n\n" ..
        "|cffffffffRank 1:|r Basic quality gems (Tier 1)\n" ..
        "|cffffffffRank 2:|r Medium quality gems (Tier 2)\n" ..
        "|cffffffffRank 3:|r High quality gems (Tier 3)\n\n" ..
        "|cffffffffRecommended:|r Rank 3 for competitive content, Rank 2 for casual play.",
        gemRankOptions,
        "number"
    )

    -- Exclude optional gem slots checkbox
    createSetting(
        category,
        "Exclude Optional Gem Slots",
        "EXCLUDE_OPTIONAL_GEM_SLOTS",
        true,
        "When enabled, head/wrist/belt slots won't count as 'missing gems' in the summary.\n\n" ..
        "|cffffffffThis is useful early in seasons when these gems are harder to obtain.|r\n\n" ..
        "|cffffffffNote:|r Quality of gems in these slots will still be checked if present."
    )
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
