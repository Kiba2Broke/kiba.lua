
local Players = game:Get-- LocalScript in StarterPlayerScripts
Service("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- Settings
local ORBIT_RADIUS  = 2.5
local ORBIT_SPEED   = 900
local ORBIT_Y       = 4
local KNIFE_OFFSET  = 2
local KNIFE_Y       = 0

-- State
local mode         = nil
local angle        = 0
local lockedTarget = nil
local lockedName   = ""

-- Find closest enemy (skips teammates)
local function findClosestTarget()
    local myChar = localPlayer.Character
    if not myChar then return nil, "" end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, "" end
    local closest, closestName, closestDist = nil, "", math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            -- skip teammates
            if p.Team ~= localPlayer.Team or p.Team == nil or localPlayer.Team == nil then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d = (r.Position - myRoot.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest     = r
                        closestName = p.Name
                    end
                end
            end
        end
    end
    return closest, closestName
end

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KibaGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 170)
frame.Position = UDim2.new(0.5, -120, 0, 16)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BorderSizePixel = 0
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(200, 30, 30)
frameStroke.Thickness = 1.5
frameStroke.Parent = frame

-- Drag
local dragBar = Instance.new("Frame")
dragBar.Size = UDim2.new(1, 0, 0, 36)
dragBar.BackgroundTransparency = 1
dragBar.ZIndex = 2
dragBar.Parent = frame

local dragging, dragStart, startPos = false, nil, nil
dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = frame.Position
    end
end)
dragBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.Text = "kiba.lua"
title.TextColor3 = Color3.fromRGB(220, 40, 40)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.ZIndex = 2
title.Parent = frame

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.85, 0, 0, 1)
divider.Position = UDim2.new(0.075, 0, 0, 36)
divider.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
divider.BackgroundTransparency = 0.6
divider.BorderSizePixel = 0
divider.Parent = frame

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 22)
statusLabel.Position = UDim2.new(0, 8, 0, 42)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "target: none"
statusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = frame

-- Mode label
local phaseLabel = Instance.new("TextLabel")
phaseLabel.Size = UDim2.new(1, -16, 0, 20)
phaseLabel.Position = UDim2.new(0, 8, 0, 64)
phaseLabel.BackgroundTransparency = 1
phaseLabel.Text = "mode: --"
phaseLabel.TextColor3 = Color3.fromRGB(220, 40, 40)
phaseLabel.TextXAlignment = Enum.TextXAlignment.Left
phaseLabel.TextScaled = true
phaseLabel.Font = Enum.Font.Gotham
phaseLabel.Parent = frame

-- Button factory
local function makeButton(text, pos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 98, 0, 34)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 40, 40)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(200, 30, 30)
    s.Thickness = 1
    s.Parent = btn
    return btn
end

local orbitBtn = makeButton("ORBIT", UDim2.new(0, 14,  0, 96))
local knifeBtn = makeButton("KNIFE", UDim2.new(0, 128, 0, 96))

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.85, 0, 0, 28)
stopBtn.Position = UDim2.new(0.075, 0, 0, 136)
stopBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
stopBtn.BorderSizePixel = 0
stopBtn.Text = "STOP"
stopBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
stopBtn.TextScaled = true
stopBtn.Font = Enum.Font.GothamBold
stopBtn.Parent = frame
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)
local stopStroke = Instance.new("UIStroke")
stopStroke.Color = Color3.fromRGB(100, 100, 100)
stopStroke.Thickness = 1
stopStroke.Parent = stopBtn

-- Button logic
local function setActive(newMode)
    lockedTarget, lockedName = findClosestTarget()
    if not lockedTarget then
        statusLabel.Text = "no enemy found"
        return
    end
    mode  = newMode
    angle = 0
    statusLabel.Text = "target: " .. lockedName
    orbitBtn.BackgroundColor3 = newMode == "orbit"
        and Color3.fromRGB(50, 10, 10) or Color3.fromRGB(25, 25, 25)
    knifeBtn.BackgroundColor3 = newMode == "knife"
        and Color3.fromRGB(50, 10, 10) or Color3.fromRGB(25, 25, 25)
end

local function stopAll()
    mode         = nil
    lockedTarget = nil
    lockedName   = ""
    orbitBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    knifeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    statusLabel.Text = "target: none"
    phaseLabel.Text  = "mode: --"
    local char = localPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = root.CFrame + Vector3.new(0, 5, 0) end
    end
end

orbitBtn.MouseButton1Click:Connect(function() setActive("orbit") end)
knifeBtn.MouseButton1Click:Connect(function() setActive("knife") end)
stopBtn.MouseButton1Click:Connect(stopAll)

-- Re-snap after respawn
localPlayer.CharacterAdded:Connect(function(character)
    if mode == "knife" and lockedTarget then
        task.wait(0.5)
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and lockedTarget.Parent then
            local behindCF = lockedTarget.CFrame * CFrame.new(0, 0, KNIFE_OFFSET)
            local finalPos = Vector3.new(
                behindCF.Position.X,
                lockedTarget.Position.Y + KNIFE_Y,
                behindCF.Position.Z
            )
            local headPos = lockedTarget.Position + Vector3.new(0, 1.5, 0)
            root.CFrame = CFrame.new(finalPos, headPos)
        end
    end
end)

-- Main loop
RunService.Heartbeat:Connect(function(dt)
    if not mode then return end
    if not lockedTarget then return end

    local character = localPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if not lockedTarget.Parent then
        stopAll()
        return
    end

    local headPos = lockedTarget.Position + Vector3.new(0, 1.5, 0)

    if mode == "orbit" then
        phaseLabel.Text = "mode: orbit"
        angle = angle + ORBIT_SPEED * dt

        local orbitPos = Vector3.new(
            lockedTarget.Position.X + math.cos(angle) * ORBIT_RADIUS,
            lockedTarget.Position.Y + ORBIT_Y,
            lockedTarget.Position.Z + math.sin(angle) * ORBIT_RADIUS
        )

        root.CFrame = CFrame.new(orbitPos, headPos)

    elseif mode == "knife" then
        phaseLabel.Text = "mode: knife"

        local behindCF = lockedTarget.CFrame * CFrame.new(0, 0, KNIFE_OFFSET)
        local finalPos = Vector3.new(
            behindCF.Position.X,
            lockedTarget.Position.Y + KNIFE_Y,
            behindCF.Position.Z
        )
        root.CFrame = CFrame.new(finalPos, headPos)
    end
end)
