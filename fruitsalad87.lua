
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
-- 💥 Hitbox Expander
------------------------------------------------------------
local hitboxEnabled = false
local hitboxSize = 20

-- Setup Collision Group
local function setupCollisionGroup()
    if not pcall(function() PhysicsService:CreateCollisionGroup("ExpandedHitboxes") end) then end
    pcall(function()
        PhysicsService:CollisionGroupSetCollidable("ExpandedHitboxes", "Default", false)
        PhysicsService:CollisionGroupSetCollidable("ExpandedHitboxes", "ExpandedHitboxes", false)
    end)
end
setupCollisionGroup()

-- Apply hitbox to a player
local function applyHitbox(player)
    task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end

        if hitboxEnabled then
            hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            hrp.Transparency = 0.9
            hrp.BrickColor = BrickColor.new("Really red")
            hrp.Material = Enum.Material.Neon
            hrp.CanCollide = false
            pcall(function()
                PhysicsService:SetPartCollisionGroup(hrp, "ExpandedHitboxes")
            end)
        else
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
            hrp.BrickColor = BrickColor.new("Medium stone grey")
            hrp.Material = Enum.Material.Plastic
            hrp.CanCollide = false
            pcall(function()
                PhysicsService:SetPartCollisionGroup(hrp, "Default")
            end)
        end
    end)
end

-- Apply hitbox updates to all players
local function updateAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            applyHitbox(player)
        end
    end
end

-- Character respawn handling
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        applyHitbox(player)
        player.CharacterAdded:Connect(function()
            applyHitbox(player)
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            applyHitbox(player)
        end)
    end
end)

------------------------------------------------------------
-- ✈️ Fly Script (MiscTab Toggle)
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

-- Fly movement controls (keep WASD)
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
-- 🎯 Combat System
------------------------------------------------------------
local function getNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return nil end
    local localHRP = localChar.HumanoidRootPart

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local distance = (hrp.Position - localHRP.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = player
                end
            end
        end
    end

    return nearestPlayer
end

-- Aimlock
RunService.RenderStepped:Connect(function()
    if Combat.Aimlock then
        local target = getNearestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            Combat.AimlockTarget = target
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.HumanoidRootPart.Position)
        else
            Combat.AimlockTarget = nil
        end
    else
        Combat.AimlockTarget = nil
    end
end)

RunService.Heartbeat:Connect(function()
    if Combat.AutoAttack then
        -- Instantly spam left clicks nonstop
        mouse1click()
    end
end)

------------------------------------------------------------
-- ⚡ H Key Toggle for Auto Attack
------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.H then
        Combat.AutoAttack = not Combat.AutoAttack
        local status = Combat.AutoAttack and "✅ Auto Attack Enabled" or "❌ Auto Attack Disabled"

        -- Notify on toggle
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {
                Title = "⚔️ Combat System",
                Text = status,
                Duration = 3
            })
        end)
    end
end)
------------------------------------------------------------
-- 🏃 Movement
------------------------------------------------------------
-- Speed Boost
RunService.Heartbeat:Connect(function()
    if Movement.SpeedEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = Movement.WalkSpeed
            end
        end
    end
end)

------------------------------------------------------------
-- 🧲 Teleport Magnet (Behind Player + MiscTab Slider)
------------------------------------------------------------
local currentTarget = nil
local magnetActive = false
local magnetDistance = 3 -- Default distance

-- 🔍 Find lowest health alive player
local function getLowestHealthPlayer()
    local lowestHealth = math.huge
    local target = nil
    local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localHRP then return nil end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                if hum.Health < lowestHealth then
                    lowestHealth = hum.Health
                    target = player
                end
            end
        end
    end
    return target
end

