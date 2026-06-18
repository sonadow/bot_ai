-- addons/bot_ai/lua/autorun/client/bot_ai_menu.lua
-- Bot AI Control Menu (Client) — Custom Non-Modal Draggable Window

if not CLIENT then return end

local BOTAI = {}
BOTAI.Bots = {}
BOTAI.Selected = {}
BOTAI.Frame = nil
BOTAI.List = nil
BOTAI.SelectAllCheck = nil

-------------------------------------------------
-- Networking
-------------------------------------------------

local function RequestBotList()
    net.Start("BotAI_RequestBotList")
    net.SendToServer()
end

net.Receive("BotAI_SendBotList", function()
    BOTAI.Bots = {}
    BOTAI.Selected = {}

    local count = net.ReadUInt(8)

    for i = 1, count do
        local ent        = net.ReadEntity()
        local follow     = net.ReadBool()
        local drive      = net.ReadBool()
        local jump       = net.ReadBool()
        local danceLoop  = net.ReadBool()
        local muscleLoop = net.ReadBool()
        local frozen     = net.ReadBool()

        if IsValid(ent) then
            table.insert(BOTAI.Bots, {
                ent        = ent,
                name       = ent:Nick() or ("Bot[" .. ent:EntIndex() .. "]"),
                follow     = follow,
                drive      = drive,
                jump       = jump,
                danceLoop  = danceLoop,
                muscleLoop = muscleLoop,
                frozen     = frozen
            })
        end
    end

    if IsValid(BOTAI.List) then
        BOTAI.List:Clear()

        for _, info in ipairs(BOTAI.Bots) do
            local statuses = {}

            if info.follow     then table.insert(statuses, "Following") end
            if info.drive      then table.insert(statuses, "Driving") end
            if info.jump       then table.insert(statuses, "Jumping") end
            if info.danceLoop  then table.insert(statuses, "Dancing") end
            if info.muscleLoop then table.insert(statuses, "Muscle") end
            if info.frozen     then table.insert(statuses, "Frozen") end

            local statusStr = table.concat(statuses, ", ")
            local selected = BOTAI.Selected[info.ent] and "✓" or ""

            local line = BOTAI.List:AddLine(selected, info.name, statusStr)
            line.Entity = info.ent
        end
    end
end)

-------------------------------------------------
-- Client runs bot_* commands locally
-------------------------------------------------

net.Receive("BotAI_ClientRunCommand", function()
    local cmd = net.ReadString()
    local botName = net.ReadString()
    LocalPlayer():ConCommand(cmd .. " \"" .. botName .. "\"")
end)

-------------------------------------------------
-- Send command to server for selected bots
-------------------------------------------------

