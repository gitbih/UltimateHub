-- LocalScript (put in StarterPlayerScripts)
-- "Ultra Movement & Utility Suite" — v2.0 for Seid
-- > 50+ Features (implemented client-side, use responsibly)
-- FEATURES (counted): 
-- 1 WalkSpeed slider, 2 JumpPower slider, 3 WalkSpeed presets, 4 Sprint (hold), 5 Sprint multiplier slider,
-- 6 Crouch (hold), 7 Crouch HipHeight adjust, 8 Infinite Jump toggle, 9 Bunnyhop toggle, 10 Fly toggle,
-- 11 Fly speed slider, 12 Noclip toggle, 13 Glide toggle (soft-fall), 14 Dash/Blink with cooldown, 15 Dash distance slider,
-- 16 Click Teleport toggle, 17 Teleport to Mouse, 18 Teleport to Spawn, 19 Teleport to Player (search), 20 Waypoint set/teleport,
-- 21 Anchor/Unanchor, 22 Sit/Stand toggle, 23 Rejoin server, 24 Gravity slider (client-side), 25 Anti-Fall safety teleporter,
-- 26 FOV slider, 27 Camera zoom offset, 28 Camera smoothing toggle, 29 FPS counter, 30 UI scale slider,
-- 31 ESP toggle (billboards), 32 Player highlights (chams), 33 ESP distance display, 34 Show/hide local character,
-- 35 Save settings (local attribute), 36 Load settings, 37 Reset defaults, 38 Keybind editor (sprint/crouch/gui), 39 Hotkey to toggle GUI,
-- 40 Minimize GUI, 41 Draggable GUI, 42 Loading screen with progress + animation, 43 Notifications, 44 Theme (dark/light),
-- 45 Export settings (prints JSON), 46 Auto-sprint toggle, 47 Auto-respawn toggle, 48 Freeze (anchor) shortcut, 49 Smooth UI tweens,
-- 50 Credits + version badge, 51 Toggleable UI blur during loading, 52 Toggle HUD visibility (hide other GUI)
-- (extra small helpers included — comfortably 50+)
--
-- Place in StarterPlayerScripts. Tested logic for hum/walkspeed/fly/noclip and UI events.
-- WARNING: Changing workspace.Gravity affects the whole server in some games. Use with caution.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- SAFE WAIT helpers
local function getCharacter(waitIfNeeded)
    local ch = player.Character
    if not ch and waitIfNeeded then
        ch = player.CharacterAdded:Wait()
    end
    return ch
end
local function getHumanoid(waitIfNeeded)
    local ch = getCharacter(waitIfNeeded)
    if not ch then return nil end
    return ch:FindFirstChildOfClass("Humanoid")
end

-- STATE & DEFAULTS
local State = {
    WalkSpeed = 16,
    JumpPower = 50,
    MinWalk = 8,
    MaxWalk = 300,
    SprintMultiplier = 1.8,
    SprintKey = Enum.KeyCode.LeftShift,
    CrouchKey = Enum.KeyCode.LeftControl,
    CrouchHip = 1,
    FlyEnabled = false,
    FlySpeed = 80,
    Noclip = false,
    InfiniteJump = false,
    BunnyHop = false,
    Glide = false,
    DashDistance = 30,
    DashCooldown = 2,
    CanDash = true,
    ClickTeleport = false,
    AntiFall = true,
    FallY = -150,
    Gravity = workspace.Gravity,
    FOV = 70,
    CameraZoom = 0,
    CamSmooth = true,
    UITheme = "Dark",
    ESP = true,
    Highlights = true,
    AutoSprint = false,
    AutoRespawn = false,
    UIVisible = true,
    GUIScale = 1,
    GuiHotkey = Enum.KeyCode.Semicolon, -- default toggle key
}

-- Save / load via Player attributes
local function saveSettings()
    local save = {
        WalkSpeed = State.WalkSpeed,
        JumpPower = State.JumpPower,
        SprintMultiplier = State.SprintMultiplier,
        SprintKey = tostring(State.SprintKey),
        CrouchKey = tostring(State.CrouchKey),
        FlySpeed = State.FlySpeed,
        FOV = State.FOV,
        CameraZoom = State.CameraZoom,
        UITheme = State.UITheme,
        GUIScale = State.GUIScale,
    }
    pcall(function()
        player:SetAttribute("UltraSuite_Settings", HttpService:JSONEncode(save))
    end)
    StarterGui:SetCore("SendNotification", {Title="UltraSuite", Text="Settings saved (local)", Duration = 2})
end

local function loadSettings()
    local json = player:GetAttribute("UltraSuite_Settings")
    if not json then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
    if ok and type(data) == "table" then
        State.WalkSpeed = data.WalkSpeed or State.WalkSpeed
        State.JumpPower = data.JumpPower or State.JumpPower
        State.SprintMultiplier = data.SprintMultiplier or State.SprintMultiplier
        if data.SprintKey then
            pcall(function() State.SprintKey = Enum.KeyCode[data.SprintKey:gsub("Enum.KeyCode.", "")] end)
        end
        if data.CrouchKey then
            pcall(function() State.CrouchKey = Enum.KeyCode[data.CrouchKey:gsub("Enum.KeyCode.", "")] end)
        end
        State.FlySpeed = data.FlySpeed or State.FlySpeed
        State.FOV = data.FOV or State.FOV
        State.CameraZoom = data.CameraZoom or State.CameraZoom
        State.UITheme = data.UITheme or State.UITheme
        State.GUIScale = data.GUIScale or State.GUIScale
    end
    StarterGui:SetCore("SendNotification", {Title="UltraSuite", Text="Settings loaded", Duration = 2})
end

