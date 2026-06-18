-- bot_dance.lua
-- Makes a bot loop the built-in dance animation every 10 seconds.

if SERVER then

    BotAI = BotAI or {}
    BotAI.DanceLoop = BotAI.DanceLoop or {}

    local function FindBotByName(name)
        if not name then return nil end
        name = string.lower(name)

        for _, ply in ipairs(player.GetAll()) do
            if ply:IsBot() and string.lower(ply:Name()) == name then
                return ply
            end
        end

        return nil
    end

    -- Command: bot_dance <bot_name>
    concommand.Add("bot_dance", function(ply, cmd, args)
        if not IsValid(ply) then return end

        local botName = args[1]
        if not botName then
            ply:ChatPrint("Usage: bot_dance <bot_name>")
            return
        end

        local bot = FindBotByName(botName)
        if not IsValid(bot) then
            ply:ChatPrint("Bot named " .. botName .. " not found.")
            return
        end

        -- Toggle dance loop
        if BotAI.DanceLoop[bot] then
            timer.Remove("BotDanceLoop_" .. bot:EntIndex())
            BotAI.DanceLoop[bot] = nil
            ply:ChatPrint("Bot " .. botName .. " stopped dancing.")
            return
        end

        -- Start looping
        BotAI.DanceLoop[bot] = true

        -- Play immediately
        bot:DoAnimationEvent(ACT_GMOD_TAUNT_DANCE)

        -- Loop every 10 seconds (actual dance duration)
        timer.Create("BotDanceLoop_" .. bot:EntIndex(), 10, 0, function()
            if not IsValid(bot) or not BotAI.DanceLoop[bot] then
                timer.Remove("BotDanceLoop_" .. bot:EntIndex())
                return
            end

            bot:DoAnimationEvent(ACT_GMOD_TAUNT_DANCE)
        end)

        ply:ChatPrint("Bot " .. botName .. " is now dancing in a loop!")
    end)

end