local function SendCommand(cmd)
    local targets = {}

    for _, info in ipairs(BOTAI.Bots) do
        if BOTAI.Selected[info.ent] then
            table.insert(targets, info.ent)
        end
    end

    if #targets == 0 then return end

    net.Start("BotAI_RunCommand")
    net.WriteString(cmd)
    net.WriteUInt(#targets, 8)

    for _, ent in ipairs(targets) do
        net.WriteEntity(ent)
    end

    net.SendToServer()
end

-------------------------------------------------
-- Custom Draggable Window (DFrame‑lookalike)
-------------------------------------------------

local function CreateWindow()
    local frame = vgui.Create("DPanel")
    frame:SetSize(625, 400)
    frame:Center()
    frame:SetVisible(true)
    frame:MakePopup() -- needed ONLY for mouse, not keyboard
    frame:SetKeyboardInputEnabled(false) -- critical
    frame:MoveToFront()

    frame.Dragging = false
    frame.DragX = 0
    frame.DragY = 0

    frame.Paint = function(self, w, h)
        surface.SetDrawColor(40, 40, 40, 240)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawRect(0, 0, w, 28)

        draw.SimpleText("Bot AI Control (ULX Bots)", "DermaDefaultBold", 10, 6, color_white)
    end

    frame.OnMousePressed = function(self, key)
        if key == MOUSE_LEFT then
            local mx, my = self:CursorPos()
            if my <= 28 then
                self.Dragging = true
                self.DragX = mx
                self.DragY = my
            end
        end
    end

    frame.OnMouseReleased = function(self, key)
        if key == MOUSE_LEFT then
            self.Dragging = false
        end
    end

    frame.Think = function(self)
        if self.Dragging then
            local mx, my = gui.MousePos()
            self:SetPos(mx - self.DragX, my - self.DragY)
        end
    end

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(60, 20)
    closeBtn:SetPos(frame:GetWide() - 70, 4)
    closeBtn:SetText("Close")
    closeBtn.DoClick = function()
        frame:SetVisible(false)
    end

    return frame
end

-------------------------------------------------
-- GUI construction
-------------------------------------------------

local function RebuildList()
    if not IsValid(BOTAI.List) then return end

    BOTAI.List:Clear()

    for _, info in ipairs(BOTAI.Bots) do
        local statuses = {}

        if info.follow     then table.insert(statuses, "Following") end
        if info.drive      then table.insert(statuses, "Driving") end
        if info.jump       then table.insert(statuses, "Jumping") end
        if info.danceLoop  then table.insert(statuses, "Dancing") end
        if info.muscleLoop then table.insert(statuses, "Muscle") end
        if info.frozen     then table.insert(statuses, "Frozen") end

        local statusStr = table.concat(statuses, ", ")
        local selected = BOTAI.Selected[info.ent] and "✓" or ""

        local line = BOTAI.List:AddLine(selected, info.name, statusStr)
        line.Entity = info.ent
    end
end

local function OpenBotAIWindow()
    if IsValid(BOTAI.Frame) then
        BOTAI.Frame:SetVisible(true)
        BOTAI.Frame:MoveToFront()
        return
    end

    local frame = CreateWindow()
    BOTAI.Frame = frame

    local topPanel = vgui.Create("DPanel", frame)
    topPanel:Dock(TOP)
    topPanel:SetTall(30)
    topPanel:DockMargin(5, 30, 5, 0)
    topPanel.Paint = nil

    local refreshBtn = vgui.Create("DButton", topPanel)
    refreshBtn:Dock(LEFT)
    refreshBtn:SetWide(120)
    refreshBtn:SetText("Refresh")
    refreshBtn.DoClick = function()
        RequestBotList()
    end

    local selectAll = vgui.Create("DCheckBoxLabel", topPanel)
    selectAll:Dock(LEFT)
    selectAll:DockMargin(15, 0, 0, 0)
    selectAll:SetText("Select All")
    selectAll:SetValue(0)
    selectAll:SizeToContents()
    BOTAI.SelectAllCheck = selectAll

    selectAll.OnChange = function(self, val)
        BOTAI.Selected = {}

        if val then
            for _, info in ipairs(BOTAI.Bots) do
                if IsValid(info.ent) then
                    BOTAI.Selected[info.ent] = true
                end
            end
        end

        RebuildList()
    end

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:DockMargin(5, 5, 5, 5)
    list:AddColumn("✓"):SetFixedWidth(30)
    list:AddColumn("Name")
    list:AddColumn("Status")

    list.OnRowSelected = function(_, _, line)
        local ent = line.Entity
        if not IsValid(ent) then return end

        BOTAI.Selected[ent] = not BOTAI.Selected[ent]

        if BOTAI.Selected[ent] then
            line:SetColumnText(1, "✓")
        else
            line:SetColumnText(1, "")
        end
    end

    BOTAI.List = list

    local bottom = vgui.Create("DPanel", frame)
    bottom:Dock(BOTTOM)
    bottom:SetTall(120)
    bottom:DockMargin(5, 0, 5, 5)
    bottom.Paint = nil

    local btnDefs = {
        { "Follow",      "bot_follow"    },
        { "Drive",       "bot_drive"     },
        { "Jump",        "bot_jump"      },
        { "Freeze",      "bot_freeze"    },
        { "Unfreeze",    "bot_unfreeze"  },
        { "Dance Loop",  "bot_dance"     },
        { "Crazy",       "bot_crazy"     },
        { "Muscle Flex", "bot_muscle"    },
        { "View Bot",    "bot_view"      },
    }

    local grid = vgui.Create("DIconLayout", bottom)
    grid:Dock(FILL)
    grid:SetSpaceX(5)
    grid:SetSpaceY(5)

    for _, def in ipairs(btnDefs) do
        local b = grid:Add("DButton")
        b:SetSize(110, 25)
        b:SetText(def[1])
        b.DoClick = function()
            SendCommand(def[2])
        end
    end

    RequestBotList()
end

-------------------------------------------------
-- Console Toggle Command (bindable)
-------------------------------------------------

concommand.Add("bot_ai_menu", function()
    if IsValid(BOTAI.Frame) and BOTAI.Frame:IsVisible() then
        BOTAI.Frame:SetVisible(false)
        return
    end

    OpenBotAIWindow()
end)

-------------------------------------------------
-- Spawnmenu Button
-------------------------------------------------

hook.Add("PopulateToolMenu", "BotAI_ULXBots_MenuButton", function()
    spawnmenu.AddToolMenuOption(
        "Utilities",
        "Bot AI Control",
        "BotAI_OpenWindow",
        "Open Bot AI Window",
        "",
        "",
        function(panel)
            local openBtn = vgui.Create("DButton", panel)
            openBtn:Dock(TOP)
            openBtn:SetText("Open Bot AI Window")
            openBtn.DoClick = function()
                OpenBotAIWindow()
            end
        end
    )
end)