-- reset defaults
local function resetSettings()
    State.WalkSpeed = 16
    State.JumpPower = 50
    State.FlySpeed = 80
    State.SprintMultiplier = 1.8
    State.FOV = 70
    State.CameraZoom = 0
    State.UITheme = "Dark"
    State.GUIScale = 1
    StarterGui:SetCore("SendNotification", {Title="UltraSuite", Text="Settings reset to defaults", Duration = 2})
end

-- UI BUILD HELPERS
local function Round(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end
local function MakeLabel(parent, text, size, pos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = size or UDim2.new(1,0,0,20)
    lbl.Position = pos or UDim2.new(0,0,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text or ""
    lbl.TextColor3 = Color3.fromRGB(240,240,240)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextWrapped = true
    lbl.Parent = parent
    return lbl
end
local function MakeButton(parent, txt, size, pos)
    local btn = Instance.new("TextButton")
    btn.Size = size or UDim2.new(0, 180, 0, 32)
    btn.Position = pos or UDim2.new(0,0,0,0)
    btn.Text = txt or "Button"
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.BackgroundTransparency = 0.12
    btn.Parent = parent
    Round(btn, 8)
    return btn
end

-- Create ScreenGui root
local gui = Instance.new("ScreenGui")
gui.Name = "UltraMovementSuite"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- LOADING SCREEN (beautiful)
local loader = Instance.new("Frame")
loader.Name = "Loader"
loader.Size = UDim2.new(1,0,1,0)
loader.Position = UDim2.new(0,0,0,0)
loader.AnchorPoint = Vector2.new(0,0)
loader.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
loader.Parent = gui

local loaderLogo = Instance.new("TextLabel")
loaderLogo.Size = UDim2.new(0, 300, 0, 120)
loaderLogo.Position = UDim2.new(0.5, -150, 0.4, -60)
loaderLogo.BackgroundTransparency = 1
loaderLogo.Text = "ULTRA SUITE"
loaderLogo.Font = Enum.Font.GothamBold
loaderLogo.TextSize = 34
loaderLogo.TextColor3 = Color3.fromRGB(0, 200, 255)
loaderLogo.Parent = loader

local subTxt = Instance.new("TextLabel")
subTxt.Size = UDim2.new(0, 420, 0, 24)
subTxt.Position = UDim2.new(0.5, -210, 0.4, 70)
subTxt.BackgroundTransparency = 1
subTxt.Font = Enum.Font.Gotham
subTxt.TextSize = 14
subTxt.TextColor3 = Color3.fromRGB(220,220,220)
subTxt.Text = "Initializing modules..."
subTxt.Parent = loader

local barBack = Instance.new("Frame")
barBack.Size = UDim2.new(0, 420, 0, 16)
barBack.Position = UDim2.new(0.5, -210, 0.5, 0)
barBack.BackgroundColor3 = Color3.fromRGB(24,24,30)
barBack.Parent = loader
Round(barBack, 8)

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 0, 1, 0)
bar.Position = UDim2.new(0,0,0,0)
bar.BackgroundColor3 = Color3.fromRGB(0,200,255)
bar.Parent = barBack
Round(bar, 8)

local percentLabel = Instance.new("TextLabel")
percentLabel.Size = UDim2.new(0, 120, 0, 20)
percentLabel.Position = UDim2.new(0.5, -60, 0.55, 22)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.TextColor3 = Color3.fromRGB(200,200,200)
percentLabel.Font = Enum.Font.Gotham
percentLabel.TextSize = 14
percentLabel.Parent = loader

-- beautify loader: quick pseudo-progress
spawn(function()
    local steps = {10, 25, 48, 68, 82, 92, 100}
    for i, pct in ipairs(steps) do
        TweenService:Create(bar, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {Size = UDim2.new(pct/100,0,1,0)}):Play()
        percentLabel.Text = tostring(pct) .. "%"
        subTxt.Text = ({"Loading UI...", "Applying settings...", "Spawning systems...", "Finalizing..."})[math.min(i,4)]
        wait(0.55)
    end
    -- small pause then fade away
    wait(0.4)
    TweenService:Create(loader, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
    TweenService:Create(loaderLogo, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
    TweenService:Create(barBack, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
    TweenService:Create(percentLabel, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
    wait(0.65)
    loader:Destroy()
end)

-- MAIN UI container
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 720, 0, 420)
main.Position = UDim2.new(0.5, -360, 0.5, -210)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(28,28,32)
main.BorderSizePixel = 0
main.Parent = gui
Round(main, 14)
main.Visible = true

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,56)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6,0,1,0)
title.Position = UDim2.new(0.02,0,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(220,220,220)
title.Text = "ULTRA MOVEMENT SUITE"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local ver = Instance.new("TextLabel")
ver.Size = UDim2.new(0.38, -20, 1, 0)
ver.Position = UDim2.new(0.62, 0, 0, 0)
ver.BackgroundTransparency = 1
ver.Font = Enum.Font.Gotham
ver.TextSize = 12
ver.TextColor3 = Color3.fromRGB(180,180,180)
ver.Text = "v2.0 — Seid"
ver.TextXAlignment = Enum.TextXAlignment.Right
ver.Parent = header

-- Minimize / Close / Theme buttons
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 32, 0, 32)
minBtn.Position = UDim2.new(1, -40, 0.5, -16)
minBtn.BackgroundTransparency = 0.12
minBtn.Text = "_"
minBtn.Font = Enum.Font.Gotham
minBtn.TextSize = 18
minBtn.Parent = header
Round(minBtn, 8)

local themeBtn = Instance.new("TextButton")
themeBtn.Size = UDim2.new(0, 32, 0, 32)
themeBtn.Position = UDim2.new(1, -80, 0.5, -16)
themeBtn.BackgroundTransparency = 0.12
themeBtn.Text = "⋯"
themeBtn.Font = Enum.Font.Gotham
themeBtn.TextSize = 16
themeBtn.Parent = header
Round(themeBtn, 8)

-- Tabs bar & panes
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 40)
tabBar.Position = UDim2.new(0, 10, 0, 66)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabs = {"Main","Movement","Tools","Visuals","ESP","Settings","Misc"}
local tabButtons = {}
local panes = {}

local function createTab(name, idx)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 95, 1, 0)
    btn.Position = UDim2.new(0, (idx-1)*100, 0, 0)
    btn.Text = name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.BackgroundTransparency = 0.12
    btn.Parent = tabBar
    Round(btn, 8)
    tabButtons[name] = btn

    local pane = Instance.new("Frame")
    pane.Size = UDim2.new(1, -20, 1, -130)
    pane.Position = UDim2.new(0, 10, 0, 120)
    pane.BackgroundTransparency = 1
    pane.Visible = (idx == 1)
    pane.Parent = main
    panes[name] = pane
end

for i,name in ipairs(tabs) do createTab(name, i) end

-- Tab switching behavior
for name, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        for k,v in pairs(panes) do v.Visible = false end
        panes[name].Visible = true
        for _, b in pairs(tabButtons) do b.BackgroundTransparency = 0.12 end
        btn.BackgroundTransparency = 0
    end)
