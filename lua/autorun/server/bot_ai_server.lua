-- addons/bot_ai/lua/autorun/server/bot_ai_server.lua
-- ULX bot control backend (server-side)

if not SERVER then return end

util.AddNetworkString("BotAI_RequestBotList")
util.AddNetworkString("BotAI_SendBotList")
util.AddNetworkString("BotAI_RunCommand")
util.AddNetworkString("BotAI_ClientRunCommand")

BotAI = BotAI or {}
BotAI.State = BotAI.State or {}

local function GetBotState(ply)
    BotAI.State[ply] = BotAI.State[ply] or {
        follow     = false,
        drive      = false,
        jump       = false,
        danceLoop  = false,
        muscleLoop = false,
        frozen     = false
    }
    return BotAI.State[ply]
end

local function GetULXBots()
    local bots = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsBot() then
            table.insert(bots, ply)
        end
    end
    return bots
end

net.Receive("BotAI_RequestBotList", function(_, caller)
    if not IsValid(caller) then return end

    local bots = GetULXBots()

    net.Start("BotAI_SendBotList")
    net.WriteUInt(#bots, 8)

    for _, ply in ipairs(bots) do
        local st = GetBotState(ply)

        net.WriteEntity(ply)
        net.WriteBool(st.follow)
        net.WriteBool(st.drive)
        net.WriteBool(st.jump)
        net.WriteBool(st.danceLoop)
        net.WriteBool(st.muscleLoop)
        net.WriteBool(st.frozen)
    end

    net.Send(caller)
end)

local function ApplyStateForCommand(ply, cmd)
    local st = GetBotState(ply)

    if cmd == "bot_follow" then
        st.follow = not st.follow

    elseif cmd == "bot_drive" then
        st.drive = not st.drive

    elseif cmd == "bot_jump" then
        st.jump = not st.jump

    elseif cmd == "bot_dance" then
        st.danceLoop = not st.danceLoop

    elseif cmd == "bot_crazy" then
        st.danceLoop = st.danceLoop  -- one-shot, no toggle

    elseif cmd == "bot_muscle" then
        st.muscleLoop = not st.muscleLoop

    elseif cmd == "bot_freeze" then
        st.frozen = true

    elseif cmd == "bot_unfreeze" then
        st.frozen = false
    end
end

net.Receive("BotAI_RunCommand", function(_, caller)
    if not IsValid(caller) then return end

    local cmd = net.ReadString()
    local count = net.ReadUInt(8)
    if count == 0 then return end

    local targets = {}
    for i = 1, count do
        local ent = net.ReadEntity()
        if IsValid(ent) and ent:IsBot() then
            table.insert(targets, ent)
        end
    end

    for _, ply in ipairs(targets) do
        net.Start("BotAI_ClientRunCommand")
        net.WriteString(cmd)
        net.WriteString(ply:Nick())
        net.Send(caller)

        ApplyStateForCommand(ply, cmd)
    end
end)
