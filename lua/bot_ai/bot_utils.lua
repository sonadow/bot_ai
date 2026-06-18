-- bot_utils.lua

BotAI = BotAI or {}
BotAI.Utils = BotAI.Utils or {}

local Utils = BotAI.Utils

-- Basic bot check
function Utils.IsBot(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:IsBot()
end

-- Find bot by (case-insensitive) name
function Utils.FindBotByName(name)
    if not name then return nil end
    name = string.lower(name)

    for _, ply in ipairs(player.GetAll()) do
        if Utils.IsBot(ply) and string.lower(ply:Name()) == name then
            return ply
        end
    end

    return nil
end

-- Safe chat print (works for console too)
function Utils.ChatPrintSafe(ply, msg)
    if IsValid(ply) and ply:IsPlayer() then
        ply:ChatPrint(msg)
    else
        print(msg)
    end
end

-- Simfphys detection
function Utils.IsSimfphysVehicle(ent)
    return IsValid(ent) and ent.IsSimfphyscar ~= nil
end

-- Find nearest vehicle (HL2 or Simfphys)
function Utils.FindNearestVehicle(bot, maxDistSqr)
    if not IsValid(bot) then return nil end
    maxDistSqr = maxDistSqr or (2000 * 2000)

    local nearest, best = nil, maxDistSqr
    local botPos = bot:GetPos()

    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and (ent:IsVehicle() or Utils.IsSimfphysVehicle(ent)) then
            local d = botPos:DistToSqr(ent:GetPos())
            if d < best then
                best = d
                nearest = ent
            end
        end
    end

    return nearest
end

-- Find nearest non-bot player or NPC
function Utils.FindNearestTarget(bot, maxDistSqr)
    if not IsValid(bot) then return nil end
    maxDistSqr = maxDistSqr or (5000 * 5000)

    local nearest, best = nil, maxDistSqr
    local botPos = bot:GetPos()

    -- Players
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply ~= bot and not ply:IsBot() then
            local d = botPos:DistToSqr(ply:GetPos())
            if d < best then
                best = d
                nearest = ply
            end
        end
    end

    -- NPCs
    for _, npc in ipairs(ents.FindByClass("npc_*")) do
        if IsValid(npc) then
            local d = botPos:DistToSqr(npc:GetPos())
            if d < best then
                best = d
                nearest = npc
            end
        end
    end

    return nearest
end