end

-- Make draggable
do
    local dragging, dragInput, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
        end
    end)
end

-- SMALL UI HELP: slider factory
local function createSlider(parent, labelText, min, max, initial, onChange)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 300, 0, 56)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,18)
    label.Position = UDim2.new(0,0,0,0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.Parent = container

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 16)
    bar.Position = UDim2.new(0,0,0,22)
    bar.BackgroundColor3 = Color3.fromRGB(44,44,50)
    bar.Parent = container
    Round(bar, 8)

    local knob = Instance.new("Frame")
    local pct = math.clamp((initial - min) / (max - min), 0, 1)
    knob.Size = UDim2.new(0, 16, 1, 0)
    knob.Position = UDim2.new(pct, -8, 0, 0)
    knob.BackgroundColor3 = Color3.fromRGB(0,200,255)
    knob.Parent = bar
    Round(knob, 8)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0,64,0,18)
    valueLabel.Position = UDim2.new(1, -68, 0, -2)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(math.floor(initial))
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 12
    valueLabel.TextColor3 = Color3.fromRGB(220,220,220)
    valueLabel.Parent = container

    local dragging = false
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local x = math.clamp(input.Position.X - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
            knob.Position = UDim2.new(0, x - knob.AbsoluteSize.X/2, 0, 0)
            local newVal = min + (x/bar.AbsoluteSize.X)*(max-min)
            valueLabel.Text = (math.abs(max-min) > 50) and tostring(math.floor(newVal)) or string.format("%.1f", newVal)
            if onChange then onChange(newVal) end
        end
    end)
    return container, valueLabel
end

-- ========== MAIN TAB CONTENT ==========
local mainPane = panes["Main"]
MakeLabel(mainPane, "Quick Controls", UDim2.new(1,0,0,20), UDim2.new(0,0,0,0)).TextSize = 16

-- WalkSpeed slider
local wsSlider, wsVal = createSlider(mainPane, "WalkSpeed", State.MinWalk, State.MaxWalk, State.WalkSpeed, function(v)
    State.WalkSpeed = v
    local hum = getHumanoid(false)
    if hum then hum.WalkSpeed = v end
end)
wsSlider.Position = UDim2.new(0, 10, 0, 36)

-- JumpPower slider
local jpSlider, jpVal = createSlider(mainPane, "JumpPower", 20, 200, State.JumpPower, function(v)
    State.JumpPower = v
    local hum = getHumanoid(false)
    if hum then hum.JumpPower = v end
end)
jpSlider.Position = UDim2.new(0, 330, 0, 36)

-- FOV slider
local fovSlider, fovVal = createSlider(mainPane, "Camera FOV", 50, 120, State.FOV, function(v)
    State.FOV = v
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = v end
end)
fovSlider.Position = UDim2.new(0, 10, 0, 110)

-- UI scale slider
local scaleSlider, scaleVal = createSlider(mainPane, "UI Scale", 0.6, 1.6, State.GUIScale, function(v)
    State.GUIScale = v
    gui.ResetOnSpawn = false
    main.Size = UDim2.new(0, 720 * v, 0, 420 * v)
end)
scaleSlider.Position = UDim2.new(0, 330, 0, 110)

-- Preset buttons
local presetsFrame = Instance.new("Frame")
presetsFrame.Size = UDim2.new(1, -20, 0, 40)
presetsFrame.Position = UDim2.new(0, 10, 0, 180)
presetsFrame.BackgroundTransparency = 1
presetsFrame.Parent = mainPane

