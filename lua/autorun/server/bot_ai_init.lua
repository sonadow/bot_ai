-- bot_ai_init.lua
-- Full rewrite for ULX bots (NPCs)

AddCSLuaFile()

include("bot_ai/bot_utils.lua")
include("bot_ai/bot_core.lua")
include("bot_ai/bot_follow.lua")
include("bot_ai/bot_drive.lua")
include("bot_ai/bot_jump.lua")
include("bot_ai/bot_view.lua")
include("bot_ai/bot_freeze.lua")
include("bot_ai/bot_crazy.lua")
include("bot_ai/bot_dance.lua")
include("bot_ai/bot_muscle.lua")

BotAI = BotAI or {}

-- Per-entity state tables
BotAI.Follow     = BotAI.Follow     or {}
BotAI.Drive      = BotAI.Drive      or {}
BotAI.Jump       = BotAI.Jump       or {}
BotAI.DanceLoop  = BotAI.DanceLoop  or {}
BotAI.MuscleLoop = BotAI.MuscleLoop or {}
BotAI.Frozen     = BotAI.Frozen     or {}

if SERVER then
    util.AddNetworkString("BotAI_RequestBotList")
    util.AddNetworkString("BotAI_SendBotList")
    util.AddNetworkString("BotAI_RunCommand")

    --------------------------------------------------------------------
    -- ULX BOT DETECTION
    --------------------------------------------------------------------
    local function IsULXBot(ent)
        if not IsValid(ent) then return false end
        if not ent:IsNPC() then return false end

        -- Adjust this to match ULX bot class if needed
        -- Commonly npc_citizen, but you can refine:
        local class = ent:GetClass()
        if class ~= "npc_citizen" then return false end

        -- If ULX sets NWVars, you can tighten detection here:
        -- return ent:GetNWBool("ulx_bot", false)

        return true
    end

    local function GetULXBots()
        local bots = {}

        for _, ent in ipairs(ents.GetAll()) do
            if IsULXBot(ent) then
                table.insert(bots, ent)
            end
        end

        return bots
    end

    --------------------------------------------------------------------
    -- SEND BOT LIST + STATUS TO CLIENT
    --------------------------------------------------------------------
    net.Receive("BotAI_RequestBotList", function(_, ply)
        local bots = GetULXBots()

        net.Start("BotAI_SendBotList")
        net.WriteUInt(#bots, 8)

        for _, bot in ipairs(bots) do
            net.WriteEntity(bot)

            net.WriteBool(BotAI.Follow[bot]     or false)
            net.WriteBool(BotAI.Drive[bot]      or false)
            net.WriteBool(BotAI.Jump[bot]       or false)
            net.WriteBool(BotAI.DanceLoop[bot]  or false)
            net.WriteBool(BotAI.MuscleLoop[bot] or false)
            net.WriteBool(BotAI.Frozen[bot]     or false)
        end

        net.Send(ply)
    end)

    --------------------------------------------------------------------
    -- COMMAND DISPATCHER (NPC-BASED)
    --------------------------------------------------------------------
    local function RunBotCommand(cmd, bot)
        if not IsValid(bot) then return end

        -- You wire these to your existing bot_* APIs.
        if cmd == "bot_follow" then
            BotAI.Follow[bot] = not BotAI.Follow[bot]
            if BotAI.Follow[bot] then
                BotAI.StartFollow(bot)
            else
                BotAI.StopFollow(bot)
            end

        elseif cmd == "bot_drive" then
            BotAI.Drive[bot] = not BotAI.Drive[bot]
            if BotAI.Drive[bot] then
                BotAI.StartDrive(bot)
            else
                BotAI.StopDrive(bot)
            end

        elseif cmd == "bot_jump" then
            BotAI.Jump[bot] = true
            BotAI.DoJump(bot)
            BotAI.Jump[bot] = false

        elseif cmd == "bot_freeze" then
            BotAI.Frozen[bot] = true
            BotAI.Freeze(bot)

        elseif cmd == "bot_unfreeze" then
            BotAI.Frozen[bot] = false
            BotAI.Unfreeze(bot)

        elseif cmd == "bot_dance" then
            BotAI.DanceLoop[bot] = not BotAI.DanceLoop[bot]
            if BotAI.DanceLoop[bot] then
                BotAI.StartDanceLoop(bot)
            else
                BotAI.StopDanceLoop(bot)
            end

        elseif cmd == "bot_dancing" then
            BotAI.StartDanceOnce(bot)

        elseif cmd == "bot_muscle" then
            BotAI.MuscleLoop[bot] = not BotAI.MuscleLoop[bot]
            if BotAI.MuscleLoop[bot] then
                BotAI.StartMuscleLoop(bot)
            else
                BotAI.StopMuscleLoop(bot)
            end

        elseif cmd == "bot_view" then
            BotAI.SetViewTarget(bot)

        end
    end

    --------------------------------------------------------------------
    -- RUN COMMANDS ON SELECTED BOTS (FROM GUI)
    --------------------------------------------------------------------
    net.Receive("BotAI_RunCommand", function(_, ply)
        local cmd   = net.ReadString()
        local count = net.ReadUInt(8)

        for i = 1, count do
            local bot = net.ReadEntity()
            if IsULXBot(bot) then
                RunBotCommand(cmd, bot)
            end
        end
    end)
end
