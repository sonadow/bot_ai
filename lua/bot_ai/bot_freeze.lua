-- bot_stop.lua
-- Makes a bot stand still and do absolutely nothing.

if SERVER then

    -- Table of bots that should be frozen
    local FrozenBots = {}

    -- Command: bot_freeze <bot_name>
    concommand.Add("bot_freeze", function(ply, cmd, args)
        if not IsValid(ply) then return end

        local botName = args[1]
        if not botName then
            ply:ChatPrint("Usage: bot_freeze <bot_name>")
            return
        end

        -- Find bot by name
        local bot = nil
        for _, v in ipairs(player.GetAll()) do
            if v:IsBot() and string.lower(v:Name()) == string.lower(botName) then
                bot = v
                break
            end
        end

        if not IsValid(bot) then
            ply:ChatPrint("Bot named " .. botName .. " not found.")
            return
        end

        FrozenBots[bot] = true
        ply:ChatPrint("Bot " .. botName .. " is now frozen and will not move.")
    end)

    -- Command: bot_unfreeze <bot_name>
    concommand.Add("bot_unfreeze", function(ply, cmd, args)
        if not IsValid(ply) then return end

        local botName = args[1]
        if not botName then
            ply:ChatPrint("Usage: bot_unfreeze <bot_name>")
            return
        end

        -- Find bot by name
        local bot = nil
        for _, v in ipairs(player.GetAll()) do
            if v:IsBot() and string.lower(v:Name()) == string.lower(botName) then
                bot = v
                break
            end
        end

        if not IsValid(bot) then
            ply:ChatPrint("Bot named " .. botName .. " not found.")
            return
        end

        FrozenBots[bot] = nil
        ply:ChatPrint("Bot " .. botName .. " is now unfrozen.")
    end)

    -- Stop bot movement using StartCommand (the correct API)
    hook.Add("StartCommand", "FreezeBotCommands", function(ply, cmd)
        if not ply:IsBot() then return end
        if not FrozenBots[ply] then return end

        -- Zero out all movement
        cmd:ClearMovement()
        cmd:ClearButtons()

        -- Keep bot looking straight ahead
        cmd:SetViewAngles(Angle(0, 0, 0))
    end)

end