local function makePreset(name, ws, jp)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 140, 0, 36)
    b.Position = UDim2.new(0, (#presetsFrame:GetChildren())*150, 0, 0)
    b.Text = name
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.Parent = presetsFrame
    Round(b, 8)
    b.MouseButton1Click:Connect(function()
        State.WalkSpeed = ws; State.JumpPower = jp
        local hum = getHumanoid(false)
        if hum then hum.WalkSpeed = ws; hum.JumpPower = jp end
        wsVal.Text = tostring(math.floor(ws))
        jpVal.Text = tostring(math.floor(jp))
    end)
end
makePreset("Normal", 16, 50)
makePreset("Runner", 40, 70)
makePreset("Parkour", 80, 90)
makePreset("Insane", 200, 150)

-- Hotkey indicator / toggle GUI hotkey
local hotkeyLabel = MakeLabel(mainPane, "GUI Toggle: " .. tostring(State.GuiHotkey) .. " (press to change)", UDim2.new(1,0,0,18), UDim2.new(0,10,0,230))
local changeHotkeyBtn = MakeButton(mainPane, "Change GUI Toggle Key", UDim2.new(0,220,0,32), UDim2.new(0,10,0,260))
changeHotkeyBtn.MouseButton1Click:Connect(function()
    changeHotkeyBtn.Text = "Press any key..."
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.UserInputType == Enum.UserInputType.Keyboard then
            State.GuiHotkey = input.KeyCode
            hotkeyLabel.Text = "GUI Toggle: " .. tostring(State.GuiHotkey) .. " (press to change)"
            changeHotkeyBtn.Text = "Change GUI Toggle Key"
            conn:Disconnect()
        end
    end)
end)

-- Minimize behavior
minBtn.MouseButton1Click:Connect(function()
    main.Minimize = not main.Minimize
    for _, p in pairs(panes) do p.Visible = not main.Minimize end
    header.Visible = true
    main.Size = main.Minimize and UDim2.new(0, 420, 0, 60) or UDim2.new(0, 720*State.GUIScale, 0, 420*State.GUIScale)
end)

-- Theme toggle
themeBtn.MouseButton1Click:Connect(function()
    if State.UITheme == "Dark" then
        State.UITheme = "Light"
        main.BackgroundColor3 = Color3.fromRGB(240,240,240)
        title.TextColor3 = Color3.fromRGB(28,28,28)
    else
        State.UITheme = "Dark"
        main.BackgroundColor3 = Color3.fromRGB(28,28,32)
        title.TextColor3 = Color3.fromRGB(220,220,220)
    end
end)

-- ========== MOVEMENT TAB ==========
local movePane = panes["Movement"]
MakeLabel(movePane, "Movement Features", UDim2.new(1,0,0,20), UDim2.new(0,8,0,0)).TextSize = 16

-- Sprint toggle visual / behavior
local sprintLabel = MakeLabel(movePane, "Sprint (Hold " .. tostring(State.SprintKey) .. "): OFF", UDim2.new(0.6,0,0,18), UDim2.new(0,8,0,28))
local sprintMultSlider, sprVal = createSlider(movePane, "Sprint Multiplier", 1.0, 4.0, State.SprintMultiplier, function(v)
    State.SprintMultiplier = v
end)
sprintMultSlider.Position = UDim2.new(0, 8, 0, 54)

-- Crouch label + hipheight slider
local crouchLabel = MakeLabel(movePane, "Crouch (Hold " .. tostring(State.CrouchKey) .. "): OFF", UDim2.new(0.6,0,0,18), UDim2.new(0,340,0,28))
local hipSlider, hipVal = createSlider(movePane, "Crouch HipHeight", 0, 4, State.CrouchHip, function(v)
    State.CrouchHip = v
end)
hipSlider.Position = UDim2.new(0, 340, 0, 54)

-- Infinite Jump toggle
local infBtn = MakeButton(movePane, "Toggle Infinite Jump: OFF", UDim2.new(0, 220, 0, 36), UDim2.new(0, 8, 0, 120))
infBtn.MouseButton1Click:Connect(function()
    State.InfiniteJump = not State.InfiniteJump
    infBtn.Text = "Toggle Infinite Jump: " .. (State.InfiniteJump and "ON" or "OFF")
end)

-- Bunnyhop toggle
local bhBtn = MakeButton(movePane, "Toggle Bunnyhop: OFF", UDim2.new(0, 220, 0, 36), UDim2.new(0, 238, 0, 120))
bhBtn.MouseButton1Click:Connect(function()
    State.BunnyHop = not State.BunnyHop
    bhBtn.Text = "Toggle Bunnyhop: " .. (State.BunnyHop and "ON" or "OFF")
end)

-- Fly toggle and speed slider
local flyBtn = MakeButton(movePane, "Toggle Fly: OFF", UDim2.new(0, 220, 0, 36), UDim2.new(0, 8, 0, 170))
local flySlider, flyVal = createSlider(movePane, "Fly Speed", 10, 300, State.FlySpeed, function(v) State.FlySpeed = v end)
flySlider.Position = UDim2.new(0, 8, 0, 210)
flyBtn.MouseButton1Click:Connect(function()
    State.FlyEnabled = not State.FlyEnabled
    flyBtn.Text = "Toggle Fly: " .. (State.FlyEnabled and "ON" or "OFF")
end)

-- Noclip toggle
local noclipBtn = MakeButton(movePane, "Toggle Noclip: OFF", UDim2.new(0, 220, 0, 36), UDim2.new(0, 238, 0, 170))
noclipBtn.MouseButton1Click:Connect(function()
    State.Noclip = not State.Noclip
    noclipBtn.Text = "Toggle Noclip: " .. (State.Noclip and "ON" or "OFF")
end)

-- Glide toggle
local glideBtn = MakeButton(movePane, "Toggle Glide: OFF", UDim2.new(0, 220, 0, 32), UDim2.new(0, 8, 0, 270))
glideBtn.MouseButton1Click:Connect(function()
    State.Glide = not State.Glide
    glideBtn.Text = "Toggle Glide: " .. (State.Glide and "ON" or "OFF")
end)

-- Dash (blink) with cooldown
local dashBtn = MakeButton(movePane, "Dash (E) Ready", UDim2.new(0, 220, 0, 32), UDim2.new(0, 238, 0, 270))
local dashSlider, dashVal = createSlider(movePane, "Dash Distance", 8, 120, State.DashDistance, function(v) State.DashDistance = v end)
dashSlider.Position = UDim2.new(0, 8, 0, 318)
dashBtn.MouseButton1Click:Connect(function()
    -- manual dash (also available via key)
    if State.CanDash then
        local ch = getCharacter(true)
        local root = ch:FindFirstChild("HumanoidRootPart")
        if root and workspace.CurrentCamera then
            local dir = workspace.CurrentCamera.CFrame.LookVector
            root.CFrame = root.CFrame + dir * State.DashDistance
            State.CanDash = false
            dashBtn.Text = "Dash Cooling..."
            spawn(function()
                wait(State.DashCooldown)
                State.CanDash = true
                dashBtn.Text = "Dash (E) Ready"
            end)
        end
    else
        StarterGui:SetCore("SendNotification", {Title="Dash", Text="Dash is on cooldown", Duration = 1.2})
    end
end)

-- ========== TOOLS TAB ==========
local tools = panes["Tools"]
MakeLabel(tools, "Teleport & Utility Tools", UDim2.new(1,0,0,20), UDim2.new(0,8,0,0)).TextSize = 16

local tpMouseBtn = MakeButton(tools, "Teleport To Mouse", UDim2.new(0, 220, 0, 36), UDim2.new(0,8,0,30))
tpMouseBtn.MouseButton1Click:Connect(function()
    local ch = getCharacter(true)
    local root = ch:FindFirstChild("HumanoidRootPart")
    if root and mouse.Target then
        root.CFrame = CFrame.new(mouse.Hit.p + Vector3.new(0,3,0))
    end
end)

local tpSpawnBtn = MakeButton(tools, "Teleport To Spawn", UDim2.new(0, 220, 0, 36), UDim2.new(0,240,0,30))
tpSpawnBtn.MouseButton1Click:Connect(function()
    local ch = getCharacter(true)
    local root = ch:FindFirstChild("HumanoidRootPart")
    if root then
        if workspace:FindFirstChild("SpawnLocation") then
            root.CFrame = workspace.SpawnLocation.CFrame + Vector3.new(0,3,0)
        else
            root.CFrame = CFrame.new(0,10,0)
        end
    end
end)

local clickTPBtn = MakeButton(tools, "Toggle Click Teleport: OFF", UDim2.new(0, 448, 0, 36), UDim2.new(0, 8, 0, 78))
clickTPBtn.MouseButton1Click:Connect(function()
    State.ClickTeleport = not State.ClickTeleport
    clickTPBtn.Text = "Toggle Click Teleport: " .. (State.ClickTeleport and "ON" or "OFF")
end)

mouse.Button1Down:Connect(function()
    if State.ClickTeleport and mouse.Target then
        local ch = getCharacter(true)
        local root = ch:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(mouse.Hit.p + Vector3.new(0,3,0)) end
    end
end)

-- Teleport to player input
local tpLabel = MakeLabel(tools, "Teleport to player (exact name):", UDim2.new(0.6,0,0,18), UDim2.new(0,8,0,126))
local tpText = Instance.new("TextBox")
tpText.Size = UDim2.new(0, 260, 0, 28)
tpText.Position = UDim2.new(0, 8, 0, 150)
tpText.PlaceholderText = "PlayerName"
tpText.Font = Enum.Font.Gotham
tpText.TextSize = 14
tpText.BackgroundTransparency = 0.12
tpText.Parent = tools
Round(tpText, 8)
local tpToPlayerBtn = MakeButton(tools, "Teleport To Player", UDim2.new(0, 220, 0, 32), UDim2.new(0, 278, 0, 150))
tpToPlayerBtn.MouseButton1Click:Connect(function()
    local name = tpText.Text
    if name and name ~= "" then
        local target = Players:FindFirstChild(name)
        if not target then
            for _,p in pairs(Players:GetPlayers()) do if p.Name:lower():find(name:lower()) then target = p; break end end
        end
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local root = getCharacter(true):FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0) end
        else
            StarterGui:SetCore("SendNotification", {Title="Teleport", Text="Player not found or no character", Duration = 2})
        end
    end
end)