-- 🔁 Get another alive player (for manual switching)
local function getAnotherPlayer()
    local alivePlayers = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChildOfClass("Humanoid") 
           and player.Character:FindFirstChildOfClass("Humanoid").Health > 0
           and player ~= currentTarget then
            table.insert(alivePlayers, player)
        end
    end
    if #alivePlayers > 0 then
        return alivePlayers[math.random(1, #alivePlayers)]
    else
        return nil
    end
end

-- 🎯 Press J → switch to another player manually
LocalPlayer:GetMouse().KeyDown:Connect(function(key)
    if key:lower() == "j" and magnetActive then
        currentTarget = getAnotherPlayer()
    end
end)

-- 🔄 Follow behind target smoothly
RunService.Heartbeat:Connect(function()
    if magnetActive then
        if not currentTarget or not currentTarget.Character or not currentTarget.Character:FindFirstChild("HumanoidRootPart")
            or currentTarget.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            currentTarget = getLowestHealthPlayer()
            if not currentTarget then
                magnetActive = false
                return
            end
        end

        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetHRP = currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp and targetHRP then
            local behindPos = targetHRP.Position - (targetHRP.CFrame.LookVector * magnetDistance)
            hrp.CFrame = CFrame.new(behindPos, targetHRP.Position)
        end
    end
end)

------------------------------------------------------------
-- ⚔️ Auto Farm Level (Auto Skill Spam + Left Click | 0.05s Sync)
------------------------------------------------------------
local AutoFarm = {Enabled = false}
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Function to press key + left click
local function useSkillKeyFarm(key)
    -- Press key
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    
    -- Left click
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

-- Auto loop for skilling + clicking
task.spawn(function()
    while task.wait(0.05) do
        if AutoFarm.Enabled then
            useSkillKeyFarm("One")
            task.wait(0.5)
            useSkillKeyFarm("Two")
            task.wait(0.5)
            useSkillKeyFarm("Three")
            task.wait(0.5)
            useSkillKeyFarm("Four")
            task.wait(0.5)
            useSkillKeyFarm("Five")
            task.wait(0.5)
            useSkillKeyFarm("E")
            task.wait(0.5)
            useSkillKeyFarm("G")
            task.wait(0.5)
            useSkillKeyFarm("Six")
        end
    end
end)

------------------------------------------------------------
-- ⚔️ Auto Farm Level (1 Skill = 1 Click | Fast Version)
------------------------------------------------------------
local AutoPvp = {Enabled = false}
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Function: press skill key + click quickly
local function useSkillPvp(key)
    -- Press skill key
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.03)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)

    -- Quick left click right after skill
    task.wait(0.03)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.02)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

-- Auto loop (very fast skill+click cycle)
task.spawn(function()
    while task.wait(0.03) do
        if AutoPvp.Enabled then
            useSkillPvp("One")
            task.wait(0.15)
            useSkillPvp("Two")
            task.wait(0.15)
            useSkillPvp("Three")
            task.wait(0.15)
            useSkillPvp("Four")
            task.wait(0.15)
            useSkillPvp("Five")
            task.wait(0.15)
            useSkillWithClick("E")
            task.wait(0.15)
            useSkillPvp("G")
            task.wait(0.15)
            useSkillPvp("Six")
            task.wait(0.15)
        end
    end
end)
------------------------------------------------------------
-- 👻 Invisible Mode
------------------------------------------------------------
local Invisible = {Enabled = false}
local function setInvisibility(state)
    local char = LocalPlayer.Character
    if not char then return end

    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            if state then
                part.Transparency = 1
                if part:IsA("Decal") then part.Transparency = 1 end
            else
                if part.Name ~= "HumanoidRootPart" then
                    part.Transparency = 0
                end
            end
        elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
            part.Handle.Transparency = state and 1 or 0
        end
    end
end

-- Monitor invisibility on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    if Invisible.Enabled then
        task.wait(1)
        setInvisibility(true)
    end
end)


------------------------------------------------------------
-- 👁️ ESP
------------------------------------------------------------
-- Chams
local function createCham(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local char = player.Character
    if not char:FindFirstChild("HumanoidRootPart") then return end

    if Highlights[player] then
        Highlights[player]:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 170, 0)
    highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = char
    highlight.Parent = game.CoreGui

    Highlights[player] = highlight
end

local function removeCham(player)
    if Highlights[player] then
        Highlights[player]:Destroy()
        Highlights[player] = nil
    end
end

local function updateChams()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if ESP.Enabled then
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    createCham(player)
                else
                    removeCham(player)
                end
            else
                removeCham(player)
            end
        end
    end
end

Players.PlayerRemoving:Connect(removeCham)
RunService.Heartbeat:Connect(updateChams)

-- Billboard ESP
local function updateBillboards()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local distance = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            local billboard = BillboardCache[player]

            if ESP.Enabled then
                if not billboard then
                    billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(0, 50, 0, 15)
                    billboard.Adornee = hrp
                    billboard.AlwaysOnTop = true
                    billboard.Parent = game.CoreGui

                    local text = Instance.new("TextLabel", billboard)
                    text.Size = UDim2.new(1, 0, 1, 0)
                    text.BackgroundTransparency = 1
                    text.TextColor3 = Color3.fromRGB(255, 0, 0)
                    text.TextStrokeTransparency = 0.1
                    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    text.Font = Enum.Font.GothamBold
                    text.TextScaled = true
                    text.Name = "NameLabel"

                    BillboardCache[player] = billboard
                end
                billboard.Enabled = true
                billboard.NameLabel.Text = string.format("%s [%dm]", player.Name, math.floor(distance))
            else
                if billboard then billboard.Enabled = false end
            end
        elseif BillboardCache[player] then
            BillboardCache[player].Enabled = false
        end
    end
