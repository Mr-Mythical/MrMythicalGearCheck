--[[
UIHelpers.lua - User Interface Helper Functions

Purpose: Reusable UI creation and management functions
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.UIHelpers = {}

local UIHelpers = MrMythicalGearCheck.UIHelpers

-- UI Constants for consistent styling
UIHelpers.UI_CONSTANTS = {
    FRAME = {
        WIDTH = 850,
        HEIGHT = 500,
        NAV_PANEL_WIDTH = 140,
        CONTENT_WIDTH = 680,
    },
    LAYOUT = {
        ROW_HEIGHT = 25,
        LARGE_ROW_HEIGHT = 30,
        BUTTON_HEIGHT = 30,
        PADDING = 10,
        LARGE_PADDING = 20,
    },
    COLORS = {
        EVEN_ROW = {r = 0.1, g = 0.1, b = 0.1, a = 0.3},
        ODD_ROW = {r = 0.15, g = 0.15, b = 0.15, a = 0.3},
        SUCCESS_HIGH = {r = 0, g = 1, b = 0},
        SUCCESS_MEDIUM = {r = 1, g = 1, b = 0},
        SUCCESS_LOW = {r = 1, g = 0, b = 0},
        DISABLED = {r = 0.5, g = 0.5, b = 0.5},
        INFO_TEXT = {r = 0.8, g = 0.8, b = 0.8},
        NAV_BACKGROUND = {r = 0.1, g = 0.1, b = 0.1, a = 0.8}
    },
    CONTENT_TYPES = {
        DASHBOARD = "dashboard",
        PERSONAL_GEAR = "personal_gear",
        GROUP_VALIDATION = "group_validation", 
        SETTINGS = "settings"
    }
}

--- Create a font string with positioning
--- @param parent table Frame parent
--- @param layer string Draw layer
--- @param font string Font template
--- @param text string Initial text
--- @param point string Anchor point
--- @param x number X offset
--- @param y number Y offset
--- @return table FontString object
function UIHelpers.createFontString(parent, layer, font, text, point, x, y)
    local fontString = parent:CreateFontString(nil, layer or "OVERLAY", font or "GameFontNormal")
    if point then
        fontString:SetPoint(point, x or 0, y or 0)
    end
    if text then
        fontString:SetText(text)
    end
    return fontString
end

--- Create a centered header text
--- @param parent table Frame parent
--- @param text string Header text
--- @param x number X position
--- @param width number Header width
--- @return table FontString object
function UIHelpers.createHeader(parent, text, x, width)
    local header = UIHelpers.createFontString(parent, "OVERLAY", "GameFontHighlight", text, "TOPLEFT", x, 0)
    header:SetWidth(width)
    header:SetJustifyH("CENTER")
    return header
end

--- Create alternating row background
--- @param parent table Frame parent
--- @param yOffset number Y position
--- @param width number Row width
--- @param isEven boolean Even/odd row indicator
--- @return table Texture object
function UIHelpers.createRowBackground(parent, yOffset, width, isEven)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 0, yOffset)
    bg:SetSize(width, UIHelpers.UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
    
    local color = isEven and UIHelpers.UI_CONSTANTS.COLORS.EVEN_ROW or UIHelpers.UI_CONSTANTS.COLORS.ODD_ROW
    bg:SetColorTexture(color.r, color.g, color.b, color.a)
    return bg
end

--- Set text color using predefined color names
--- @param fontString table FontString object
--- @param colorName string Color constant name
function UIHelpers.setTextColor(fontString, colorName)
    local color = UIHelpers.UI_CONSTANTS.COLORS[colorName]
    if color then
        fontString:SetTextColor(color.r, color.g, color.b, color.a)
    end
end

--- Create a scroll frame with scroll child
--- @param parent table Frame parent
--- @param width number Scroll frame width
--- @param height number Scroll frame height
--- @param x number X position
--- @param y number Y position
--- @return table, table ScrollFrame and ScrollChild
function UIHelpers.createScrollFrame(parent, width, height, x, y)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", x, y)
    scrollFrame:SetSize(width, height)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(width, height)
    scrollFrame:SetScrollChild(scrollChild)
    
    return scrollFrame, scrollChild
end

--- Create a standard button with consistent styling
--- @param parent table Frame parent
--- @param text string Button text
--- @param width number Button width
--- @param height number Button height
--- @param point string Anchor point
--- @param x number X offset
--- @param y number Y offset
--- @return table Button object
function UIHelpers.createButton(parent, text, width, height, point, x, y)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 120, height or UIHelpers.UI_CONSTANTS.LAYOUT.BUTTON_HEIGHT)
    if point then
        button:SetPoint(point, x or 0, y or 0)
    end
    button:SetText(text or "Button")
    return button
end