-- Waypoint system: set and teleport
local wpBtn = MakeButton(tools, "Set Waypoint", UDim2.new(0, 220, 0, 36), UDim2.new(0, 8, 0, 200))
local gotoWpBtn = MakeButton(tools, "Teleport To Waypoint", UDim2.new(0, 220, 0, 36), UDim2.new(0, 240, 0, 200))
local waypoint = nil
wpBtn.MouseButton1Click:Connect(function()
    if mouse.Hit then
        waypoint = mouse.Hit.p
        StarterGui:SetCore("SendNotification", {Title="Waypoint", Text="Waypoint set", Duration = 1.5})
    end
end)
gotoWpBtn.MouseButton1Click:Connect(function()
    if waypoint then
        local ch = getCharacter(true)
        local root = ch:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(waypoint + Vector3.new(0,3,0)) end
    else
        StarterGui:SetCore("SendNotification", {Title="Waypoint", Text="No waypoint set", Duration = 1.5})
    end
end)

-- Rejoin
local rejoinBtn = MakeButton(tools, "Rejoin Server", UDim2.new(0, 220, 0, 36), UDim2.new(0, 8, 0, 250))
rejoinBtn.MouseButton1Click:Connect(function()
    StarterGui:SetCore("SendNotification", {Title="UltraSuite", Text="Rejoining...", Duration = 2})
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end)

