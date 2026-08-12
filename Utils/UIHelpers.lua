--[[
UIHelpers.lua - Mr. Mythical Gear Check UI Helper Functions

Purpose: Reusable UI creation and management functions
Dependencies: LibMrMythicalUI-1.0 (optional)
Author: Braunerr
--]]

local MrMythicalGearCheck = MrMythicalGearCheck or {}
MrMythicalGearCheck.UIHelpers = {}

local UIHelpers = MrMythicalGearCheck.UIHelpers

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
        DISABLED = {r = 0.5, g = 0.5, b = 0.5},
        INFO_TEXT = {r = 0.8, g = 0.8, b = 0.8},
        NAV_BACKGROUND = {r = 0.1, g = 0.1, b = 0.1, a = 0.8}
    }
}

local function getUILib()
    return LibStub and LibStub("LibMrMythicalUI-1.0", true) or nil
end

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

--- Create a section/page title (Lib CreateHeader when available)
--- @return Frame|FontString
function UIHelpers.createTitle(parent, text, point, x, y, width)
    local Lib = getUILib()
    if Lib then
        local header = Lib:CreateHeader(parent, {
            text = text or "",
            width = width or 400,
        })
        if point then
            header:SetPoint(point, x or 0, y or 0)
        end
        return header
    end
    return UIHelpers.createFontString(parent, "OVERLAY", "GameFontNormalLarge", text, point, x, y)
end

--- Create a themed label (returns FontString for call-site compatibility)
function UIHelpers.createLabel(parent, text, width, height, colorKey, justifyH)
    local Lib = getUILib()
    if Lib then
        local label = Lib:CreateLabel(parent, {
            text = text or "",
            width = width or 200,
            height = height or 25,
            color = colorKey or "TEXT",
            justifyH = justifyH or "LEFT",
        })
        return label, label.FontString
    end
    local fs = UIHelpers.createFontString(parent, "OVERLAY", "GameFontNormal", text)
    if width then
        fs:SetWidth(width)
    end
    if justifyH then
        fs:SetJustifyH(justifyH)
    end
    return fs, fs
end

--- Create a centered header text (column headers)
--- @param parent table Frame parent
--- @param text string Header text
--- @param x number X position
--- @param width number Header width
--- @return table FontString object
function UIHelpers.createHeader(parent, text, x, width)
    local Lib = getUILib()
    if Lib then
        local label = Lib:CreateLabel(parent, {
            text = text or "",
            width = width,
            height = 25,
            color = "TEXT",
            justifyH = "CENTER",
            font = "GameFontHighlight",
        })
        label:SetPoint("TOPLEFT", x, 0)
        return label.FontString
    end
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
    local Lib = getUILib()
    local rowH = UIHelpers.UI_CONSTANTS.LAYOUT.ROW_HEIGHT
    if Lib then
        local color = isEven and Lib.Theme.COLORS.EVEN_ROW or Lib.Theme.COLORS.ODD_ROW
        local bg = Lib:CreateColorTexture(parent, color, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 0, yOffset)
        bg:SetSize(width, rowH)
        return bg
    end
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 0, yOffset)
    bg:SetSize(width, rowH)
    local color = isEven and UIHelpers.UI_CONSTANTS.COLORS.EVEN_ROW or UIHelpers.UI_CONSTANTS.COLORS.ODD_ROW
    bg:SetColorTexture(color.r, color.g, color.b, color.a)
    return bg
end

--- Set text color using predefined color names
--- @param fontString table FontString object
--- @param colorName string Color constant name
function UIHelpers.setTextColor(fontString, colorName)
    local Lib = getUILib()
    if Lib and Lib.Theme and Lib.Theme.COLORS[colorName] and fontString.SetTextColor then
        local c = Lib.Theme.COLORS[colorName]
        fontString:SetTextColor(c.r, c.g, c.b, c.a or 1)
        return
    end
    local color = UIHelpers.UI_CONSTANTS.COLORS[colorName]
    if color then
        fontString:SetTextColor(color.r, color.g, color.b, color.a)
    end
end

--- Create a scroll frame with scroll child
--- @return table, table ScrollFrame and ScrollChild
function UIHelpers.createScrollFrame(parent, width, height, x, y)
    local Lib = getUILib()
    local scrollFrame
    if Lib then
        scrollFrame = Lib:CreateScrollFrame(parent, {
            width = width,
            height = height,
        })
    else
        scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(width, height)
    end
    scrollFrame:SetPoint("TOPLEFT", x, y)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(math.max(1, width - (Lib and 20 or 0)), height)
    scrollFrame:SetScrollChild(scrollChild)

    return scrollFrame, scrollChild
end

--- Linear status bar with WoW StatusBar-compatible SetMinMaxValues/SetValue
function UIHelpers.createStatusBar(parent, width, height, showLabel)
    local Lib = getUILib()
    if Lib then
        local bar = Lib:CreateStatusBar(parent, {
            width = width or 120,
            height = height or 18,
            percent = 0,
            showLabel = showLabel == true,
        })
        bar._min = 0
        bar._max = 100
        function bar:SetMinMaxValues(minV, maxV)
            self._min = minV or 0
            self._max = maxV or 1
        end
        function bar:SetValue(value)
            local range = (self._max or 1) - (self._min or 0)
            if range <= 0 then
                self:SetPercent(0)
            else
                self:SetPercent(((value or 0) - (self._min or 0)) / range)
            end
        end
        function bar:GetValue()
            local range = (self._max or 1) - (self._min or 0)
            return (self._min or 0) + (self:GetPercent() or 0) * range
        end
        return bar
    end

    local progressBar = CreateFrame("StatusBar", nil, parent)
    progressBar:SetSize(width or 120, height or 18)
    progressBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    progressBar:SetStatusBarColor(0.2, 0.8, 0.2, 1.0)
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(0)
    local progressBg = progressBar:CreateTexture(nil, "BACKGROUND")
    progressBg:SetAllPoints(progressBar)
    progressBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    return progressBar
end

--- Create a standard button with consistent styling
function UIHelpers.createButton(parent, text, width, height, point, x, y)
    local Lib = getUILib()
    local button
    if Lib then
        button = Lib:CreateButton(parent, {
            text = text or "Button",
            width = width or 120,
            height = height or UIHelpers.UI_CONSTANTS.LAYOUT.BUTTON_HEIGHT,
        })
    else
        button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetSize(width or 120, height or UIHelpers.UI_CONSTANTS.LAYOUT.BUTTON_HEIGHT)
        button:SetText(text or "Button")
    end
    if point then
        button:SetPoint(point, x or 0, y or 0)
    end
    return button
end
