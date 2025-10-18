-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

------------------------------------------------------------
-- ⚙️ Services
------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

------------------------------------------------------------
-- 🎯 Combat Settings
------------------------------------------------------------
local Combat = {
    Aimlock = false,
    AutoAttack = false,
    AimlockTarget = nil,
    AttackCooldown = 0
}

local Movement = {
    SpeedEnabled = false,
    WalkSpeed = 16,
}

local ESP = {Enabled = false}
local Highlights = {}
local BillboardCache = {}

------------------------------------------------------------
-- (Other sections remain unchanged above)
------------------------------------------------------------
local Workspace = game:GetService("Workspace")
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

local function GetClosestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestPlayer = player
            end
        end
    end
    return nearestPlayer
end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "Raycast" then
        local origin = args[1]
        local direction = args[2]
        local result = oldNamecall(self, ...)
        local target = GetClosestPlayer()

        if target then
            return {
                Instance = target.Character.HumanoidRootPart,
                Position = target.Character.HumanoidRootPart.Position,
                Material = Enum.Material.Plastic
            }
        end

        return result
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

------------------------------------------------------------
-- ✈️ Fly Script
------------------------------------------------------------
local flying = false
local ctrl, lastctrl = {f=0,b=0,l=0,r=0}, {f=0,b=0,l=0,r=0}
local speed, maxspeed = 0, 50
local bg, bv

local function Fly()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChildOfClass("Humanoid")

    bg = Instance.new("BodyGyro", hrp)
    bg.P = 9e4
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = hrp.CFrame

    bv = Instance.new("BodyVelocity", hrp)
    bv.Velocity = Vector3.new(0, 0.1, 0)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    hum.PlatformStand = true

    while flying do
        task.wait()
        if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
            speed = math.clamp(speed + 0.5, 0, maxspeed)
        elseif speed ~= 0 then
            speed = math.clamp(speed - 1, 0, maxspeed)
        end

        if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
            bv.Velocity = ((workspace.CurrentCamera.CFrame.LookVector * (ctrl.f + ctrl.b))
                + ((workspace.CurrentCamera.CFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * .2, 0)).p
                - workspace.CurrentCamera.CFrame.p)) * speed
            lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
        elseif speed ~= 0 then
            bv.Velocity = ((workspace.CurrentCamera.CFrame.LookVector * (lastctrl.f + lastctrl.b))
                + ((workspace.CurrentCamera.CFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * .2, 0)).p
                - workspace.CurrentCamera.CFrame.p)) * speed
        else
            bv.Velocity = Vector3.new(0, 0.1, 0)
        end

        bg.CFrame = workspace.CurrentCamera.CFrame
    end

    hum.PlatformStand = false
    bg:Destroy()
    bv:Destroy()
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.W then ctrl.f = 1
    elseif input.KeyCode == Enum.KeyCode.S then ctrl.b = -1
    elseif input.KeyCode == Enum.KeyCode.A then ctrl.l = -1
    elseif input.KeyCode == Enum.KeyCode.D then ctrl.r = 1 end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then ctrl.f = 0
    elseif input.KeyCode == Enum.KeyCode.S then ctrl.b = 0
    elseif input.KeyCode == Enum.KeyCode.A then ctrl.l = 0
    elseif input.KeyCode == Enum.KeyCode.D then ctrl.r = 0 end
end)

------------------------------------------------------------
-- ⚔️ Combat / ESP / Movement / Misc Tabs (UI)
------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "⚡ Lynx Fruit Battlegrounds",
    LoadingTitle = "Created Menu",
    LoadingSubtitle = "By Elle",
    ConfigurationSaving = {Enabled = false}
})

-- Combat Tab
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)
CombatTab:CreateToggle({
    Name = "Aimlock (Auto-Aim Nearest Player)",
    CurrentValue = false,
    Callback = function(Value)
        Combat.Aimlock = Value
    end,
})
CombatTab:CreateParagraph({
    Title = "Info",
    Content = "Press [H] to toggle Auto-Attack.\nUse Aimlock to target nearest player."
})

-- Movement Tab
local MovementTab = Window:CreateTab("🏃 Movement", 4483362458)
MovementTab:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Callback = function(Value)
        Movement.SpeedEnabled = Value
    end,
})
MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        Movement.WalkSpeed = Value
    end,
})

-- ESP Tab
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)
ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(Value)
        ESP.Enabled = Value
    end,
})

-- Misc Tab
local MiscTab = Window:CreateTab("🔧 Misc", 4483362458)
MiscTab:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Callback = function(Value)
        flying = Value
        if flying then task.spawn(Fly) end
    end,
})
MiscTab:CreateButton({
    Name = "🗑️ Destroy UI & Stop Script",
    Callback = function()
        if Rayfield and Rayfield.Destroy then Rayfield:Destroy() end
        game.StarterGui:SetCore("SendNotification", {
            Title = "⚡ Lynx Battlegrounds",
            Text = "UI destroyed. Script stopped.",
            Duration = 3
        })
    end,
})

print("✅ Script Loaded — open Rayfield UI to toggle features.")