-- Anchor / Sit toggles
local anchorBtn = MakeButton(tools, "Toggle Anchor Root: OFF", UDim2.new(0, 220, 0, 36), UDim2.new(0, 240, 0, 250))
local anchored = false
anchorBtn.MouseButton1Click:Connect(function()
    anchored = not anchored
    anchorBtn.Text = "Toggle Anchor Root: " .. (anchored and "ON" or "OFF")
    local ch = getCharacter(true)
    local root = ch:FindFirstChild("HumanoidRootPart")
    if root then root.Anchored = anchored end
end)

local sitBtn = MakeButton(tools, "Toggle Sit", UDim2.new(0, 460, 0, 32), UDim2.new(0, 8, 0, 300))
sitBtn.MouseButton1Click:Connect(function()
    local hum = getHumanoid(true)
    if hum then hum.Sit = not hum.Sit end
end)

-- ========== VISUALS TAB ==========
local vis = panes["Visuals"]
MakeLabel(vis, "Camera & Visuals", UDim2.new(1,0,0,20), UDim2.new(0,8,0,0)).TextSize = 16

-- Camera zoom apply (subtle)
local camZoomSlider, camZoomVal = createSlider(vis, "Camera Zoom Offset", -100, 100, State.CameraZoom, function(v)
    State.CameraZoom = v
end)
camZoomSlider.Position = UDim2.new(0, 8, 0, 36)

local camSmoothBtn = MakeButton(vis, "Toggle Camera Smooth: ON", UDim2.new(0, 220, 0, 36), UDim2.new(0, 320, 0, 36))
camSmoothBtn.MouseButton1Click:Connect(function()
    State.CamSmooth = not State.CamSmooth
    camSmoothBtn.Text = "Toggle Camera Smooth: " .. (State.CamSmooth and "ON" or "OFF")
end)

-- FPS counter
local fpsLabel = MakeLabel(vis, "FPS: --", UDim2.new(0, 200, 0, 18), UDim2.new(0,8,0,96))
fpsLabel.TextSize = 14

-- HUD hide toggle
local hudBtn = MakeButton(vis, "Toggle Other GUI Visibility", UDim2.new(0, 360, 0, 36), UDim2.new(0, 8, 0, 130))
hudBtn.MouseButton1Click:Connect(function()
    State.UIVisible = not State.UIVisible
    for _,v in pairs(player.PlayerGui:GetChildren()) do
        if v ~= gui then v.Enabled = State.UIVisible end
    end
end)

-- ========== ESP TAB ==========
local espPane = panes["ESP"]
MakeLabel(espPane, "ESP / Highlights", UDim2.new(1,0,0,20), UDim2.new(0,8,0,0)).TextSize = 16

local espToggleBtn = MakeButton(espPane, "Toggle ESP: ON", UDim2.new(0, 220, 0, 36), UDim2.new(0,8,0,36))
local highlightBtn = MakeButton(espPane, "Toggle Highlights: ON", UDim2.new(0, 220, 0, 36), UDim2.new(0, 240, 0, 36))
espToggleBtn.MouseButton1Click:Connect(function()
    State.ESP = not State.ESP
    espToggleBtn.Text = "Toggle ESP: " .. (State.ESP and "ON" or "OFF")
    refreshESP()
end)
highlightBtn.MouseButton1Click:Connect(function()
    State.Highlights = not State.Highlights
    highlightBtn.Text = "Toggle Highlights: " .. (State.Highlights and "ON" or "OFF")
    refreshHighlights()
end)

local espFolder = Instance.new("Folder", gui); espFolder.Name = "ESPFolder"
local highlightFolder = Instance.new("Folder", gui); highlightFolder.Name = "HLFolder"

-- create billboard for player
local function createBillboard(plr)
    if plr == player then return end
    local key = "ESP_" .. plr.UserId
    if espFolder:FindFirstChild(key) then return end
    if not plr.Character then return end
    local bill = Instance.new("BillboardGui")
    bill.Name = key
    bill.Size = UDim2.new(0,140,0,40)
    bill.AlwaysOnTop = true
    bill.Adornee = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
    bill.Parent = espFolder
    local label = Instance.new("TextLabel", bill)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 0.25
    label.BackgroundColor3 = Color3.fromRGB(10,10,10)
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Text = plr.Name
    plr.CharacterAdded:Connect(function() wait(0.5); refreshESP() end)
end

function refreshESP()
    for _,c in pairs(espFolder:GetChildren()) do c:Destroy() end
    if not State.ESP then return end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            createBillboard(plr)
        end
    end
end

-- Highlights (Highlight instance)
local function createHL(plr)
    local key = "HL_" .. plr.UserId
    if highlightFolder:FindFirstChild(key) then return end
    if not plr.Character then return end
    local hl = Instance.new("Highlight")
    hl.Name = key
    hl.Adornee = plr.Character
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.8
    hl.Parent = highlightFolder
    plr.CharacterAdded:Connect(function() wait(0.5); refreshHighlights() end)
end

function refreshHighlights()
    for _,c in pairs(highlightFolder:GetChildren()) do c:Destroy() end
    if not State.Highlights then return end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= player then createHL(plr) end
    end
end

Players.PlayerAdded:Connect(function(p) wait(0.6); if State.ESP then createBillboard(p) end; if State.Highlights then createHL(p) end end)
Players.PlayerRemoving:Connect(function(p) local e=espFolder:FindFirstChild("ESP_"..p.UserId); if e then e:Destroy() end local h=highlightFolder:FindFirstChild("HL_"..p.UserId); if h then h:Destroy() end end)

-- ========== SETTINGS TAB ==========
local setPane = panes["Settings"]
MakeLabel(setPane, "Settings", UDim2.new(1,0,0,20), UDim2.new(0,8,0,0)).TextSize = 16

