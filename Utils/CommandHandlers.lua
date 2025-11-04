--[[
CommandHandlers.lua - Mr. Mythical Gear Check Command Handlers

Purpose: Handlers for slash commands and user interface commands
Dependencies: UnifiedUI
Author: Braunerr
--]]

local CommandHandlers = {}

function CommandHandlers.handleOpenCommand()
    local unifiedUI = MrMythicalGearCheck.UnifiedUI

    if unifiedUI and unifiedUI.Show then
        unifiedUI:Show()
        return
    end
end

-- Export the module
MrMythicalGearCheck.CommandHandlers = CommandHandlers

-- Register slash commands
SLASH_MRMYTHICALGEARCHECK1 = "/mrgc"
SLASH_MRMYTHICALGEARCHECK2 = "/gearcheck"
SlashCmdList["MRMYTHICALGEARCHECK"] = CommandHandlers.handleOpenCommand
