-- bot_muscle.lua
-- Loops the built-in "muscle" animation every 10 seconds.

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

    -- Command: bot_muscle <bot_name>
    concommand.Add("bot_muscle", function(ply, cmd, args)
        if not IsValid(ply) then return end

        local botName = args[1]
        if not botName then
            ply:ChatPrint("Usage: bot_muscle <bot_name>")
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
        bot:DoAnimationEvent(ACT_GMOD_TAUNT_MUSCLE)

        -- Loop every 10 seconds
        timer.Create("BotDanceLoop_" .. bot:EntIndex(), 15, 0, function()
            if not IsValid(bot) or not BotAI.DanceLoop[bot] then
                timer.Remove("BotDanceLoop_" .. bot:EntIndex())
                return
            end

            bot:DoAnimationEvent(ACT_GMOD_TAUNT_MUSCLE)
        end)

        ply:ChatPrint("Bot " .. botName .. " is now flexing in a loop!")
    end)

end
