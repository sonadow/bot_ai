-- bot_view.lua

local Utils = BotAI and BotAI.Utils or nil

-- bot_view <bot_name>
concommand.Add("bot_view", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local botName = args[1]
    if not botName then
        if Utils then Utils.ChatPrintSafe(ply, "Usage: bot_view <bot_name>") end
        return
    end

    local bot = nil
    for _, v in ipairs(player.GetAll()) do
        if IsValid(v) and v:IsBot() and string.lower(v:Name()) == string.lower(botName) then
            bot = v
            break
        end
    end

    if not IsValid(bot) then
        if Utils then Utils.ChatPrintSafe(ply, "Bot named " .. botName .. " not found.") end
        return
    end

    if ply:GetObserverTarget() == bot then
        ply:UnSpectate()
        ply:Spawn()
        if Utils then Utils.ChatPrintSafe(ply, "You have stopped viewing " .. botName .. ".") end
    else
        if not ply:Alive() then
            ply:Spawn()
        end
        ply:StripWeapons()
        ply:Spectate(OBS_MODE_IN_EYE)
        ply:SpectateEntity(bot)
        if Utils then Utils.ChatPrintSafe(ply, "You are now viewing " .. botName .. ".") end
    end
end)
