-- bot_follow.lua

BotAI = BotAI or {}
BotAI.Follow = BotAI.Follow or {}

local Utils = BotAI.Utils

-- bot_follow <bot_name>
concommand.Add("bot_follow", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local botName = args[1]
    if not botName then
        Utils.ChatPrintSafe(ply, "Usage: bot_follow <bot_name>")
        return
    end

    local bot = Utils.FindBotByName(botName)
    if not IsValid(bot) then
        Utils.ChatPrintSafe(ply, "Bot named " .. botName .. " not found.")
        return
    end

    if BotAI.Follow[bot] then
        BotAI.Follow[bot] = nil
        Utils.ChatPrintSafe(ply, "Bot " .. bot:Name() .. " stopped following.")
    else
        BotAI.Follow[bot] = {
            target     = ply,
            followDist = 150, -- start moving if farther than this
            stopDist   = 80   -- stop if closer than this
        }
        Utils.ChatPrintSafe(ply, "Bot " .. bot:Name() .. " is now following you.")
    end
end)

-- bot_stop <bot_name>
concommand.Add("bot_stop", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local botName = args[1]
    if not botName then
        Utils.ChatPrintSafe(ply, "Usage: bot_stop <bot_name>")
        return
    end

    local bot = Utils.FindBotByName(botName)
    if not IsValid(bot) then
        Utils.ChatPrintSafe(ply, "Bot named " .. botName .. " not found.")
        return
    end

    BotAI.Follow[bot] = nil
    BotAI.Drive[bot]  = nil
    BotAI.Jump[bot]   = nil

    Utils.ChatPrintSafe(ply, "Bot " .. bot:Name() .. " has been stopped (no AI actions).")
end)
