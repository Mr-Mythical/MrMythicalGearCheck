--[[
Mr. Mythical Gear Check Options Panel

This module handles the creation and management of the settings panel for the
Mr. Mythical Gear Check addon. It uses a global registry pattern to coordinate
with other Mr. Mythical addons to avoid duplicate category creation.

Author: Braunerr
--]]

_G.MrMythicalGearCheck = _G.MrMythicalGearCheck or {}

local Options = {}

_G.MrMythicalGearCheck.Options = Options

local DEFAULTS = {
    MIN_ENCHANT_RANK = 2,
    REQUIRE_PREMIUM_ENCHANTS = true,
    MIN_GEM_RANK = 2,
    LOW_DURABILITY_THRESHOLD = 50,
    SHOW_CHARACTER_PANEL = true,
    SHOW_CHARACTER_PANEL_ISSUES_ONLY = false
}

Options.DEFAULTS = DEFAULTS

local DROPDOWN_OPTIONS = {
    MIN_ENCHANT_RANK = {
        { text = "Rank 1 or higher (Any Quality)", value = 1 },
        { text = "Rank 2 only (High Quality)",     value = 2 }
    },
    MIN_GEM_RANK = {
        { text = "Rank 1 or higher (Any Quality)", value = 1 },
        { text = "Rank 2 only (High Quality)",     value = 2 }
    },
    LOW_DURABILITY_THRESHOLD = {
        { text = "Below 20%", value = 20 },
        { text = "Below 30%", value = 30 },
        { text = "Below 40%", value = 40 },
        { text = "Below 50%", value = 50 },
        { text = "Below 75%", value = 75 }
    }
}

local TOOLTIPS = {
    MIN_ENCHANT_RANK = "Set the minimum required enchant quality rank.\n\n" ..
        "|cffffffffRank 1:|r Basic quality enchants (Tier 1)\n" ..
        "|cffffffffRank 2:|r High quality enchants (Tier 2)",

    MIN_GEM_RANK = "Set the minimum required gem quality rank.\n\n" ..
        "|cffffffffRank 1:|r Basic quality gems (Tier 1)\n" ..
        "|cffffffffRank 2:|r High quality gems (Tier 2)",

    LOW_DURABILITY_THRESHOLD = "Flag gear as needing repair when durability falls below this percentage.\n\n" ..
        "Applies to your personal gear check and character panel summary.",

    REQUIRE_PREMIUM_ENCHANTS = "When enabled, cheap enchant materials are flagged on slots that use a premium vs cheap material split.\n\n" ..
        "|cffaaaaaaCurrent expansion uses rank-based enchants only, so this setting has no effect until material-quality slots are configured again.|r"
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
    local setting = Settings.RegisterAddOnSetting(category, name, key, MrMythicalGearCheckDB, settingType, name,
        defaultValue)
    setting:SetValueChangedCallback(function(_, value)
        MrMythicalGearCheckDB[key] = value
    end)

    local initializer
    if settingType == "boolean" then
        initializer = Settings.CreateCheckbox(category, setting, tooltip)
    else -- dropdown for string/number
        local function getOptions()
            -- Fallback: build menu entries compatible with Blizzard_Menu on older clients.
            local dropdownOptions = {}
            local menuRadio = (_G.MenuButtonType and _G.MenuButtonType.Radio)
                or (_G.Enum and Enum.MenuItemType and Enum.MenuItemType.Radio)
                or 1                    -- numeric fallback commonly used for Radio
            for _, option in ipairs(options) do
                table.insert(dropdownOptions, {
                    text = option.text,
                    label = option.text,
                    value = option.value,
                    controlType = menuRadio,
                    -- Mark selected state and provide a handler to update the setting.
                    checked = function() return setting:GetValue() == option.value end,
                    func = function() setting:SetValue(option.value) end,
                })
            end
            return dropdownOptions
        end
        initializer = Settings.CreateDropdown(category, setting, getOptions, tooltip)
    end

    initializer:SetSetting(setting)
    return { setting = setting, initializer = initializer }
end

function Options.initializeSettings()
    MrMythicalGearCheckDB = MrMythicalGearCheckDB or {}

    for key, default in pairs(DEFAULTS) do
        if MrMythicalGearCheckDB[key] == nil then
            MrMythicalGearCheckDB[key] = default
        end
    end

    Options.createSettingsPanel()
end

function Options.createSettingsPanel()
    if not _G.MrMythicalSettingsRegistry then
        _G.MrMythicalSettingsRegistry = {}
    end

    local registry = _G.MrMythicalSettingsRegistry
    local parentCategory = nil

    if registry.parentCategory then
        parentCategory = registry.parentCategory
    else
        parentCategory = Settings.RegisterVerticalLayoutCategory("Mr. Mythical")
        registry.parentCategory = parentCategory
        registry.createdBy = "MrMythicalGearCheck"
        Settings.RegisterAddOnCategory(parentCategory)
    end

    local category = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Gear Check")

    registry.subCategories = registry.subCategories or {}
    registry.subCategories["GearCheck"] = category

    local layout = SettingsPanel:GetLayout(category)

    local function addHeader(name, tooltip)
        local headerData = { name = name, tooltip = tooltip }
        local headerInitializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", headerData)
        layout:AddInitializer(headerInitializer)
    end

    local settingsConfig = {
        {
            header = { name = "Detection Settings", tooltip = "Settings that control what gear issues are detected and reported" },
            settings = {
                {
                    name = "Minimum Enchant Rank",
                    key = "MIN_ENCHANT_RANK",
                    type = "number",
                    tooltip = TOOLTIPS.MIN_ENCHANT_RANK,
                    options = DROPDOWN_OPTIONS.MIN_ENCHANT_RANK
                },
                {
                    name = "Minimum Gem Rank",
                    key = "MIN_GEM_RANK",
                    type = "number",
                    tooltip = TOOLTIPS.MIN_GEM_RANK,
                    options = DROPDOWN_OPTIONS.MIN_GEM_RANK
                },
                {
                    name = "Low Durability Threshold",
                    key = "LOW_DURABILITY_THRESHOLD",
                    type = "number",
                    tooltip = TOOLTIPS.LOW_DURABILITY_THRESHOLD,
                    options = DROPDOWN_OPTIONS.LOW_DURABILITY_THRESHOLD
                },
                {
                    name = "Show Gear Summary on Character Panel",
                    key = "SHOW_CHARACTER_PANEL",
                    type = "boolean",
                    tooltip = "When enabled, a gear summary is displayed next to the character info panel."
                },
                {
                    name = "Character Panel: Show Only Issues",
                    key = "SHOW_CHARACTER_PANEL_ISSUES_ONLY",
                    type = "boolean",
                    tooltip = "When enabled, the character panel hides clean slots and only lists detected issues."
                }
            }
        }
    }

    -- Premium material checks are inactive while QUALITY_CHECK_SLOTS is empty (Exp 11).
    local configData = _G.MrMythicalGearCheck and _G.MrMythicalGearCheck.ConfigData
    if configData and configData.HasEnchantQualityChecks and configData:HasEnchantQualityChecks() then
        table.insert(settingsConfig[1].settings, 2, {
            name = "Require High Quality Enchant Materials",
            key = "REQUIRE_PREMIUM_ENCHANTS",
            type = "boolean",
            tooltip = TOOLTIPS.REQUIRE_PREMIUM_ENCHANTS
        })
    end

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
        parentName = registry.parentCategory and registry.parentCategory.GetName and registry.parentCategory:GetName() or
        nil
    }
end
