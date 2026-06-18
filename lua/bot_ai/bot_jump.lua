-- bot_jump.lua

BotAI = BotAI or {}
BotAI.Jump = BotAI.Jump or {}

local Utils = BotAI.Utils

-- bot_jump <bot_name>
-- Toggles constant jumping
concommand.Add("bot_jump", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local botName = args[1]
    if not botName then
        Utils.ChatPrintSafe(ply, "Usage: bot_jump <bot_name>")
        return
    end

    local bot = Utils.FindBotByName(botName)
    if not IsValid(bot) then
        Utils.ChatPrintSafe(ply, "Bot named " .. botName .. " not found.")
        return
    end

    if BotAI.Jump[bot] then
        BotAI.Jump[bot] = nil
        Utils.ChatPrintSafe(ply, "Bot " .. botName .. " has stopped jumping.")
    else
        BotAI.Jump[bot] = true
        Utils.ChatPrintSafe(ply, "Bot " .. botName .. " is now constantly jumping.")
    end
end)