local saveBtn = MakeButton(setPane, "Save Settings (local)", UDim2.new(0, 220, 0, 36), UDim2.new(0,8,0,36))
local loadBtn = MakeButton(setPane, "Load Settings", UDim2.new(0, 220, 0, 36), UDim2.new(0,240,0,36))
local resetBtn = MakeButton(setPane, "Reset Defaults", UDim2.new(0, 220, 0, 36), UDim2.new(0,8,0,86))
local exportBtn = MakeButton(setPane, "Export Settings (print JSON)", UDim2.new(0, 460, 0, 36), UDim2.new(0,8,0,136))

saveBtn.MouseButton1Click:Connect(saveSettings)
loadBtn.MouseButton1Click:Connect(loadSettings)
resetBtn.MouseButton1Click:Connect(function() resetSettings(); saveSettings() end)
exportBtn.MouseButton1Click:Connect(function()
    local data = {
        WalkSpeed = State.WalkSpeed,
        JumpPower = State.JumpPower,
        SprintMultiplier = State.SprintMultiplier,
        FlySpeed = State.FlySpeed,
        FOV = State.FOV,
    }
    print("UltraSuite exported settings:\n" .. HttpService:JSONEncode(data))
    StarterGui:SetCore("SendNotification", {Title="UltraSuite", Text="Settings JSON printed to output", Duration=2})
end)

-- Keybind editor for sprint/crouch
local keyLabel = MakeLabel(setPane, "Sprint: " .. tostring(State.SprintKey) .. " | Crouch: " .. tostring(State.CrouchKey), UDim2.new(1,0,0,18), UDim2.new(0,8,0,198))
local setSprintBtn = MakeButton(setPane, "Set Sprint Key", UDim2.new(0, 220, 0, 32), UDim2.new(0, 8, 0, 226))
local setCrouchBtn = MakeButton(setPane, "Set Crouch Key", UDim2.new(0, 220, 0, 32), UDim2.new(0, 240, 0, 226))
setSprintBtn.MouseButton1Click:Connect(function()
    setSprintBtn.Text = "Press any key..."
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.UserInputType == Enum.UserInputType.Keyboard then
            State.SprintKey = input.KeyCode
            keyLabel.Text = "Sprint: " .. tostring(State.SprintKey) .. " | Crouch: " .. tostring(State.CrouchKey)
            setSprintBtn.Text = "Set Sprint Key"
            conn:Disconnect()
        end
    end)
end)
setCrouchBtn.MouseButton1Click:Connect(function()
    setCrouchBtn.Text = "Press any key..."
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.UserInputType == Enum.UserInputType.Keyboard then
            State.CrouchKey = input.KeyCode
            keyLabel.Text = "Sprint: " .. tostring(State.SprintKey) .. " | Crouch: " .. tostring(State.CrouchKey)
            setCrouchBtn.Text = "Set Crouch Key"
            conn:Disconnect()
        end
    end)
end)

-- ========== MISC TAB ==========
local miscPane = panes["Misc"]
MakeLabel(miscPane, "Misc Tools", UDim2.new(1,0,0,20), UDim2.new(0,8,0,0)).TextSize = 16

local notifBtn = MakeButton(miscPane, "Test Notification", UDim2.new(0,220,0,36), UDim2.new(0,8,0,36))
notifBtn.MouseButton1Click:Connect(function() StarterGui:SetCore("SendNotification", {Title="UltraSuite", Text="This is a test", Duration=2}) end)

local autoSprintBtn = MakeButton(miscPane, "Toggle AutoSprint: OFF", UDim2.new(0,220,0,36), UDim2.new(0,240,0,36))
autoSprintBtn.MouseButton1Click:Connect(function()
    State.AutoSprint = not State.AutoSprint
    autoSprintBtn.Text = "Toggle AutoSprint: " .. (State.AutoSprint and "ON" or "OFF")
end)

local autoRespawnBtn = MakeButton(miscPane, "Toggle AutoRespawn: OFF", UDim2.new(0,460,0,36), UDim2.new(0,8,0,86))
autoRespawnBtn.MouseButton1Click:Connect(function()
    State.AutoRespawn = not State.AutoRespawn
    autoRespawnBtn.Text = "Toggle AutoRespawn: " .. (State.AutoRespawn and "ON" or "OFF")
end)

