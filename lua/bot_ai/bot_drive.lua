-- bot_drive.lua

BotAI = BotAI or {}
BotAI.Drive = BotAI.Drive or {}

local Utils = BotAI.Utils

-- bot_drive <bot_name>
-- Toggles driving the nearest vehicle
concommand.Add("bot_drive", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local botName = args[1]
    if not botName then
        Utils.ChatPrintSafe(ply, "Usage: bot_drive <bot_name>")
        return
    end

    local bot = Utils.FindBotByName(botName)
    if not IsValid(bot) then
        Utils.ChatPrintSafe(ply, "Bot named " .. botName .. " not found.")
        return
    end

    -- If already driving, stop
    if BotAI.Drive[bot] and BotAI.Drive[bot].active then
        BotAI.Drive[bot] = nil

        if bot:InVehicle() then
            bot:ExitVehicle()
        end

        Utils.ChatPrintSafe(ply, "Bot " .. botName .. " stopped driving.")
        return
    end

    -- Find nearest vehicle
    local vehicle = Utils.FindNearestVehicle(bot)
    if not IsValid(vehicle) then
        Utils.ChatPrintSafe(ply, "No vehicle found near " .. botName .. ".")
        return
    end

    -- Enter vehicle
    if Utils.IsSimfphysVehicle(vehicle) then
        -- Simfphys: try to put bot in driver seat
        local seats = vehicle.GetSeats and vehicle:GetSeats()
        local driverSeat = nil

        if seats then
            for _, seat in pairs(seats) do
                if seat.GetDrivingMode and seat:GetDrivingMode() then
                    driverSeat = seat
                    break
                end
            end
        end

        if driverSeat and not IsValid(driverSeat:GetDriver()) then
            bot:EnterVehicle(driverSeat)
        else
            -- fallback
            vehicle:SetDriver(bot)
        end
    else
        bot:EnterVehicle(vehicle)
    end

    -- Clear follow when driving
    BotAI.Follow[bot] = nil

    BotAI.Drive[bot] = {
        active = true
    }

    Utils.ChatPrintSafe(ply, "Bot " .. botName .. " is now driving the nearest vehicle.")
end)
