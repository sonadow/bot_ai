-- bot_core.lua
-- Central StartCommand controller

BotAI = BotAI or {}
BotAI.Follow = BotAI.Follow or {}   -- [bot] = { target = Player, stopDist = number, followDist = number }
BotAI.Jump   = BotAI.Jump   or {}   -- [bot] = true/false
BotAI.Drive  = BotAI.Drive  or {}   -- [bot] = { active = true }

local Utils = BotAI.Utils

-- Per-bot movement state (for unstuck, etc.)
BotAI.State = BotAI.State or {}     -- [bot] = { lastPos = Vector, stuckTime = number }

local function GetBotState(bot)
    BotAI.State[bot] = BotAI.State[bot] or {
        lastPos  = bot:GetPos(),
        stuckTime = 0
    }
    return BotAI.State[bot]
end

local function HandleFollow(bot, cmd, data)
    if not IsValid(data.target) then
        BotAI.Follow[bot] = nil
        return
    end

    local botPos    = bot:GetPos()
    local targetPos = data.target:GetPos()

    local dir = targetPos - botPos
    dir.z = 0

    local dist = dir:Length()
    if dist < 1 then return end

    local ang = dir:Angle()
    cmd:SetViewAngles(ang)

    local followDist = data.followDist or 100
    local stopDist   = data.stopDist   or 80

    if dist > followDist then
        cmd:SetForwardMove(400) -- move forward
    elseif dist < stopDist then
        cmd:SetForwardMove(0)
    else
        cmd:SetForwardMove(0)
    end
end

local function HandleJump(bot, cmd)
    if not BotAI.Jump[bot] then return end

    local onGround = bit.band(bot:GetFlags(), FL_ONGROUND) ~= 0
    if onGround then
        cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))
    end
end

local function HandleDrive(bot, cmd, driveData)
    if not driveData or not driveData.active then return end

    local vehicle = bot:GetVehicle()
    if not IsValid(vehicle) then
        -- If using Simfphys, driver is bot but GetVehicle() may differ; we keep it simple:
        BotAI.Drive[bot] = nil
        return
    end

    local target = Utils.FindNearestTarget(bot)
    if not IsValid(target) then
        cmd:SetForwardMove(0)
        cmd:SetSideMove(0)
        return
    end

    local vehPos    = vehicle:GetPos()
    local targetPos = target:GetPos()

    local dir = targetPos - vehPos
    dir.z = 0
    if dir:Length() < 1 then return end
    dir:Normalize()

    -- Look where we're going
    local lookAng = dir:Angle()
    cmd:SetViewAngles(lookAng)

    -- Basic obstacle avoidance via trace
    local traceData = {
        start  = vehPos + Vector(0, 0, 20),
        endpos = vehPos + dir * 300,
        filter = { vehicle, bot }
    }
    local tr = util.TraceLine(traceData)

    local moveDir = dir
    if tr.Hit then
        -- steer around obstacle
        local avoid = tr.HitNormal:Angle():Right()
        if math.random() > 0.5 then avoid = -avoid end
        moveDir = (dir * 0.5 + avoid * 0.5):GetNormalized()
    end

    -- Convert desired direction into forward/side components
    local forward = vehicle:GetForward()
    local right   = vehicle:GetRight()

    local fDot = forward:Dot(moveDir)
    local rDot = right:Dot(moveDir)

    local forwardMove = math.Clamp(fDot * 400, -400, 400)
    local sideMove    = math.Clamp(rDot * 400, -400, 400)

    cmd:SetForwardMove(forwardMove)
    cmd:SetSideMove(sideMove)

    -- Simple random braking
    if math.random() < 0.003 then
        cmd:SetForwardMove(-200)
    end

    -- Unstuck logic
    local st = GetBotState(bot)
    local distMoved = st.lastPos:DistToSqr(vehPos)
    if distMoved < 5 then
        st.stuckTime = st.stuckTime + FrameTime()
    else
        st.stuckTime = 0
    end
    st.lastPos = vehPos

    if st.stuckTime > 2 then
        -- Try backing up and turning
        cmd:SetForwardMove(-400)
        cmd:SetSideMove((math.random() > 0.5) and 400 or -400)
        st.stuckTime = 0
    end
end

hook.Add("StartCommand", "BotAI_StartCommand", function(ply, cmd)
    if not Utils or not Utils.IsBot then return end
    if not Utils.IsBot(ply) then return end

    local bot = ply

    -- FOLLOW
    local followData = BotAI.Follow[bot]
    if followData then
        HandleFollow(bot, cmd, followData)
    end

    -- JUMP
    HandleJump(bot, cmd)

    -- DRIVE
    local driveData = BotAI.Drive[bot]
    if driveData then
        HandleDrive(bot, cmd, driveData)
    end
end)