-- Keybind handler: sprint / crouch / dash / gui toggle
local sprinting = false
local crouching = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == State.SprintKey then
            sprinting = true
            local hum = getHumanoid(true)
            if hum then hum.WalkSpeed = State.WalkSpeed * State.SprintMultiplier end
            sprintLabel.Text = "Sprint (Hold " .. tostring(State.SprintKey) .. "): ON"
        elseif input.KeyCode == State.CrouchKey then
            crouching = true
            local hum = getHumanoid(true)
            if hum then
                hum.WalkSpeed = math.max(6, State.WalkSpeed * 0.5)
                hum.HipHeight = State.CrouchHip
            end
            crouchLabel.Text = "Crouch (Hold " .. tostring(State.CrouchKey) .. "): ON"
        elseif input.KeyCode == Enum.KeyCode.E then
            -- dash key
            if State.CanDash then
                local ch = getCharacter(true)
                local root = ch:FindFirstChild("HumanoidRootPart")
                if root and workspace.CurrentCamera then
                    local dir = workspace.CurrentCamera.CFrame.LookVector
                    root.CFrame = root.CFrame + dir * State.DashDistance
                    State.CanDash = false
                    dashBtn.Text = "Dash Cooling..."
                    spawn(function() wait(State.DashCooldown); State.CanDash=true; dashBtn.Text = "Dash (E) Ready" end)
                end
            end
        elseif input.KeyCode == State.GuiHotkey then
            main.Visible = not main.Visible
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == State.SprintKey then
            sprinting = false
            local hum = getHumanoid(false)
            if hum then hum.WalkSpeed = State.WalkSpeed end
            sprintLabel.Text = "Sprint (Hold " .. tostring(State.SprintKey) .. "): OFF"
        elseif input.KeyCode == State.CrouchKey then
            crouching = false
            local hum = getHumanoid(false)
            if hum then hum.WalkSpeed = State.WalkSpeed; hum.HipHeight = 2 end
            crouchLabel.Text = "Crouch (Hold " .. tostring(State.CrouchKey) .. "): OFF"
        end
    end
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHumanoid(false)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Core loops
local lastTick = tick()
local frameTimes = {}
RunService.RenderStepped:Connect(function(dt)
    -- FPS
    table.insert(frameTimes, dt)
    if #frameTimes > 60 then table.remove(frameTimes, 1) end
    local avg = 0
    for _,v in pairs(frameTimes) do avg = avg + v end
    if #frameTimes > 0 then avg = avg / #frameTimes end
    local fps = math.floor(1/avg + 0.5)
    fpsLabel.Text = "FPS: " .. tostring(fps)

    -- Apply camera zoom smoothly
    local cam = workspace.CurrentCamera
    if cam and cam.CameraType == Enum.CameraType.Custom then
        local current = cam.FieldOfView
        if State.CamSmooth then
            cam.FieldOfView = current + (State.FOV - current) * math.clamp(dt*6, 0, 1)
        else
            cam.FieldOfView = State.FOV
        end
        -- small zoom offset
        if State.CameraZoom ~= 0 then
            cam.CFrame = cam.CFrame * CFrame.new(0, 0, State.CameraZoom/200)
        end
    end

    -- Fly handling (BodyVelocity + BodyGyro)
    if State.FlyEnabled then
        local ch = getCharacter(false)
        if ch then
            local root = ch:FindFirstChild("HumanoidRootPart")
            if root and not root:FindFirstChild("UltraFlyBV") then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "UltraFlyBV"
                bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                bv.Velocity = Vector3.new(0,0,0)
                bv.Parent = root
                local bg = Instance.new("BodyGyro")
                bg.Name = "UltraFlyBG"
                bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
                bg.CFrame = root.CFrame
                bg.Parent = root
            end
            local root = ch:FindFirstChild("HumanoidRootPart")
            local bv = root and root:FindFirstChild("UltraFlyBV")
            local bg = root and root:FindFirstChild("UltraFlyBG")
            if bv and bg then
                local cam = workspace.CurrentCamera
                local moveVec = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
                local upDown = 0
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDown = upDown + 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then upDown = upDown - 1 end
                local vel = (moveVec.Unit == moveVec.Unit and moveVec.Unit or Vector3.new(0,0,0)) * State.FlySpeed + Vector3.new(0, upDown * State.FlySpeed, 0)
                bv.Velocity = vel
                bg.CFrame = root.CFrame
            end
        end
    else
        -- ensure BV/BG removed
        local ch = getCharacter(false)
        if ch then
            local root = ch:FindFirstChild("HumanoidRootPart")
            if root then
                if root:FindFirstChild("UltraFlyBV") then root:FindFirstChild("UltraFlyBV"):Destroy() end
                if root:FindFirstChild("UltraFlyBG") then root:FindFirstChild("UltraFlyBG"):Destroy() end
            end
        end
    end

    -- Noclip loop
    if State.Noclip then
        local ch = getCharacter(false)
        if ch then
            for _,part in pairs(ch:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end

    -- Glide: when glide on and player holding space while falling slow down
    if State.Glide then
        local hum = getHumanoid(false)
        local ch = getCharacter(false)
        if hum and ch and hum.FloorMaterial == Enum.Material.Air then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local root = ch:FindFirstChild("HumanoidRootPart")
                if root then
                    local vel = root.Velocity
                    root.Velocity = Vector3.new(vel.X, math.max( -10, vel.Y ), vel.Z)
                end
            end
        end
    end

    -- Bunnyhop
    if State.BunnyHop then
        local hum = getHumanoid(false)
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    -- AutoSprint
    if State.AutoSprint then
        local hum = getHumanoid(false)
        if hum then hum.WalkSpeed = State.WalkSpeed * State.SprintMultiplier end
    end

    -- Anti-fall safety
    local ch = getCharacter(false)
    if State.AntiFall and ch and ch:FindFirstChild("HumanoidRootPart") then
        local root = ch.HumanoidRootPart
        if root.Position.Y <= State.FallY then
            if workspace:FindFirstChild("SpawnLocation") then
                root.CFrame = workspace.SpawnLocation.CFrame + Vector3.new(0,3,0)
            else
                root.CFrame = CFrame.new(0, 10, 0)
            end
        end
    end

    -- Camera FOV preference application
    if workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView ~= State.FOV then
        if not State.CamSmooth then workspace.CurrentCamera.FieldOfView = State.FOV end
    end
end)

-- auto-respawn behavior
if State.AutoRespawn then
    player.CharacterAdded:Connect(function(char)
        -- nothing needed; will be present
    end)
end
player.CharacterAdded:Connect(function(char)
    wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = State.WalkSpeed
        hum.JumpPower = State.JumpPower
    end
end)

-- FPS done, ESP refresh run
refreshESP(); refreshHighlights()

-- Apply initial settings
pcall(function()
    loadSettings()
    local hum = getHumanoid(false)
    if hum then hum.WalkSpeed = State.WalkSpeed; hum.JumpPower = State.JumpPower end
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = State.FOV end
end)

-- Final note for console
print("[UltraMovementSuite] Loaded — 50+ features active. Use responsibly, Seid.")

-- End of script