end
RunService.RenderStepped:Connect(updateBillboards)

------------------------------------------------------------
-- 🎛️ Rayfield UI
------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "⚡ Lynx Fruit Battlegrounds",
    LoadingTitle = "Created Menu",
    LoadingSubtitle = "By Elle",
    ConfigurationSaving = {Enabled = false}
})

-- ESP Tab
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)
ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(Value)
        ESP.Enabled = Value
    end,
})

-- Combat Tab
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)
CombatTab:CreateToggle({
    Name = "Aimlock (Auto-Aim Nearest Player)",
    CurrentValue = false,
    Flag = "Aimlock_Toggle",
    Callback = function(Value)
        Combat.Aimlock = Value
    end,
})
CombatTab:CreateToggle({
    Name = "Auto Skill PVP (Skills + Attack)",
    CurrentValue = false,
    Flag = "AutoPvpLevel",
    Callback = function(Value)
        AutoPvp.Enabled = Value
    end,
})
CombatTab:CreateToggle({
    Name = "Auto Farm Level (Skills + Attack)",
    CurrentValue = false,
    Flag = "AutoFarmLevel",
    Callback = function(Value)
        AutoFarm.Enabled = Value
    end,
})
CombatTab:CreateParagraph({
    Title = "Auto Attack",
    Content = "Press [H] to auto attack a player."
})



-- Movement Tab

local MovementTab = Window:CreateTab("🏃 Movement", 4483362458)
MovementTab:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Flag = "Speed_Toggle",
    Callback = function(Value)
        Movement.SpeedEnabled = Value
    end,
})
MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed_Slider",
    Callback = function(Value)
        Movement.WalkSpeed = Value
    end,
})

local MiscTab = Window:CreateTab("🔧 Misc", 4483362458)
MiscTab:CreateParagraph({
    Title = "Teleport Controls",
    Content = "Press [J] to teleport to the lowest health player."
})
MiscTab:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        flying = Value
        if flying then
            task.spawn(Fly)
        end
    end,
})
MiscTab:CreateToggle({
    Name = "Enable Teleport Magnet",
    CurrentValue = false,
    Flag = "TeleportMagnet",
    Callback = function(state)
        magnetActive = state
        if state then
            currentTarget = getLowestHealthPlayer()
        else
            currentTarget = nil
        end
    end
})

MiscTab:CreateSlider({
    Name = "Magnet Distance",
    Range = {1, 15},
    Increment = 0.5,
    Suffix = "studs",
    CurrentValue = 5,
    Flag = "MagnetDistance",
    Callback = function(value)
        magnetDistance = value
    end
})
MiscTab:CreateToggle({
    Name = "Invisible Mode (Client-Side)",
    CurrentValue = false,
    Flag = "Invisible_Toggle",
    Callback = function(Value)
        Invisible.Enabled = Value
        setInvisibility(Value)
    end,
})
-- ⚡ Hitbox Expander Toggle
CombatTab:CreateToggle({
    Name = "Hitbox Expander (Really Red HRP)",
    CurrentValue = false,
    Flag = "Hitbox_Expand",
    Callback = function(Value)
        hitboxEnabled = Value
        updateAllPlayers()
    end,
})
CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 20,
    Flag = "Hitbox_Size",
    Callback = function(Value)
        hitboxSize = Value
        if hitboxEnabled then
            updateAllPlayers()
        end
    end,
})



------------------------------------------------------------
-- 🧹 Destroy UI Button
------------------------------------------------------------

MiscTab:CreateButton({
    Name = "🗑️ Destroy UI & Stop Script",
    Callback = function()
        -- Destroy Rayfield
        if Rayfield and Rayfield.Destroy then
            Rayfield:Destroy()
        end
        
        -- Clean up CoreGui ESP objects
        for _, obj in pairs(game.CoreGui:GetChildren()) do
            if obj:IsA("BillboardGui") or obj:IsA("Highlight") then
                obj:Destroy()
            end
        end

        -- Reset toggles
        ESP.Enabled = false
        Combat.Aimlock = false
        Combat.AutoAttack = false
        AutoFarm.Enabled = false
        AutoPvp.Enabled = false
        Movement.SpeedEnabled = false
        Invisible.Enabled = false
        magnetActive = false

        -- Notify user
        game.StarterGui:SetCore("SendNotification", {
            Title = "⚡ Lynx Fruit Battlegrounds",
            Text = "All UI and scripts have been destroyed.",
            Duration = 4
        })
    end,
})




