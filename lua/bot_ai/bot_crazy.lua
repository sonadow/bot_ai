-- bot_crazy.lua
-- Makes a bot do the "crazy" dance (fast spin + side movement)

if SERVER then

    BotAI = BotAI or {}
    BotAI.Dance = BotAI.Dance or {}

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

    -- Command: bot_crazy <bot_name>
    concommand.Add("bot_crazy", function(ply, cmd, args)
        if not IsValid(ply) then return end

        local botName = args[1]
        if not botName then
            ply:ChatPrint("Usage: bot_crazy <bot_name>")
            return
        end

        local bot = FindBotByName(botName)
        if not IsValid(bot) then
            ply:ChatPrint("Bot named " .. botName .. " not found.")
            return
        end

        -- Crazy dance is a one-shot action, not a toggle
        BotAI.Dance[bot] = {
            t = 0,
            crazy = true
        }

        ply:ChatPrint("Bot " .. botName .. " is doing the CRAZY dance!")
    end)

    -- Dance behavior using StartCommand
    hook.Add("StartCommand", "BotCrazyDanceController", function(ply, cmd)
        if not ply:IsBot() then return end
        local data = BotAI.Dance[ply]
        if not data then return end

        -- Time accumulator for smooth animation
        data.t = data.t + FrameTime()

        -- CRAZY MODE: faster spin, more aggressive movement
        local spinAngle = Angle(0, (data.t * 350) % 360, 0)
        cmd:SetViewAngles(spinAngle)

        -- Wild side-to-side movement
        local side = math.sin(data.t * 10) * 600
        cmd:SetSideMove(side)

        -- Strong forward/back pulses
        local forward = math.cos(data.t * 6) * 500
        cmd:SetForwardMove(forward)

        -- Frequent jumps
        if math.random() < 0.10 then
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))
        end

        -- Remove after 2 seconds (one-shot)
        if data.t > 2 then
            BotAI.Dance[ply] = nil
        end
    end)

end
