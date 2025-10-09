local CommandHandlers = {}

function CommandHandlers.handleOpenCommand()
    local unifiedUI = MrMythicalGearCheck.UnifiedUI

    if unifiedUI and unifiedUI.Show then
        unifiedUI:Show()
        return
    end

    if MrMythicalGearCheck.DebugPrint then
        MrMythicalGearCheck.DebugPrint("Unified UI not available yet.")
    end
end

-- Export the module
MrMythicalGearCheck.CommandHandlers = CommandHandlers

-- Register slash commands
SLASH_MRMYTHICALGEARCHECK1 = "/mrgc"
SLASH_MRMYTHICALGEARCHECK2 = "/gearcheck"
SlashCmdList["MRMYTHICALGEARCHECK"] = CommandHandlers.handleOpenCommand
