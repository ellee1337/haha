--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local MacLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/vinxiii1/maclib/refs/heads/main/maclib.lua"))()

local Window = MacLib:Window({
	Title = "BoogerLand",
	Subtitle = "Lynx",
	Size = UDim2.fromOffset(868, 650),
	DragStyle = 2,
	DisabledWindowControls = {},
	ShowUserInfo = true,
	Keybind = Enum.KeyCode.RightControl,
	AcrylicBlur = true,
})

local globalSettings = {
	UIBlurToggle = Window:GlobalSetting({
		Name = "UI Blur",
		Default = Window:GetAcrylicBlurState(),
		Callback = function(bool)
			Window:SetAcrylicBlurState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Enabled" or "Disabled") .. " UI Blur",
				Lifetime = 5
			})
		end,
	}),
	NotificationToggler = Window:GlobalSetting({
		Name = "Notifications",
		Default = Window:GetNotificationsState(),
		Callback = function(bool)
			Window:SetNotificationsState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Enabled" or "Disabled") .. " Notifications",
				Lifetime = 5
			})
		end,
	}),
	ShowUserInfo = Window:GlobalSetting({
		Name = "Show User Info",
		Default = Window:GetUserInfoState(),
		Callback = function(bool)
			Window:SetUserInfoState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Showing" or "Redacted") .. " User Info",
				Lifetime = 5
			})
		end,
	})
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local HRP = character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local flying = false
local baseSpeed = 50
local flySpeed = baseSpeed
local inputFlags = { forward = false, back = false, left = false, right = false, up = false, down = false }
local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)

local floatTime = 0
local floatIntensity = 0.5
local floatSpeed = 2

local Noclipping = nil
local Clip = true

local infJumpConnection
local infJumpDebounce = false

local espEnabled = false
local espFolder
local espObjects = {}
local espConnection

local antiAFKConnection

local function startFlying()
    flying = true
    floatTime = 0  
    flySpeed = baseSpeed
    bodyVelocity.Parent = HRP
    bodyGyro.Parent = HRP
    humanoid.PlatformStand = true
    Window:Notify({
        Title = "BoogerLand",
        Description = "Flying Enabled",
        Lifetime = 3
    })
end

local function stopFlying()
    flying = false
    bodyVelocity.Parent = nil
    bodyGyro.Parent = nil
    humanoid.PlatformStand = false
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    Window:Notify({
        Title = "BoogerLand",
        Description = "Flying Disabled",
        Lifetime = 3
    })
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = input.KeyCode

    if key == Enum.KeyCode.W then
        inputFlags.forward = true
    elseif key == Enum.KeyCode.S then
        inputFlags.back = true
    elseif key == Enum.KeyCode.A then
        inputFlags.left = true
    elseif key == Enum.KeyCode.D then
        inputFlags.right = true
    elseif key == Enum.KeyCode.E then
        inputFlags.up = true
    elseif key == Enum.KeyCode.Q then
        inputFlags.down = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local key = input.KeyCode
    if key == Enum.KeyCode.W then
        inputFlags.forward = false
    elseif key == Enum.KeyCode.S then
        inputFlags.back = false
    elseif key == Enum.KeyCode.A then
        inputFlags.left = false
    elseif key == Enum.KeyCode.D then
        inputFlags.right = false
    elseif key == Enum.KeyCode.E then
        inputFlags.up = false
    elseif key == Enum.KeyCode.Q then
        inputFlags.down = false
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not flying then return end

    floatTime = floatTime + dt

    local dir = Vector3.new(0,0,0)
    local camCF = Camera.CFrame
    local isMoving = false

	if inputFlags.forward then 
		dir = dir + camCF.LookVector 
		isMoving = true
	end
	if inputFlags.back then 
		dir = dir - camCF.LookVector 
		isMoving = true
	end
	if inputFlags.left then 
		dir = dir - camCF.RightVector 
		isMoving = true
	end
	if inputFlags.right then 
		dir = dir + camCF.RightVector 
		isMoving = true
	end
	if inputFlags.up then 
		dir = dir + Vector3.new(0,1,0) 
		isMoving = true
	end
	if inputFlags.down then 
		dir = dir - Vector3.new(0,1,0) 
		isMoving = true
	end

    if dir.Magnitude > 0 then
        dir = dir.Unit
    end

    local finalVelocity = dir * flySpeed
    if not isMoving then
        local floatOffset = math.sin(floatTime * floatSpeed) * floatIntensity
        finalVelocity = finalVelocity + Vector3.new(0, floatOffset, 0)
    end

    bodyVelocity.Velocity = finalVelocity
    bodyGyro.CFrame = camCF
end)

player.CharacterAdded:Connect(function(newCharacter)
    if flying then
        stopFlying()
    end

    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    HRP = character:WaitForChild("HumanoidRootPart")

    if bodyVelocity then
        bodyVelocity:Destroy()
    end
    if bodyGyro then
        bodyGyro:Destroy()
    end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
end)

local noclipCamEnabled = false

local walkSpeedConnection
local desiredWalkSpeed = 16

local cameraUnlockEnabled = false
local originalCameraMode = player.CameraMode
local originalCameraType = Camera.CameraType
local originalMaxZoom = player.CameraMaxZoomDistance
local originalMinZoom = player.CameraMinZoomDistance
local originalCursorVisible = UserInputService.MouseIconEnabled
local cameraUnlockConnection

local function applyCameraUnlockSettings()
    player.CameraMode = Enum.CameraMode.Classic
    Camera.CameraType = Enum.CameraType.Custom
    player.CameraMaxZoomDistance = 320
    player.CameraMinZoomDistance = 0.5
    UserInputService.MouseIconEnabled = true
end

local function restoreCameraSettings()
    player.CameraMode = originalCameraMode
    player.CameraMaxZoomDistance = originalMaxZoom
    player.CameraMinZoomDistance = originalMinZoom
    UserInputService.MouseIconEnabled = originalCursorVisible
    Camera.CameraType = Enum.CameraType.Custom
end

local espColor = Color3.fromRGB(0, 255, 0)
local espTransparency = 0.7

local tagTextESPEnabled = false
local tagTextESPFolder
local tagTextESPColor = Color3.fromRGB(255, 0, 0)
local tagTextESPConnection

local tagHighlightESPEnabled = false
local tagHighlightESPColor = Color3.fromRGB(255, 255, 0)
local tagHighlightESPTransparency = 0.4
local tagHighlightESPConnection

local function createTagTextESP(headPart)
    if not headPart or not headPart:IsA("BasePart") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TagTaggerESP"
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.Adornee = headPart
    billboard.AlwaysOnTop = true
    billboard.ExtentsOffset = Vector3.new(0, 3.5, 0)
    billboard.Parent = tagTextESPFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "TAGGER"
    label.TextColor3 = tagTextESPColor
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true
    label.Parent = billboard
end

local function setupTagTextESP()
    if not tagTextESPEnabled then return end

    local tag = workspace:FindFirstChild("Tag")
    if not tag or not tag:IsA("Model") then return end

    local horseHead = tag:FindFirstChild("HorseHead")
    if not horseHead or not horseHead:IsA("Model") then return end

    local tool = horseHead:FindFirstChild("Machete")
    if not tool or not tool:IsA("Tool") then return end

    local head = horseHead:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local existingESP = nil
        for _, child in pairs(tagTextESPFolder:GetChildren()) do
            if child.Adornee == head then
                existingESP = child
                break
            end
        end

        if not existingESP then
            createTagTextESP(head)
        else
            local label = existingESP:FindFirstChild("TextLabel")
            if label then
                label.TextColor3 = tagTextESPColor
            end
        end
    end
end

local function createTagHighlight(part)
    if part:FindFirstChild("TagHorseESP_Highlight") then 
        local highlight = part:FindFirstChild("TagHorseESP_Highlight")
        highlight.FillColor = tagHighlightESPColor
        highlight.OutlineColor = tagHighlightESPColor
        highlight.FillTransparency = tagHighlightESPTransparency
        return 
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "TagHorseESP_Highlight"
    highlight.Adornee = part
    highlight.FillColor = tagHighlightESPColor
    highlight.FillTransparency = tagHighlightESPTransparency
    highlight.OutlineColor = tagHighlightESPColor
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = part
end

local function applyTagESPToHorseHead(model)
    if not tagHighlightESPEnabled then return end
    if not model:IsA("Model") or model.Name ~= "HorseHead" then return end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            createTagHighlight(descendant)
        end
    end
end

local function setupTagHorseHeadMonitoring()
    if not tagHighlightESPEnabled then return end

    local tag = workspace:FindFirstChild("Tag")
    if not tag then return end

    for _, child in ipairs(tag:GetChildren()) do
        if child:IsA("Model") and child.Name == "HorseHead" then
            applyTagESPToHorseHead(child)
        end
    end
end

local function removeAllTagHighlights()
    local tag = workspace:FindFirstChild("Tag")
    if not tag then return end

    for _, descendant in ipairs(tag:GetDescendants()) do
        local highlight = descendant:FindFirstChild("TagHorseESP_Highlight")
        if highlight then
            highlight:Destroy()
        end
    end
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function stringSimilarity(a, b)
    a, b = a:lower(), b:lower()
    local score = 0
    for i = 1, math.min(#a, #b) do
        if a:sub(i, i) == b:sub(i, i) then
            score = score + 1
        else
            break
        end
    end
    return score
end

local function findClosestPlayer(partial)
    local bestMatch = nil
    local bestScore = -1

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local displayScore = stringSimilarity(partial, player.DisplayName)
            local usernameScore = stringSimilarity(partial, player.Name)

            local score = math.max(displayScore, usernameScore)
            if score > bestScore then
                bestScore = score
                bestMatch = player
            end
        end
    end

    return bestMatch
end

local function triggerNearestPrompt(rootPart)
    local range = 15
    local closestPrompt
    local shortestDistance = math.huge

    for _, prompt in pairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent then
            local part = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (part.Position - rootPart.Position).Magnitude
                if dist < range and dist < shortestDistance then
                    shortestDistance = dist
                    closestPrompt = prompt
                end
            end
        end
    end

    if closestPrompt then
        fireproximityprompt(closestPrompt)
    end
end

local function teleportToAndBack(partialName)
    local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local myHRP = myChar:WaitForChild("HumanoidRootPart")
    local safeCFrame = CFrame.new(-1796.04, 247.22, 982.80)

    local targetPlayer = findClosestPlayer(partialName)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetHRP = targetPlayer.Character.HumanoidRootPart

        myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 0.5, 0)

        task.wait(0.25) 

        triggerNearestPrompt(myHRP)

        task.wait(0.25)

        myHRP.CFrame = safeCFrame
    end
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local function triggerPromptIn(model)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Enabled then
			fireproximityprompt(obj)
			break
		end
	end
end

local function teleportToAllPointGivers()
	local visited = {}

	for _, model in ipairs(Workspace:GetDescendants()) do
		if model:IsA("Model") and model.Name == "PointGiver" and not visited[model] then
			local targetPart = model.PrimaryPart
			if not targetPart then
				for _, part in ipairs(model:GetDescendants()) do
					if part:IsA("BasePart") then
						targetPart = part
						break
					end
				end
			end

			if targetPart then
				HumanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 5, 0)
				task.wait(0.2)
				triggerPromptIn(model)
				task.wait(0.5)
				visited[model] = true
			end
		end
	end
end

local OsmosisTP = false

local function getLocalTeam()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChild("BlueTeamHigh") and "BlueTeamHigh"
		or char:FindFirstChild("RedTeamHigh") and "RedTeamHigh"
end

local function getEnemyTeam()
	local myTeam = getLocalTeam()
	if myTeam == "BlueTeamHigh" then return "RedTeamHigh"
	elseif myTeam == "RedTeamHigh" then return "BlueTeamHigh"
	end
	return nil
end

local function getEnemyPlayers(enemyTeamHighlight)
	local enemies = {}
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") and model ~= LocalPlayer.Character then
			if model:FindFirstChild(enemyTeamHighlight) then
				table.insert(enemies, model)
			end
		end
	end
	return enemies
end

local function triggerPromptIn(model)
	local char = LocalPlayer.Character
	local HRP = char and char:FindFirstChild("HumanoidRootPart")
	if not HRP then return false end

	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Enabled then
			fireproximityprompt(obj)
			return true
		end
	end
	return false
end

task.spawn(function()
	while true do
		if OsmosisTP then
			local char = LocalPlayer.Character
			local HRP = char and char:FindFirstChild("HumanoidRootPart")
			local enemyTeam = getEnemyTeam()

			if HRP and enemyTeam then
				local enemies = getEnemyPlayers(enemyTeam)

				if #enemies == 0 then
					Window:Notify({
						Title = "BoogerLand",
						Description = "No enemies found",
						Lifetime = 2
					})
					task.wait(2)
				else
					for _, enemy in ipairs(enemies) do
						if not OsmosisTP then break end 

						local targetPart = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart")
						if targetPart then
							HRP.CFrame = targetPart.CFrame + Vector3.new(0, 0.5, 0)
							task.wait(0.3) 

							if triggerPromptIn(enemy) then
								task.wait(0.5) 
							else
								task.wait(0.1) 
							end
						end
					end
				end
			else
				if not enemyTeam then
					Window:Notify({
						Title = "BoogerLand",
						Description = "Could not determine your team",
						Lifetime = 3
					})
				end
				task.wait(1)
			end
		end
		task.wait(0.1)
	end
end)

local osmosisESPEnabled = false
local osmosisESPEnemyOnly = false 
local osmosisESPColorBlue = Color3.fromRGB(0, 0, 255)
local osmosisESPColorRed = Color3.fromRGB(255, 0, 0)
local osmosisESPAlphaBlue = 0.5  
local osmosisESPAlphaRed = 0.5

local osmosisProcessedModels = {}

local function setupOsmosisESP(playerModel)
    if not playerModel:IsA("Model") then return end
    local highlight = playerModel:FindFirstChildOfClass("Highlight")
    if not highlight then return end

    local modelId = playerModel:GetDebugId()
    local myTeam = getLocalTeam()

    if osmosisESPEnemyOnly and highlight.Name == myTeam then 
        return 
    end

    if osmosisProcessedModels[modelId]
        and osmosisProcessedModels[modelId].HighlightName == highlight.Name then
        return
    end

    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    if highlight.Name == "BlueTeamHigh" then
        highlight.FillColor = osmosisESPColorBlue
        highlight.OutlineColor = osmosisESPColorBlue:Lerp(Color3.new(0,0,0), 0.2)
        highlight.FillTransparency = osmosisESPAlphaBlue 
        highlight.OutlineTransparency = osmosisESPAlphaBlue * 0.8  
    elseif highlight.Name == "RedTeamHigh" then
        highlight.FillColor = osmosisESPColorRed
        highlight.OutlineColor = osmosisESPColorRed:Lerp(Color3.new(0,0,0), 0.2)
        highlight.FillTransparency = osmosisESPAlphaRed  
        highlight.OutlineTransparency = osmosisESPAlphaRed * 0.8  
    else
        return
    end

    osmosisProcessedModels[modelId] = {
        Model = playerModel,
        HighlightName = highlight.Name
    }
end

local function clearOsmosisESP()
    for _, data in pairs(osmosisProcessedModels) do
        local model = data.Model
        if model and model:IsDescendantOf(Workspace) then
            local highlight = model:FindFirstChildOfClass("Highlight")
            if highlight then
                highlight.DepthMode = Enum.HighlightDepthMode.Occluded
                highlight.FillTransparency = 1
                highlight.OutlineTransparency = 1
            end
        end
    end
    osmosisProcessedModels = {}
end

local function osmosisESPLoop()
    while osmosisESPEnabled do
        for _, child in ipairs(Workspace:GetChildren()) do
            if child ~= LocalPlayer.Character then
                setupOsmosisESP(child)
            end
        end
        task.wait(2)
    end

    clearOsmosisESP()
end

local CheckmateTP = false

local function getLocalTeam()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChild("BlueTeamHigh") and "BlueTeamHigh"
		or char:FindFirstChild("RedTeamHigh") and "RedTeamHigh"
end

local function getEnemyTeam()
	local myTeam = getLocalTeam()
	if myTeam == "BlueTeamHigh" then return "RedTeamHigh"
	elseif myTeam == "RedTeamHigh" then return "BlueTeamHigh"
	end
	return nil
end

local function getEnemyPlayers(enemyTeamHighlight)
	local enemies = {}
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") and model ~= LocalPlayer.Character then
			if model:FindFirstChild(enemyTeamHighlight) then
				table.insert(enemies, model)
			end
		end
	end
	return enemies
end

local function triggerPromptIn(model)
	local char = LocalPlayer.Character
	local HRP = char and char:FindFirstChild("HumanoidRootPart")
	if not HRP then return false end

	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Enabled then
			fireproximityprompt(obj)
			return true
		end
	end
	return false
end

task.spawn(function()
	while true do
		if CheckmateTP then
			local char = LocalPlayer.Character
			local HRP = char and char:FindFirstChild("HumanoidRootPart")
			local enemyTeam = getEnemyTeam()

			if HRP and enemyTeam then
				local enemies = getEnemyPlayers(enemyTeam)

				if #enemies == 0 then
					Window:Notify({
						Title = "BoogerLand",
						Description = "No enemies found",
						Lifetime = 2
					})
					task.wait(2)
				else
					for _, enemy in ipairs(enemies) do
						if not CheckmateTP then break end 

						local targetPart = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart")
						if targetPart then
							HRP.CFrame = targetPart.CFrame + Vector3.new(0, 0.5, 0)
							task.wait(0.3) 

							if triggerPromptIn(enemy) then
								task.wait(0.5) 
							else
								task.wait(0.1) 
							end
						end
					end
				end
			else
				if not enemyTeam then
					Window:Notify({
						Title = "BoogerLand",
						Description = "Could not determine your team",
						Lifetime = 3
					})
				end
				task.wait(1)
			end
		end
		task.wait(0.1)
	end
end)

local checkmateESPEnabled = false
local checkmateESPEnemyOnly = false 
local checkmateESPColorBlue = Color3.fromRGB(0, 0, 255)
local checkmateESPColorRed = Color3.fromRGB(255, 0, 0)
local checkmateESPAlphaBlue = 0.5  
local checkmateESPAlphaRed = 0.5

local checkmateProcessedModels = {}

local function setupCheckmateESP(playerModel)
    if not playerModel:IsA("Model") then return end
    local highlight = playerModel:FindFirstChild("BlueTeamHigh") or playerModel:FindFirstChild("RedTeamHigh")
    if not highlight then return end

    local modelId = playerModel:GetDebugId()
    local myTeam = getLocalTeam()

    if checkmateESPEnemyOnly and highlight.Name == myTeam then 
        return 
    end

    if checkmateProcessedModels[modelId]
        and checkmateProcessedModels[modelId].HighlightName == highlight.Name then
        return
    end

    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    if highlight.Name == "BlueTeamHigh" then
        highlight.FillColor = checkmateESPColorBlue
        highlight.OutlineColor = checkmateESPColorBlue:Lerp(Color3.new(0,0,0), 0.2)
        highlight.FillTransparency = checkmateESPAlphaBlue 
        highlight.OutlineTransparency = checkmateESPAlphaBlue * 0.8  
    elseif highlight.Name == "RedTeamHigh" then
        highlight.FillColor = checkmateESPColorRed
        highlight.OutlineColor = checkmateESPColorRed:Lerp(Color3.new(0,0,0), 0.2)
        highlight.FillTransparency = checkmateESPAlphaRed  
        highlight.OutlineTransparency = checkmateESPAlphaRed * 0.8  
    end

    checkmateProcessedModels[modelId] = {
        Model = playerModel,
        HighlightName = highlight.Name
    }
end

local function clearCheckmateESP()
    for _, data in pairs(checkmateProcessedModels) do
        local model = data.Model
        if model and model:IsDescendantOf(Workspace) then
            local highlight = model:FindFirstChildOfClass("Highlight")
            if highlight then
                highlight.DepthMode = Enum.HighlightDepthMode.Occluded
                highlight.FillTransparency = 1
                highlight.OutlineTransparency = 1
            end
        end
    end
    checkmateProcessedModels = {}
end

local function checkmateESPLoop()
    while checkmateESPEnabled do
        for _, child in ipairs(Workspace:GetChildren()) do
            if child ~= LocalPlayer.Character then
                setupCheckmateESP(child)
            end
        end
        task.wait(0.5) 
    end

    clearCheckmateESP()
end

local cameraUnlockEnabled = false
local originalCameraMode = player.CameraMode
local originalCameraType = Camera.CameraType
local originalMaxZoom = player.CameraMaxZoomDistance
local originalMinZoom = player.CameraMinZoomDistance
local originalCursorVisible = UserInputService.MouseIconEnabled
local cameraUnlockConnection

local function applyCameraUnlockSettings()
    player.CameraMode = Enum.CameraMode.Classic
    Camera.CameraType = Enum.CameraType.Custom
    player.CameraMaxZoomDistance = 320
    player.CameraMinZoomDistance = 0.5
    UserInputService.MouseIconEnabled = true
end

local function restoreCameraSettings()
    player.CameraMode = originalCameraMode
    player.CameraMaxZoomDistance = originalMaxZoom
    player.CameraMinZoomDistance = originalMinZoom
    UserInputService.MouseIconEnabled = originalCursorVisible
    Camera.CameraType = Enum.CameraType.Custom
end

local toolESPEnabled = false
local toolESPColor = Color3.fromRGB(255, 255, 0) 
local toolFolder = nil
local toolESPConnections = {}
local toolESPObjects = {}

local function addTextESP(tool)
    if not toolESPEnabled then return end

    local function createLabel()
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
        if not handle then return end
        if not handle:FindFirstChild("ToolLabel") then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ToolLabel"
            billboard.Adornee = handle
            billboard.Size = UDim2.new(0, 100, 0, 40)
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = handle

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = "Tool"
            textLabel.TextColor3 = toolESPColor
            textLabel.TextStrokeTransparency = 0
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.Parent = billboard

            if not toolESPObjects[tool] then
                toolESPObjects[tool] = {}
            end
            table.insert(toolESPObjects[tool], billboard)
        end
    end

    local function updateESP()
        if not toolESPEnabled then return end

        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
        if not handle then return end

        local label = handle:FindFirstChild("ToolLabel")
        local parent = tool.Parent
        local isEquipped = parent and Players:GetPlayerFromCharacter(parent)

        if label then
            label.Enabled = not isEquipped
            local textLabel = label:FindFirstChild("TextLabel")
            if textLabel then
                textLabel.TextColor3 = toolESPColor
            end
        elseif not isEquipped then
            createLabel()
        end
    end

    createLabel()
    updateESP()

    local connection = tool:GetPropertyChangedSignal("Parent"):Connect(updateESP)
    toolESPConnections[tool] = connection
end

local function removeAllToolESP()
    for tool, objects in pairs(toolESPObjects) do
        for _, obj in ipairs(objects) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end
    end
    toolESPObjects = {}

    for tool, connection in pairs(toolESPConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    toolESPConnections = {}
end

local function setupToolESP()
    if not toolESPEnabled then return end

    toolFolder = Workspace:FindFirstChild("BRToolsSpawned")
    if not toolFolder then
        Window:Notify({
            Title = "BoogerLand",
            Description = "BRToolsSpawned folder not found",
            Lifetime = 3
        })
        return
    end

    for _, tool in ipairs(toolFolder:GetChildren()) do
        if tool:IsA("Tool") then
            addTextESP(tool)
        end
    end

    local childAddedConnection = toolFolder.ChildAdded:Connect(function(child)
        if toolESPEnabled and child:IsA("Tool") then
            task.wait(0.1)
            addTextESP(child)
        end
    end)

    toolESPConnections["ChildAdded"] = childAddedConnection
end

local getAllToolsEnabled = false
local getAllToolsConnection = nil

local function teleportToTool(tool)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HRP = Character:WaitForChild("HumanoidRootPart")

    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
    if handle then
        HRP.CFrame = handle.CFrame + Vector3.new(0, 1, 0) 
        Window:Notify({
            Title = "BoogerLand",
            Description = "Teleported to " .. tool.Name,
            Lifetime = 2
        })
    end
end

local function setupGetAllTools()
    local toolFolder = Workspace:FindFirstChild("BRToolsSpawned")
    if not toolFolder then
        Window:Notify({
            Title = "BoogerLand",
            Description = "BRToolsSpawned folder not found",
            Lifetime = 3
        })
        return
    end

    getAllToolsConnection = toolFolder.ChildAdded:Connect(function(child)
        if getAllToolsEnabled and child:IsA("Tool") then
            task.wait(0.1) 
            teleportToTool(child)
        end
    end)
end

local function getFirstTool()
    local toolFolder = Workspace:FindFirstChild("BRToolsSpawned")
    if not toolFolder then
        Window:Notify({
            Title = "BoogerLand",
            Description = "BRToolsSpawned folder not found",
            Lifetime = 3
        })
        return
    end

    for _, child in pairs(toolFolder:GetChildren()) do
        if child:IsA("Tool") then
            teleportToTool(child)
            return
        end
    end

    local connection
    connection = toolFolder.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1) 
            teleportToTool(child)
            connection:Disconnect() 
        end
    end)

    Window:Notify({
        Title = "BoogerLand",
        Description = "Waiting for first tool to spawn...",
        Lifetime = 3
    })
end

local hitboxEnabled = false
local hitboxSize = 20
local toggleKey = Enum.KeyCode.H
local keyConnection

local function setupCollisionGroup()
	if not pcall(function() PhysicsService:CreateCollisionGroup("ExpandedHitboxes") end) then end
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable("ExpandedHitboxes", "Default", false)
		PhysicsService:CollisionGroupSetCollidable("ExpandedHitboxes", "ExpandedHitboxes", false)
	end)
end
setupCollisionGroup()

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

local function updateAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			applyHitbox(player)
		end
	end
end

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

local knifeESPConnections = {}
local knifeESPToggle = false

local cluesESPConnections = {}
local cluesESPToggle = false

local knifeESPColor = Color3.fromRGB(255, 0, 0)
local cluesESPColor = Color3.fromRGB(255, 255, 0)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local enabled = false
local enemyOnly = false
local hpenabled = false

local function getHealthColor(percent)
	return percent > 0.75 and Color3.fromRGB(0,255,0)
		or percent > 0.4 and Color3.fromRGB(255,255,0)
		or Color3.fromRGB(255,0,0)
end

local existingHolder = CoreGui:FindFirstChild("ESPHolder")
if existingHolder then
    existingHolder:Destroy()
end

local holder = Instance.new("Folder", CoreGui)
holder.Name = "ESPHolder"

local healthBarConnection

local function createOrUpdateHealthBar(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if not (char and hum and root and hum.Health > 0 and char.Parent) then 
		local con = holder:FindFirstChild(player.Name)
		if con then con:Destroy() end
		return 
	end

	local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
	if not onScreen or screenPos.Z <= 0 then return end

	local con = holder:FindFirstChild(player.Name)
	if not con then
		con = Instance.new("Folder")
		con.Name = player.Name
		con.Parent = holder
	end

	local hpGui = con:FindFirstChild("HPBar")
	if hpenabled then
		if not hpGui or (hpGui.Adornee ~= root) then
			if hpGui then hpGui:Destroy() end

			hpGui = Instance.new("BillboardGui")
			hpGui.Name = "HPBar"
			hpGui.Size = UDim2.new(0, 60, 0, 6)
			hpGui.StudsOffset = Vector3.new(0, 4, 0)
			hpGui.AlwaysOnTop = true
			hpGui.Adornee = root
			hpGui.Parent = con

			local bg = Instance.new("Frame", hpGui)
			bg.Name = "BG"
			bg.Size = UDim2.new(1, 0, 1, 0)
			bg.BackgroundColor3 = Color3.new(0, 0, 0)
			bg.BackgroundTransparency = 0.3
			bg.BorderSizePixel = 0
			Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

			local bar = Instance.new("Frame", bg)
			bar.Name = "Bar"
			bar.Size = UDim2.new(1, 0, 1, 0)
			bar.BorderSizePixel = 0
			Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
		end

		local bar = hpGui:FindFirstChild("BG") and hpGui.BG:FindFirstChild("Bar")
		if bar then
			local percent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			bar.Size = UDim2.new(percent, 0, 1, 0)
			bar.BackgroundColor3 = getHealthColor(percent)
		end
	elseif hpGui then
		hpGui:Destroy()
	end
end

local function cleanupHealthBarESP()
    if healthBarConnection then
        healthBarConnection:Disconnect()
        healthBarConnection = nil
    end

    if holder then
        for _, con in ipairs(holder:GetChildren()) do 
            con:Destroy() 
        end
    end

    enabled = false
    hpenabled = false
end

local function startHealthBarESP()
    if healthBarConnection then
        healthBarConnection:Disconnect()
    end

    healthBarConnection = RunService.Heartbeat:Connect(function()
        if not enabled or not hpenabled then
            for _, con in ipairs(holder:GetChildren()) do con:Destroy() end
            return
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if not enemyOnly or player.Team ~= LocalPlayer.Team then
                    createOrUpdateHealthBar(player)
                else
                    local con = holder:FindFirstChild(player.Name)
                    if con then con:Destroy() end
                end
            end
        end
    end)
end

local nameESPEnabled = false
local nameESPColor = Color3.fromRGB(255, 255, 255)
local nameESPFolder = nil
local nameESPConnections = {}
local nameESPObjects = {}

local function createNameESP(player)
    if not nameESPEnabled then return end
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end
    if nameESPObjects[player] then
        nameESPObjects[player]:Destroy()
        nameESPObjects[player] = nil
    end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameESP"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Parent = nameESPFolder
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = nameESPColor
    nameLabel.TextStrokeTransparency = 0.7
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.SourceSansSemibold
    nameLabel.TextScaled = true
    nameLabel.Text = player.DisplayName
    nameLabel.Parent = billboard
    nameESPObjects[player] = billboard
    local conn = RunService.RenderStepped:Connect(function()
        if not nameESPEnabled or not player or not player.Character or not player.Character:FindFirstChild("Head") then
            if nameESPConnections[player] then
                nameESPConnections[player]:Disconnect()
                nameESPConnections[player] = nil
            end
            if nameESPObjects[player] then
                nameESPObjects[player]:Destroy()
                nameESPObjects[player] = nil
            end
            return
        end
        local head = player.Character:FindFirstChild("Head")
        if head then
            local distance = (Camera.CFrame.Position - head.Position).Magnitude
            local scale = math.clamp(100 / distance, 0.6, 1.5)
            billboard.Size = UDim2.new(0, 100 * scale, 0, 25 * scale)
            nameLabel.TextColor3 = nameESPColor
        end
    end)
    nameESPConnections[player] = conn
end

local function removeAllNameESP()
    for player, connection in pairs(nameESPConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    nameESPConnections = {}
    for player, billboard in pairs(nameESPObjects) do
        if billboard then
            billboard:Destroy()
        end
    end
    nameESPObjects = {}
    if nameESPFolder then
        nameESPFolder:ClearAllChildren()
    end
end

local function setupNameESP()
    if not nameESPEnabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            createNameESP(player)
        end
    end
end

local function updateNameESPColors()
    if not nameESPEnabled then return end
    for player, billboard in pairs(nameESPObjects) do
        if billboard and billboard.Parent then
            local nameLabel = billboard:FindFirstChild("TextLabel")
            if nameLabel then
                nameLabel.TextColor3 = nameESPColor
            end
        end
    end
end

local nameESPPlayerConnections = {}

local function connectPlayerEvents()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if nameESPPlayerConnections[player] then
                nameESPPlayerConnections[player]:Disconnect()
            end
            nameESPPlayerConnections[player] = player.CharacterAdded:Connect(function()
                task.wait(1)
                if nameESPEnabled then
                    createNameESP(player)
                end
            end)
            if player.Character then
                createNameESP(player)
            end
        end
    end
    if not nameESPPlayerConnections["PlayerAdded"] then
        nameESPPlayerConnections["PlayerAdded"] = Players.PlayerAdded:Connect(function(player)
            if player == LocalPlayer then return end
            nameESPPlayerConnections[player] = player.CharacterAdded:Connect(function()
                task.wait(1)
                if nameESPEnabled then
                    createNameESP(player)
                end
            end)
        end)
    end
    if not nameESPPlayerConnections["PlayerRemoving"] then
        nameESPPlayerConnections["PlayerRemoving"] = Players.PlayerRemoving:Connect(function(player)
            if nameESPConnections[player] then
                nameESPConnections[player]:Disconnect()
                nameESPConnections[player] = nil
            end
            if nameESPObjects[player] then
                nameESPObjects[player]:Destroy()
                nameESPObjects[player] = nil
            end
            if nameESPPlayerConnections[player] then
                nameESPPlayerConnections[player]:Disconnect()
                nameESPPlayerConnections[player] = nil
            end
        end)
    end
end

local function disconnectPlayerEvents()
    for player, connection in pairs(nameESPPlayerConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    nameESPPlayerConnections = {}
end

local followLoop = nil
local currentFollowTarget = nil

local function stringSimilarity(a, b)
    a, b = a:lower(), b:lower()
    local score = 0
    for i = 1, math.min(#a, #b) do
        if a:sub(i, i) == b:sub(i, i) then
            score = score + 1
        else
            break
        end
    end
    return score
end

local function findClosestPlayer(partial)
    local bestMatch = nil
    local bestScore = -1

    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            local displayScore = stringSimilarity(partial, targetPlayer.DisplayName)
            local usernameScore = stringSimilarity(partial, targetPlayer.Name)

            local score = math.max(displayScore, usernameScore)
            if score > bestScore then
                bestScore = score
                bestMatch = targetPlayer
            end
        end
    end

    return bestMatch
end

local function startFollowing(targetPlayer)
    if followLoop then
        followLoop:Disconnect()
        followLoop = nil
    end

    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Window:Notify({
            Title = "BoogerLand",
            Description = "Invalid target player",
            Lifetime = 3
        })
        return
    end

    currentFollowTarget = targetPlayer
    local offset = CFrame.new(0, 0, 1.5)

    followLoop = RunService.Stepped:Connect(function()
        pcall(function()
            local otherRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local speakerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

            if otherRoot and speakerRoot then
                speakerRoot.CFrame = otherRoot.CFrame * offset
            end
        end)
    end)

    Window:Notify({
        Title = "BoogerLand",
        Description = "Now following: " .. targetPlayer.DisplayName,
        Lifetime = 3
    })
end

local function stopFollowing()
    if followLoop then
        followLoop:Disconnect()
        followLoop = nil
    end

    currentFollowTarget = nil

    Window:Notify({
        Title = "BoogerLand",
        Description = "Stopped following player",
        Lifetime = 3
    })
end

local staminaSystemEnabled = false
local currentStaminaConnection = nil
local currentStaminaPreset = "Default"

local staminaPresets = {
    ["Default"] = {
        DRAIN_RATE = 18,
        REGEN_RATE = 30,
        WALK_SPEED = 16,
        SPRINT_SPEED = 22,
        MAX_STAMINA = 100,
        FOV_NORMAL = 70,
        FOV_SPRINT = 80
    },
    ["2x Stamina"] = {
        DRAIN_RATE = 9,
        REGEN_RATE = 60,
        WALK_SPEED = 16,
        SPRINT_SPEED = 22,
        MAX_STAMINA = 200,
        FOV_NORMAL = 70,
        FOV_SPRINT = 80
    },
    ["3x Stamina"] = {
        DRAIN_RATE = 6,
        REGEN_RATE = 90,
        WALK_SPEED = 16,
        SPRINT_SPEED = 22,
        MAX_STAMINA = 300,
        FOV_NORMAL = 70,
        FOV_SPRINT = 80
    },
    ["4x Stamina"] = {
        DRAIN_RATE = 4.5,
        REGEN_RATE = 120,
        WALK_SPEED = 16,
        SPRINT_SPEED = 22,
        MAX_STAMINA = 400,
        FOV_NORMAL = 70,
        FOV_SPRINT = 80
    },
    ["5x Stamina"] = {
        DRAIN_RATE = 3.6,
        REGEN_RATE = 150,
        WALK_SPEED = 16,
        SPRINT_SPEED = 22,
        MAX_STAMINA = 500,
        FOV_NORMAL = 70,
        FOV_SPRINT = 80
    },
    ["6x Stamina"] = {
        DRAIN_RATE = 3,
        REGEN_RATE = 180,
        WALK_SPEED = 16,
        SPRINT_SPEED = 22,
        MAX_STAMINA = 600,
        FOV_NORMAL = 70,
        FOV_SPRINT = 80
    },
    ["Infinite"] = {
        DRAIN_RATE = 0,
        REGEN_RATE = 999,
        WALK_SPEED = 16,
        SPRINT_SPEED = 22,
        MAX_STAMINA = 1e9,
        FOV_NORMAL = 70,
        FOV_SPRINT = 80
    }
}

local function stopStaminaSystem()
    if currentStaminaConnection then
        currentStaminaConnection:Disconnect()
        currentStaminaConnection = nil
    end

    requestedSprint = false
    isSprinting = false
    stamina = 0

    local ContextActionService = game:GetService("ContextActionService")
    pcall(function()
        ContextActionService:UnbindAction("Sprint")
    end)

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character
    if Character then
        local Humanoid = Character:FindFirstChild("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = 16 
        end
    end

    local Camera = workspace.CurrentCamera
    if Camera then
        Camera.FieldOfView = 70 
    end

    Window:Notify({
        Title = "BoogerLand",
        Description = "Stamina System Disabled",
        Lifetime = 3
    })
end

local function createStaminaSystem(preset)
    local config = staminaPresets[preset]
    if not config then
        Window:Notify({
            Title = "BoogerLand",
            Description = "Invalid stamina preset!",
            Lifetime = 3
        })
        return
    end

    if currentStaminaConnection then
        currentStaminaConnection:Disconnect()
        currentStaminaConnection = nil
    end

    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local ContextActionService = game:GetService("ContextActionService")
    local RunService = game:GetService("RunService")

    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Camera = workspace.CurrentCamera

    local DRAIN_RATE = config.DRAIN_RATE
    local REGEN_RATE = config.REGEN_RATE
    local WALK_SPEED = config.WALK_SPEED
    local SPRINT_SPEED = config.SPRINT_SPEED
    local MAX_STAMINA = config.MAX_STAMINA
    local FOV_NORMAL = config.FOV_NORMAL
    local FOV_SPRINT = config.FOV_SPRINT

    local stamina = MAX_STAMINA
    local isSprinting = false
    local requestedSprint = false
    local lastUpdate = time()

    local function setFOV(duration, fov)
        local tween = TweenService:Create(Camera, TweenInfo.new(duration, Enum.EasingStyle.Quad), {FieldOfView = fov})
        tween:Play()
        tween.Completed:Once(function()
            tween:Destroy()
        end)
    end

    local function updateStaminaBar()
        pcall(function()
            local staminaGui = PlayerGui:FindFirstChild("StaminaGui")
            if staminaGui and staminaGui:FindFirstChild("Frame") then
                local frame = staminaGui.Frame
                if frame:FindFirstChild("Base") and frame.Base:FindFirstChild("Top") then
                    frame.Base.Top:TweenSize(
                        UDim2.new(math.clamp(stamina / MAX_STAMINA, 0, 1), 0, 1, 0),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Sine,
                        0.05,
                        true
                    )
                end
            end
        end)
    end

    local function handleSprint(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            requestedSprint = true
        elseif inputState == Enum.UserInputState.End then
            requestedSprint = false
        end
    end

    pcall(function()
        ContextActionService:UnbindAction("Sprint")
    end)

    ContextActionService:BindAction("Sprint", handleSprint, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL2)

    pcall(function()
        local mobileButtons = PlayerGui:FindFirstChild("MobileButtons")
        if mobileButtons and mobileButtons:FindFirstChild("MobileButtons") then
            local sprintButton = mobileButtons.MobileButtons:FindFirstChild("SprintButton")
            if sprintButton then
                sprintButton.MouseButton1Down:Connect(function()
                    requestedSprint = true
                end)
                sprintButton.MouseButton1Up:Connect(function()
                    requestedSprint = false
                end)
            end
        end
    end)

    currentStaminaConnection = RunService.RenderStepped:Connect(function()
        local dt = time() - lastUpdate
        lastUpdate = time()

        if requestedSprint and stamina > 0 then
            isSprinting = true
            stamina = math.max(0, stamina - DRAIN_RATE * dt)
            setFOV(0.2, FOV_SPRINT)
            Humanoid.WalkSpeed = SPRINT_SPEED
        else
            isSprinting = false
            stamina = math.min(MAX_STAMINA, stamina + REGEN_RATE * dt)
            setFOV(0.2, FOV_NORMAL)
            Humanoid.WalkSpeed = WALK_SPEED
        end

        if stamina <= 0 then
            requestedSprint = false
            isSprinting = false
        end

        updateStaminaBar()
    end)

    Window:Notify({
        Title = "BoogerLand",
        Description = "Stamina System (" .. preset .. ") Activated",
        Lifetime = 3
    })
end

local voteSkipLoopRunning = false
local voteSkipThread = nil

local voteSkipRulesRunning = false
local voteSkipRulesThread = nil

local autoPlayRunning = false
local autoPlayThread = nil

local zoomBlockEnabled = false
local zoomBlockedConnections = {}

local tabGroups = {
	TabGroup1 = Window:TabGroup(),
	TabGroup2 = Window:TabGroup(),
	TabGroup3 = Window:TabGroup()

}

local tabs = {
	Main = tabGroups.TabGroup1:Tab({ Name = "Main", Image = "rbxassetid://92334029887266" }),
	Gamepass = tabGroups.TabGroup1:Tab({ Name = "Gamepass", Image = "rbxassetid://98319238724439" }),
	Automate = tabGroups.TabGroup1:Tab({ Name = "Automate", Image = "rbxassetid://77650047664916" }),
	DeadOrAlive = tabGroups.TabGroup2:Tab({ Name = "Dead Or Alive", Image = "rbxassetid://137190209937727" }),
	Tag = tabGroups.TabGroup2:Tab({ Name = "Tag", Image = "rbxassetid://121700697298748" }),
	HideAndSeek = tabGroups.TabGroup2:Tab({ Name = "Hide and Seek", Image = "rbxassetid://127934851507549" }),
	Osmosis = tabGroups.TabGroup2:Tab({ Name = "Osmosis", Image = "rbxassetid://94950016289656" }),
	Checkmate = tabGroups.TabGroup2:Tab({ Name = "Checkmate", Image = "rbxassetid://88034556408137" }),
	BoilingDeath = tabGroups.TabGroup2:Tab({ Name = "Boiling Death", Image = "rbxassetid://135112775394924" }),
	Labyrinth = tabGroups.TabGroup2:Tab({ Name = "Labyrinth", Image = "rbxassetid://80330474014164" }),
	Distance = tabGroups.TabGroup2:Tab({ Name = "Distance", Image = "rbxassetid://74203266420181" }),
	BattleRoyale = tabGroups.TabGroup2:Tab({ Name = "Battle Royale", Image = "rbxassetid://79583481926021" }),
	WitchHunt = tabGroups.TabGroup2:Tab({ Name = "Witch Hunt", Image = "rbxassetid://139177873240632" }),
	Target = tabGroups.TabGroup2:Tab({ Name = "Target", Image = "rbxassetid://113259797554218" }),
	SolitaryConfinement = tabGroups.TabGroup2:Tab({ Name = "Solitary Confinement", Image = "rbxassetid://114902720232425" }),
	BeautyContest = tabGroups.TabGroup2:Tab({ Name = "Beauty Contest", Image = "rbxassetid://90595231239267" }),
	Settings = tabGroups.TabGroup3:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" }),
}

local sections = {
	Mainsection1 = tabs.Main:Section({ Side = "Left" }),
	Mainsection2 = tabs.Main:Section({ Side = "Left" }),
	Mainsection3 = tabs.Main:Section({ Side = "Right" }),
	Gamepasssection1 = tabs.Gamepass:Section({ Side = "Left" }),
	Automatesection1 = tabs.Automate:Section({ Side = "Left" }),
	Automatesection2 = tabs.Automate:Section({ Side = "Right" }),
	DeadOrAlivesection1 = tabs.DeadOrAlive:Section({ Side = "Left" }),
	Tagsection1 = tabs.Tag:Section({ Side = "Right" }),
	Tagsection2 = tabs.Tag:Section({ Side = "Left" }),
	HideAndSeeksection1 = tabs.HideAndSeek:Section({ Side = "Left" }),
	HideAndSeeksection2 = tabs.HideAndSeek:Section({ Side = "Right" }),
	Osmosissection1 = tabs.Osmosis:Section({ Side = "Left" }),
	Osmosissection2 = tabs.Osmosis:Section({ Side = "Right" }),
	Checkmatesection1 = tabs.Checkmate:Section({ Side = "Left" }),
	Checkmatesection2 = tabs.Checkmate:Section({ Side = "Right" }),
	BoilingDeathsection1 = tabs.BoilingDeath:Section({ Side = "Left" }),
	BoilingDeathsection2 = tabs.BoilingDeath:Section({ Side = "Right" }),
	Labyrinthsection1 = tabs.Labyrinth:Section({ Side = "Left" }),
	Labyrinthsection2 = tabs.Labyrinth:Section({ Side = "Right" }),
	Distancesection1 = tabs.Distance:Section({ Side = "Left" }),
	Distancesection2 = tabs.Distance:Section({ Side = "Right" }),
	BattleRoyalesection1 = tabs.BattleRoyale:Section({ Side = "Left" }),
	BattleRoyalesection2 = tabs.BattleRoyale:Section({ Side = "Right" }),
	BattleRoyalesection3 = tabs.BattleRoyale:Section({ Side = "Left" }),
	WitchHuntsection1 = tabs.WitchHunt:Section({ Side = "Left" }),
	WitchHuntsection2 = tabs.WitchHunt:Section({ Side = "Right" }),
	Targetsection1 = tabs.Target:Section({ Side = "Left" }),
	Targetsection2 = tabs.Target:Section({ Side = "Right" }),
	SolitaryConfinementsection1 = tabs.SolitaryConfinement:Section({ Side = "Left" }),
	BeautyContestsection1 = tabs.BeautyContest:Section({ Side = "Left" }),
}

sections.Mainsection1:Header({
	Name = "Movement"
})

sections.Mainsection2:Header({
	Name = "Stealth & Vision"
})

sections.Mainsection3:Header({
	Name = "Utilities"
})

sections.Automatesection1:Header({
	Name = "Lobby"
})

sections.Automatesection2:Header({
	Name = "In-Game"
})

sections.BoilingDeathsection1:Header({
	Name = "Teleports"
})

sections.Distancesection1:Header({
	Name = "Teleports"
})

sections.BattleRoyalesection3:Header({
	Name = "Hitbox Extender"
})

sections.Targetsection1:Header({
	Name = "Teleports"
})

sections.SolitaryConfinementsection1:Header({
	Name = "UNDER DEVELOPMENT"
})

sections.BeautyContestsection1:Header({
	Name = "UNDER DEVELOPMENT"
})

sections.Mainsection1:Slider({
    Name = "Walkspeed",
    Minimum = 16,
    Maximum = 200,
    Default = 16,
    Precision = 1,
    DisplayMethod = "Number",
    Callback = function(value)
        desiredWalkSpeed = value

        if walkSpeedConnection then
            walkSpeedConnection:Disconnect()
            walkSpeedConnection = nil
        end

        walkSpeedConnection = RunService.RenderStepped:Connect(function()
            local char = player.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum.WalkSpeed ~= desiredWalkSpeed then
                    hum.WalkSpeed = desiredWalkSpeed
                end
            end
        end)
    end,
}, "Walkspeed")

sections.Mainsection1:Slider({
    Name = "Jumppower",
    Minimum = 7.2,
    Maximum = 150,
    Default = 7.2,
    Precision = 1,
    DisplayMethod = "Number",
    Callback = function(value)
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")

        if humanoid then
            if humanoid.UseJumpPower ~= false then
                humanoid.JumpPower = value
            else
                humanoid.JumpHeight = value
            end
        end
    end,
}, "Jumppower")

sections.Mainsection1:Slider({
    Name = "Fly Speed",
    Minimum = 1,
    Maximum = 200,
    Default = 50,
    Precision = 1,
    DisplayMethod = "Number",
    Callback = function(value)
        baseSpeed = value
        if not flying then
            flySpeed = value
        end
    end,
}, "FlySpeed")

sections.Mainsection1:Keybind({
    Name = "Fly Toggle",
    Default = Enum.KeyCode.X,
    Callback = function(binded)
        if flying then
            stopFlying()
        else
            startFlying()
        end
    end,
    onBinded = function(bind)
        Window:Notify({
            Title = "BoogerLand",
            Description = "Fly keybind set to " .. tostring(bind.Name),
            Lifetime = 3
        })
    end,
}, "FlyKeybind")

sections.Mainsection1:Toggle({
	Name = "Noclip",
	Default = false,
	Callback = function(enabled)
		if enabled then
			Clip = false
			local function NoclipLoop()
				if Clip == false and player.Character then
					for _, child in pairs(player.Character:GetDescendants()) do
						if child:IsA("BasePart") and child.CanCollide == true then
							child.CanCollide = false
						end
					end
				end
			end
			Noclipping = RunService.Stepped:Connect(NoclipLoop)
			Window:Notify({
				Title = "Noclip",
				Description = "Noclip Enabled",
				Lifetime = 4
			})
		else
			Clip = true
			if Noclipping then
				Noclipping:Disconnect()
				Noclipping = nil
			end
			Window:Notify({
				Title = "Noclip",
				Description = "Noclip Disabled",
				Lifetime = 4
			})
		end
	end,
}, "NoclipToggle")

sections.Mainsection1:Toggle({
	Name = "Infinite Jump",
	Default = false,
	Callback = function(enabled)
		if enabled then
			infJumpConnection = UserInputService.JumpRequest:Connect(function()
				if not infJumpDebounce and player.Character and player.Character:FindFirstChildWhichIsA("Humanoid") then
					infJumpDebounce = true
					player.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
					task.wait()
					infJumpDebounce = false
				end
			end)

			Window:Notify({
				Title = "BoogerLand",
				Description = "Infinite Jump Enabled",
				Lifetime = 3
			})
		else
			if infJumpConnection then
				infJumpConnection:Disconnect()
				infJumpConnection = nil
			end
			infJumpDebounce = false

			Window:Notify({
				Title = "BoogerLand",
				Description = "Infinite Jump Disabled",
				Lifetime = 3
			})
		end
	end,
}, "InfJumpToggle")

sections.Mainsection2:Button({
	Name = "FE Invisibility (Key: G)",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/vinxiii1/FE-invisibility/refs/heads/main/invisible.lua", true))()
		Window:Notify({
			Title = "BoogerLand",
			Description = "Invisibility script loaded!",
			Lifetime = 3
		})
	end,
}, "FEInvisibilityButton")

sections.Mainsection2:Toggle({
	Name = "Player ESP",
	Default = false,
	Callback = function(enabled)
		espEnabled = enabled

		if enabled then
			if game:GetService("CoreGui"):FindFirstChild("ESP_Container") then
				game:GetService("CoreGui"):FindFirstChild("ESP_Container"):Destroy()
			end

			local RunService = game:GetService("RunService")
			local CoreGui = game:GetService("CoreGui")
			local Players = game:GetService("Players")
			local LocalPlayer = Players.LocalPlayer

			espFolder = Instance.new("Folder")
			espFolder.Name = "ESP_Container"
			espFolder.Parent = CoreGui

			espObjects = {}

			local function createESPPart(part, color)
				local success, adorn = pcall(function()
					local box = Instance.new("BoxHandleAdornment")
					box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
					box.Adornee = part
					box.AlwaysOnTop = true
					box.ZIndex = 0
					box.Transparency = espTransparency 
					box.Color3 = color
					box.Parent = espFolder
					return box
				end)
				if success then
					return adorn
				else
					return nil
				end
			end

			espConnection = RunService.RenderStepped:Connect(function()
				for _, model in ipairs(workspace:GetChildren()) do
					local humanoid = model:FindFirstChildOfClass("Humanoid")
					if humanoid and model ~= LocalPlayer.Character then
						if not espObjects[model] then
							espObjects[model] = {}
							for _, part in ipairs(model:GetChildren()) do
								if part:IsA("BasePart") then
									local adorn = createESPPart(part, espColor) 
									if adorn then
										table.insert(espObjects[model], adorn)
									end
								end
							end
						else

							for _, adorn in ipairs(espObjects[model]) do
								if adorn and adorn.Parent then
									adorn.Color3 = espColor
									adorn.Transparency = espTransparency
								end
							end
						end
					end
				end

				for model, adorns in pairs(espObjects) do
					if not model.Parent or not model:FindFirstChildOfClass("Humanoid") then
						for _, adorn in ipairs(adorns) do
							if adorn and adorn.Parent then
								adorn:Destroy()
							end
						end
						espObjects[model] = nil
					end
				end
			end)

			Window:Notify({
				Title = "BoogerLand",
				Description = "ESP Enabled",
				Lifetime = 3
			})
		else
			if espConnection then espConnection:Disconnect() end
			if espFolder then espFolder:Destroy() end
			espObjects = {}

			Window:Notify({
				Title = "BoogerLand",
				Description = "ESP Disabled",
				Lifetime = 3
			})
		end
	end,
}, "PlayerESPToggle")

sections.Mainsection2:Colorpicker({
	Name = "ESP Color",
	Default = Color3.fromRGB(0, 255, 0), 
	Alpha = 0.7, 
	Callback = function(color, alpha)
		espColor = color
		espTransparency = alpha

		if espEnabled and espObjects then
			for model, adorns in pairs(espObjects) do
				for _, adorn in ipairs(adorns) do
					if adorn and adorn.Parent then
						adorn.Color3 = color
						adorn.Transparency = alpha
					end
				end
			end
		end
		Window:Notify({
			Title = "BoogerLand",
			Description = "ESP Color & Transparency Updated",
			Lifetime = 2
		})
	end,
}, "ESPColorPicker")

sections.Mainsection3:Input({
    Name = "Teleport to Player",
    Placeholder = "Enter player name",
    AcceptedCharacters = "All",
    Callback = function(input)
        local function stringSimilarity(a, b)
            a, b = a:lower(), b:lower()
            local score = 0
            for i = 1, math.min(#a, #b) do
                if a:sub(i, i) == b:sub(i, i) then
                    score = score + 1
                else
                    break
                end
            end
            return score
        end

        local function findClosestPlayer(partial)
            local bestMatch = nil
            local bestScore = -1
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                if targetPlayer ~= player then
                    local displayScore = stringSimilarity(partial, targetPlayer.DisplayName)
                    local usernameScore = stringSimilarity(partial, targetPlayer.Name)
                    if displayScore > bestScore then
                        bestScore = displayScore
                        bestMatch = targetPlayer
                    elseif usernameScore > bestScore and bestMatch == nil then
                        bestScore = usernameScore
                        bestMatch = targetPlayer
                    end
                end
            end
            return bestMatch
        end

        if input == "" then return end
        local targetPlayer = findClosestPlayer(input)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                myHRP.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                Window:Notify({
                    Title = "BoogerLand",
                    Description = "Teleported to " .. targetPlayer.DisplayName,
                    Lifetime = 3
                })
            end
        end
    end,
}, "TeleportInput")

sections.DeadOrAlivesection1:Toggle({
	Name = "Camera Unlock",
	Default = false,
	Callback = function(enabled)
		cameraUnlockEnabled = enabled

		if enabled then
			originalCameraMode = player.CameraMode
			originalCameraType = Camera.CameraType
			originalMaxZoom = player.CameraMaxZoomDistance
			originalMinZoom = player.CameraMinZoomDistance
			originalCursorVisible = UserInputService.MouseIconEnabled

			cameraUnlockConnection = RunService.Heartbeat:Connect(function()
				if cameraUnlockEnabled then
					applyCameraUnlockSettings()
				end
			end)

			Window:Notify({
				Title = "BoogerLand",
				Description = "Camera Unlock Enabled",
				Lifetime = 3
			})
		else
			if cameraUnlockConnection then
				cameraUnlockConnection:Disconnect()
				cameraUnlockConnection = nil
			end
			restoreCameraSettings()

			Window:Notify({
				Title = "BoogerLand",
				Description = "Camera Unlock Disabled",
				Lifetime = 3
			})
		end
	end,
}, "CameraUnlockToggle")

player.CharacterAdded:Connect(function(newCharacter)
    if flying then
        stopFlying()
    end

    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    HRP = character:WaitForChild("HumanoidRootPart")

    if bodyVelocity then
        bodyVelocity:Destroy()
    end
    if bodyGyro then
        bodyGyro:Destroy()
    end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)

    task.wait(1)
    if cameraUnlockEnabled then
    end
end)

sections.DeadOrAlivesection1:Toggle({
	Name = "Noclip Camera",
	Default = false,
	Callback = function(state)
		local sc = (debug and debug.setconstant) or setconstant
		local gc = (debug and debug.getconstants) or getconstants

		if not sc or not getgc or not gc then
			Window:Notify({
				Title = "BoogerLand",
				Description = "Exploit doesn't support getgc/setconstant.",
				Lifetime = 4
			})
			return
		end

		local success = pcall(function()
			local pop = game.Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")
				:WaitForChild("CameraModule"):WaitForChild("ZoomController"):WaitForChild("Popper")

			for _, func in pairs(getgc()) do
				if typeof(func) == "function" and getfenv(func).script == pop then
					for index, constant in pairs(gc(func)) do
						if state then

							if tonumber(constant) == 0.25 then
								sc(func, index, 0)
							elseif tonumber(constant) == 0 then
								sc(func, index, 0.25)
							end
						else

							if tonumber(constant) == 0 then
								sc(func, index, 0.25)
							elseif tonumber(constant) == 0.25 then
								sc(func, index, 0)
							end
						end
					end
				end
			end
		end)

		if success then
			noclipCamEnabled = state
			Window:Notify({
				Title = "BoogerLand",
				Description = (state and "Enabled" or "Disabled") .. " Noclip Camera",
				Lifetime = 3
			})
		else
			Window:Notify({
				Title = "BoogerLand",
				Description = "Failed to toggle Noclip Camera.",
				Lifetime = 4
			})
		end
	end,
})

sections.Tagsection1:Toggle({
    Name = "Tag Text ESP",
    Default = false,
    Callback = function(enabled)
        tagTextESPEnabled = enabled

        if enabled then
            if game:GetService("CoreGui"):FindFirstChild("TAG_TAGGER_ESP") then
                game:GetService("CoreGui"):FindFirstChild("TAG_TAGGER_ESP"):Destroy()
            end

            tagTextESPFolder = Instance.new("Folder")
            tagTextESPFolder.Name = "TAG_TAGGER_ESP"
            tagTextESPFolder.Parent = game:GetService("CoreGui")

            tagTextESPConnection = RunService.RenderStepped:Connect(function()
                setupTagTextESP()
            end)

            Window:Notify({
                Title = "BoogerLand",
                Description = "Tag Text ESP Enabled",
                Lifetime = 3
            })
        else
            if tagTextESPConnection then 
                tagTextESPConnection:Disconnect() 
                tagTextESPConnection = nil
            end
            if tagTextESPFolder then 
                tagTextESPFolder:Destroy() 
                tagTextESPFolder = nil
            end

            Window:Notify({
                Title = "BoogerLand",
                Description = "Tag Text ESP Disabled",
                Lifetime = 3
            })
        end
    end,
}, "TagTextESPToggle")

sections.Tagsection1:Colorpicker({
    Name = "Tag Text ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        tagTextESPColor = color

        if tagTextESPEnabled and tagTextESPFolder then
            for _, billboard in pairs(tagTextESPFolder:GetChildren()) do
                local label = billboard:FindFirstChild("TextLabel")
                if label then
                    label.TextColor3 = color
                end
            end
        end

        Window:Notify({
            Title = "BoogerLand",
            Description = "Tag Text ESP Color Updated",
            Lifetime = 2
        })
    end,
}, "TagTextESPColorPicker")

sections.Tagsection1:Toggle({
    Name = "Tag Highlight ESP",
    Default = false,
    Callback = function(enabled)
        tagHighlightESPEnabled = enabled

        if enabled then
            tagHighlightESPConnection = RunService.RenderStepped:Connect(function()
                setupTagHorseHeadMonitoring()
            end)

            Window:Notify({
                Title = "BoogerLand",
                Description = "Tag Highlight ESP Enabled",
                Lifetime = 3
            })
        else
            if tagHighlightESPConnection then 
                tagHighlightESPConnection:Disconnect() 
                tagHighlightESPConnection = nil
            end
            removeAllTagHighlights()

            Window:Notify({
                Title = "BoogerLand",
                Description = "Tag Highlight ESP Disabled",
                Lifetime = 3
            })
        end
    end,
}, "TagHighlightESPToggle")

sections.Tagsection1:Colorpicker({
    Name = "Tag Highlight ESP Color",
    Default = Color3.fromRGB(255, 255, 0),
    Alpha = 0.4,
    Callback = function(color, alpha)
        tagHighlightESPColor = color
        tagHighlightESPTransparency = alpha

        if tagHighlightESPEnabled then
            local tag = workspace:FindFirstChild("Tag")
            if tag then
                for _, descendant in ipairs(tag:GetDescendants()) do
                    local highlight = descendant:FindFirstChild("TagHorseESP_Highlight")
                    if highlight then
                        highlight.FillColor = color
                        highlight.OutlineColor = color
                        highlight.FillTransparency = alpha
                    end
                end
            end
        end

        Window:Notify({
            Title = "BoogerLand",
            Description = "Tag Highlight ESP Color & Transparency Updated",
            Lifetime = 2
        })
    end,
}, "TagHighlightESPColorPicker")

sections.HideAndSeeksection1:Dropdown({
    Name = "Teleport to Player",
    Multi = false,
    Required = false,
    Options = (function()
        local playerList = {}
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                table.insert(playerList, targetPlayer.DisplayName)
            end
        end
        return playerList
    end)(),
    Search = true,
    Callback = function(selectedPlayer)
        if selectedPlayer == "" or selectedPlayer == nil then return end

        local targetPlayer = nil
        for _, p in pairs(Players:GetPlayers()) do
            if p.DisplayName == selectedPlayer and p ~= player then
                targetPlayer = p
                break
            end
        end

        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                myHRP.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                Window:Notify({
                    Title = "BoogerLand",
                    Description = "Teleported to " .. targetPlayer.DisplayName,
                    Lifetime = 3
                })
            else
                Window:Notify({
                    Title = "BoogerLand",
                    Description = "Could not find your character",
                    Lifetime = 3
                })
            end
        else
            Window:Notify({
                Title = "BoogerLand",
                Description = "Player not found or has no character",
                Lifetime = 3
            })
        end
    end,
}, "PlayerTeleportDropdown")

sections.HideAndSeeksection1:Button({
    Name = "Refresh Player List",
    Callback = function()
        local newPlayerList = {}
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                table.insert(newPlayerList, targetPlayer.DisplayName)
            end
        end

        if MacLib.Options and MacLib.Options["PlayerTeleportDropdown"] then
            MacLib.Options["PlayerTeleportDropdown"]:ClearOptions()
            MacLib.Options["PlayerTeleportDropdown"]:InsertOptions(newPlayerList)

            Window:Notify({
                Title = "BoogerLand",
                Description = "Player list refreshed (" .. #newPlayerList .. " players)",
                Lifetime = 2
            })
        else
            Window:Notify({
                Title = "BoogerLand",
                Description = "Failed to refresh - dropdown not found",
                Lifetime = 3
            })
        end
    end,
}, "RefreshPlayerListButton")

sections.HideAndSeeksection2:Button({
	Name = "Teleport to Safe Place",
	Callback = function()
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = character:FindFirstChild("HumanoidRootPart")

		if HRP then
			HRP.CFrame = CFrame.new(-1796.04, 247.22, 982.80)
		end
	end,
}, "SafeTPButton")

sections.HideAndSeeksection2:Input({
    Name = "Steal Wolf",
    Placeholder = "Enter player name",
    Callback = function(inputName)
        teleportToAndBack(inputName)
    end
}, "StealWolfInput")

sections.HideAndSeeksection2:Toggle({
    Name = "Wolf ESP",
    Default = false,
    Callback = function(state)
        local workspace = game:GetService("Workspace")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if state then
            for _, playerModel in ipairs(workspace:GetChildren()) do
                if playerModel:IsA("Model") and playerModel.Name ~= LocalPlayer.Name then
                    local head = playerModel:FindFirstChild("Head")
                    if head then
                        local wolfDisplay = head:FindFirstChild("WolfDisplay")
                        if wolfDisplay and wolfDisplay:IsA("BillboardGui") then
                            wolfDisplay.AlwaysOnTop = true
                        end
                    end
                end
            end

            wolfESPConnection = workspace.ChildAdded:Connect(function(child)
                if child:IsA("Model") then
                    local head = child:WaitForChild("Head", 5)
                    if head then
                        local wolfDisplay = head:FindFirstChild("WolfDisplay")
                        if wolfDisplay and wolfDisplay:IsA("BillboardGui") then
                            wolfDisplay.AlwaysOnTop = true
                        end
                    end
                end
            end)
        else
            for _, playerModel in ipairs(workspace:GetChildren()) do
                if playerModel:IsA("Model") then
                    local head = playerModel:FindFirstChild("Head")
                    if head then
                        local wolfDisplay = head:FindFirstChild("WolfDisplay")
                        if wolfDisplay and wolfDisplay:IsA("BillboardGui") then
                            wolfDisplay.AlwaysOnTop = false
                        end
                    end
                end
            end

            if wolfESPConnection then
                wolfESPConnection:Disconnect()
                wolfESPConnection = nil
            end
        end
    end
})

sections.Osmosissection1:Button({
	Name = "Collect All Points",
	Callback = function()
		teleportToAllPointGivers()
	end
})

sections.Osmosissection1:Toggle({
	Name = "Auto Battle",
	Default = false,
	Callback = function(state)
		OsmosisTP = state
		if state then
			Window:Notify({
				Title = "BoogerLand",
				Description = "Auto Battle Enabled - Attacking enemies",
				Lifetime = 3
			})
		else
			Window:Notify({
				Title = "BoogerLand",
				Description = "Auto Battle Disabled",
				Lifetime = 3
			})
		end
	end
})

sections.Osmosissection2:Toggle({
    Name = "Team ESP",
    Default = false,
    Callback = function(enabled)
        osmosisESPEnabled = enabled
        if enabled then
            task.spawn(osmosisESPLoop)
            Window:Notify({
                Title = "BoogerLand",
                Description = "Osmosis Team ESP Enabled",
                Lifetime = 3
            })
        else
            Window:Notify({
                Title = "BoogerLand",
                Description = "Osmosis Team ESP Disabled",
                Lifetime = 3
            })
        end
    end,
}, "OsmosisTeamESP")

sections.Osmosissection2:Toggle({
    Name = "Enemy Only",
    Default = false,
    Callback = function(enabled)
        osmosisESPEnemyOnly = enabled

        if osmosisESPEnabled then
            clearOsmosisESP()
        end

        Window:Notify({
            Title = "BoogerLand",
            Description = osmosisESPEnemyOnly and "Osmosis ESP: Enemy Only Mode" or "Osmosis ESP: Show Both Teams",
            Lifetime = 3
        })
    end,
}, "OsmosisEnemyOnlyToggle")

sections.Osmosissection2:Colorpicker({
    Name = "Blue Team Color",
    Default = osmosisESPColorBlue,
    Alpha = osmosisESPAlphaBlue,  
    Callback = function(color, alpha)
        osmosisESPColorBlue = color
        osmosisESPAlphaBlue = alpha or 0.5  

        if osmosisESPEnabled then
            for _, data in pairs(osmosisProcessedModels) do
                local model = data.Model
                if model and model:IsDescendantOf(Workspace) and data.HighlightName == "BlueTeamHigh" then
                    local highlight = model:FindFirstChildOfClass("Highlight")
                    if highlight then
                        highlight.FillColor = color
                        highlight.OutlineColor = color:Lerp(Color3.new(0,0,0), 0.2)
                        highlight.FillTransparency = alpha or 0.5
                        highlight.OutlineTransparency = (alpha or 0.5) * 0.8
                    end
                end
            end
        end

        Window:Notify({
            Title = "BoogerLand",
            Description = "Osmosis Blue Team Color Updated",
            Lifetime = 2
        })
    end,
}, "OsmosisBlueTeamESPColor")

sections.Osmosissection2:Colorpicker({
    Name = "Red Team Color",
    Default = osmosisESPColorRed,
    Alpha = osmosisESPAlphaRed, 
    Callback = function(color, alpha)
        osmosisESPColorRed = color
        osmosisESPAlphaRed = alpha or 0.5  

        if osmosisESPEnabled then
            for _, data in pairs(osmosisProcessedModels) do
                local model = data.Model
                if model and model:IsDescendantOf(Workspace) and data.HighlightName == "RedTeamHigh" then
                    local highlight = model:FindFirstChildOfClass("Highlight")
                    if highlight then
                        highlight.FillColor = color
                        highlight.OutlineColor = color:Lerp(Color3.new(0,0,0), 0.2)
                        highlight.FillTransparency = alpha or 0.5
                        highlight.OutlineTransparency = (alpha or 0.5) * 0.8
                    end
                end
            end
        end

        Window:Notify({
            Title = "BoogerLand",
            Description = "Osmosis Red Team Color Updated",
            Lifetime = 2
        })
    end,
}, "OsmosisRedTeamESPColor")

sections.Checkmatesection1:Toggle({
	Name = "Auto Attack Players",
	Default = false,
	Callback = function(state)
		CheckmateTP = state
		if state then
			Window:Notify({
				Title = "BoogerLand",
				Description = "Checkmate Auto Attack Enabled",
				Lifetime = 3
			})
		else
			Window:Notify({
				Title = "BoogerLand",
				Description = "Checkmate Auto Attack Disabled",
				Lifetime = 3
			})
		end
	end
})

sections.Checkmatesection2:Toggle({
    Name = "Team ESP",
    Default = false,
    Callback = function(enabled)
        checkmateESPEnabled = enabled
        if enabled then
            task.spawn(checkmateESPLoop)
            Window:Notify({
                Title = "BoogerLand",
                Description = "Checkmate Team ESP Enabled",
                Lifetime = 3
            })
        else
            Window:Notify({
                Title = "BoogerLand",
                Description = "Checkmate Team ESP Disabled",
                Lifetime = 3
            })
        end
    end,
}, "CheckmateTeamESP")

sections.Checkmatesection2:Toggle({
    Name = "Enemy Only",
    Default = false,
    Callback = function(enabled)
        checkmateESPEnemyOnly = enabled

        if checkmateESPEnabled then
            clearCheckmateESP()
        end

        Window:Notify({
            Title = "BoogerLand",
            Description = checkmateESPEnemyOnly and "Checkmate ESP: Enemy Only Mode" or "Checkmate ESP: Show Both Teams",
            Lifetime = 3
        })
    end,
}, "CheckmateEnemyOnlyToggle")

sections.Checkmatesection2:Colorpicker({
    Name = "Blue Team Color",
    Default = checkmateESPColorBlue,
    Alpha = checkmateESPAlphaBlue,  
    Callback = function(color, alpha)
        checkmateESPColorBlue = color
        checkmateESPAlphaBlue = alpha or 0.5  

        if checkmateESPEnabled then
            for _, data in pairs(checkmateProcessedModels) do
                local model = data.Model
                if model and model:IsDescendantOf(Workspace) and data.HighlightName == "BlueTeamHigh" then
                    local highlight = model:FindFirstChildOfClass("Highlight")
                    if highlight then
                        highlight.FillColor = color
                        highlight.OutlineColor = color:Lerp(Color3.new(0,0,0), 0.2)
                        highlight.FillTransparency = alpha or 0.5
                        highlight.OutlineTransparency = (alpha or 0.5) * 0.8
                    end
                end
            end
        end

        Window:Notify({
            Title = "BoogerLand",
            Description = "Checkmate Blue Team Color Updated",
            Lifetime = 2
        })
    end,
}, "CheckmateBlueTeamESPColor")

sections.Checkmatesection2:Colorpicker({
    Name = "Red Team Color",
    Default = checkmateESPColorRed,
    Alpha = checkmateESPAlphaRed, 
    Callback = function(color, alpha)
        checkmateESPColorRed = color
        checkmateESPAlphaRed = alpha or 0.5  

        if checkmateESPEnabled then
            for _, data in pairs(checkmateProcessedModels) do
                local model = data.Model
                if model and model:IsDescendantOf(Workspace) and data.HighlightName == "RedTeamHigh" then
                    local highlight = model:FindFirstChildOfClass("Highlight")
                    if highlight then
                        highlight.FillColor = color
                        highlight.OutlineColor = color:Lerp(Color3.new(0,0,0), 0.2)
                        highlight.FillTransparency = alpha or 0.5
                        highlight.OutlineTransparency = (alpha or 0.5) * 0.8
                    end
                end
            end
        end

        Window:Notify({
            Title = "BoogerLand",
            Description = "Checkmate Red Team Color Updated",
            Lifetime = 2
        })
    end,
}, "CheckmateRedTeamESPColor")

sections.BoilingDeathsection1:Button({
	Name = "Teleport to First Checkpoint",
	Callback = function()
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:WaitForChild("HumanoidRootPart")

		local targetPosition = Vector3.new(-957.89, 6.46, 2269.61)
		HRP.CFrame = CFrame.new(targetPosition + Vector3.new(0, 0.5, 0)) 
	end,
}, "TPFirstCheckpoint")

sections.BoilingDeathsection1:Button({
	Name = "Teleport to Second Checkpoint",
	Callback = function()
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:WaitForChild("HumanoidRootPart")

		local targetPosition = Vector3.new(-1219.74, -62.04, 2554.63)
		HRP.CFrame = CFrame.new(targetPosition + Vector3.new(0, 0.5, 0)) 
	end,
}, "TPSecCheckpoint")

sections.BoilingDeathsection1:Button({
	Name = "Teleport to Finish",
	Callback = function()
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:WaitForChild("HumanoidRootPart")

		local targetPosition = Vector3.new(-1162.07, 42.14, 2790.51)
		HRP.CFrame = CFrame.new(targetPosition + Vector3.new(0, 0.5, 0)) 
	end,
}, "TPFinish")

sections.BoilingDeathsection2:Button({
	Name = "Remove Camera Shake",
	Callback = function()
		local RunService = game:GetService("RunService")
		RunService:UnbindFromRenderStep("CameraShaker")
		local camera = workspace.CurrentCamera
		local player = game.Players.LocalPlayer
		camera.CameraType = Enum.CameraType.Custom
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		else
			camera.CameraSubject = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
		end

		Window:Notify({
			Title = "BoogerLand",
			Description = "Camera Reset Successfully",
			Lifetime = 3
		})
	end,
}, "ResetCameraButton")

sections.Labyrinthsection1:Toggle({
	Name = "Camera Unlock",
	Default = false,
	Callback = function(enabled)
		cameraUnlockEnabled = enabled

		if enabled then
			originalCameraMode = player.CameraMode
			originalCameraType = Camera.CameraType
			originalMaxZoom = player.CameraMaxZoomDistance
			originalMinZoom = player.CameraMinZoomDistance
			originalCursorVisible = UserInputService.MouseIconEnabled

			cameraUnlockConnection = RunService.Heartbeat:Connect(function()
				if cameraUnlockEnabled then
					applyCameraUnlockSettings()
				end
			end)

			Window:Notify({
				Title = "BoogerLand",
				Description = "Camera Unlock Enabled",
				Lifetime = 3
			})
		else
			if cameraUnlockConnection then
				cameraUnlockConnection:Disconnect()
				cameraUnlockConnection = nil
			end
			restoreCameraSettings()

			Window:Notify({
				Title = "BoogerLand",
				Description = "Camera Unlock Disabled",
				Lifetime = 3
			})
		end
	end,
}, "CameraUnlockToggle")

player.CharacterAdded:Connect(function(newCharacter)
    if flying then
        stopFlying()
    end

    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    HRP = character:WaitForChild("HumanoidRootPart")

    if bodyVelocity then
        bodyVelocity:Destroy()
    end
    if bodyGyro then
        bodyGyro:Destroy()
    end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)

    task.wait(1)
end)

sections.Labyrinthsection1:Button({
	Name = "Teleport to Exit",
	Callback = function()
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:WaitForChild("HumanoidRootPart")

		local targetPosition = Vector3.new(1683.98, 3.14, 1262.38)
		HRP.CFrame = CFrame.new(targetPosition + Vector3.new(0, 0.5, 0)) 
	end,
}, "TPExit")

sections.Distancesection1:Button({
	Name = "Teleport to End",
	Callback = function()
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:WaitForChild("HumanoidRootPart")

		local targetPosition = Vector3.new(937.97, 18.36, -4796.38)
		HRP.CFrame = CFrame.new(targetPosition + Vector3.new(0, 0.5, 0)) 
	end,
}, "TPEnd")

sections.Distancesection1:Button({
	Name = "Teleport to Bus",
	Callback = function()
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:WaitForChild("HumanoidRootPart")

		local targetPosition = Vector3.new(915.94, 13.17, -3275.60)
		HRP.CFrame = CFrame.new(targetPosition + Vector3.new(0, 0.5, 0)) 
	end,
}, "TPBus")

sections.BattleRoyalesection1:Toggle({
    Name = "Get All Tools",
    Default = false,
    Callback = function(enabled)
        getAllToolsEnabled = enabled

        if enabled then
            setupGetAllTools()
            Window:Notify({
                Title = "BoogerLand",
                Description = "Get All Tools Enabled - Will teleport to new tools",
                Lifetime = 3
            })
        else
            if getAllToolsConnection then
                getAllToolsConnection:Disconnect()
                getAllToolsConnection = nil
            end
            Window:Notify({
                Title = "BoogerLand",
                Description = "Get All Tools Disabled",
                Lifetime = 3
            })
        end
    end,
}, "GetAllToolsToggle")

sections.BattleRoyalesection1:Button({
    Name = "Get Tool",
    Callback = function()
        getFirstTool()
    end,
}, "GetToolButton")

sections.BattleRoyalesection2:Toggle({
    Name = "Tool ESP",
    Default = false,
    Callback = function(enabled)
        toolESPEnabled = enabled

        if enabled then
            setupToolESP()
            Window:Notify({
                Title = "BoogerLand",
                Description = "Tool ESP Enabled",
                Lifetime = 3
            })
        else
            removeAllToolESP()
            Window:Notify({
                Title = "BoogerLand",
                Description = "Tool ESP Disabled",
                Lifetime = 3
            })
        end
    end,
}, "ToolESPToggle")

sections.BattleRoyalesection2:Colorpicker({
    Name = "Tool ESP Color",
    Default = Color3.fromRGB(255, 255, 0), 
    Callback = function(color)
        toolESPColor = color

        if toolESPEnabled then
            for tool, objects in pairs(toolESPObjects) do
                for _, billboard in ipairs(objects) do
                    if billboard and billboard.Parent then
                        local textLabel = billboard:FindFirstChild("TextLabel")
                        if textLabel then
                            textLabel.TextColor3 = color
                        end
                    end
                end
            end
        end

        Window:Notify({
            Title = "BoogerLand",
            Description = "Tool ESP Color Updated",
            Lifetime = 2
        })
    end,
}, "ToolESPColorPicker")

sections.BattleRoyalesection3:Toggle({
	Name = "Hitbox Expander",
	Default = false,
	Callback = function(state)
		hitboxEnabled = state
		updateAllPlayers()
		Window:Notify({
			Title = "Hitbox Expander",
			Description = (state and "Enabled" or "Disabled") .. " hitboxes",
			Lifetime = 3
		})
	end,
}, "HitboxExpanderToggle")

sections.BattleRoyalesection3:Slider({
	Name = "Hitbox Size",
	Minimum = 5,
	Maximum = 150,
	Default = hitboxSize,
	Precision = 1,
	DisplayMethod = "Number",
	Callback = function(size)
		hitboxSize = size
		if hitboxEnabled then
			updateAllPlayers()
		end
	end,
}, "HitboxSizeSlider")

sections.BattleRoyalesection3:Keybind({
	Name = "Toggle Keybind",
	Blacklist = false,
	Default = toggleKey,
	Callback = function(key)
		if keyConnection then keyConnection:Disconnect() end
		toggleKey = key
		keyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and input.KeyCode == toggleKey then
				hitboxEnabled = not hitboxEnabled
				updateAllPlayers()
				Window:Notify({
					Title = "Hitbox Expander",
					Description = (hitboxEnabled and "Enabled" or "Disabled") .. " via keybind",
					Lifetime = 3
				})
			end
		end)
	end,
}, "HitboxToggleKey")

sections.WitchHuntsection1:Button({
	Name = "Get Knife",
	Callback = function()
		local Players = game:GetService("Players")
		local Workspace = game:GetService("Workspace")
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:WaitForChild("HumanoidRootPart")

		local witchHuntFolder = Workspace:FindFirstChild("WitchHunt")
		if not witchHuntFolder then
			Window:Notify({
				Title = "BoogerLand",
				Description = "WitchHunt folder not found",
				Lifetime = 3
			})
			return
		end

		local knifeFolder = witchHuntFolder:FindFirstChild("SavedKnives")
		if not knifeFolder then
			Window:Notify({
				Title = "BoogerLand",
				Description = "SavedKnives folder not found",
				Lifetime = 3
			})
			return
		end

		local foundKnife = false
		for _, knife in ipairs(knifeFolder:GetChildren()) do
			if knife:IsA("Part") then
				local handle = knife:FindFirstChild("Handle")
				if handle and handle:IsA("BasePart") then
					HRP.CFrame = handle.CFrame + Vector3.new(0, 1.5, 0)
					task.wait(1)

					for _, obj in ipairs(knife:GetDescendants()) do
						if obj:IsA("ProximityPrompt") and obj.Enabled then
							pcall(function()
								obj.MaxActivationDistance = 100
								fireproximityprompt(obj)
							end)

							Window:Notify({
								Title = "BoogerLand",
								Description = "Picked up knife: " .. knife.Name,
								Lifetime = 3
							})

							foundKnife = true
							break
						end
					end

					if foundKnife then break end
				end
			end
		end

		if not foundKnife then
			Window:Notify({
				Title = "BoogerLand",
				Description = "No valid knife found with ProximityPrompt",
				Lifetime = 3
			})
		end
	end
})

sections.WitchHuntsection1:Button({
	Name = "Get All Clues",
	Callback = function()
		local Players = game:GetService("Players")
		local Workspace = game:GetService("Workspace")

		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:WaitForChild("HumanoidRootPart")

		local witchHuntFolder = Workspace:FindFirstChild("WitchHunt")
		if not witchHuntFolder then
			Window:Notify({
				Title = "BoogerLand",
				Description = "WitchHunt folder not found",
				Lifetime = 3
			})
			return
		end

		local CluesFolder = witchHuntFolder:FindFirstChild("Clues")
		if not CluesFolder then
			Window:Notify({
				Title = "BoogerLand",
				Description = "Clues folder not found",
				Lifetime = 3
			})
			return
		end

		local clueCount = 0
		local function collectClue(part)
			if not part:IsA("BasePart") then return end

			local prompt = part:FindFirstChildOfClass("ProximityPrompt")
			if not prompt then
				part.ChildAdded:Connect(function(child)
					if child:IsA("ProximityPrompt") then
						task.wait(0.25)
						fireproximityprompt(child)
						clueCount = clueCount + 1
						Window:Notify({
							Title = "BoogerLand",
							Description = "Collected clue: " .. part.Name,
							Lifetime = 2
						})
					end
				end)
			else
				HRP.CFrame = part.CFrame + Vector3.new(0, 0.5, 0)
				task.wait(0.35)
				fireproximityprompt(prompt)
				clueCount = clueCount + 1
				Window:Notify({
					Title = "BoogerLand",
					Description = "Collected clue: " .. part.Name,
					Lifetime = 2
				})
			end
		end

		Window:Notify({
			Title = "BoogerLand",
			Description = "Starting clue collection...",
			Lifetime = 3
		})

		for _, clue in ipairs(CluesFolder:GetChildren()) do
			collectClue(clue)
			task.wait(0.5)
		end

		Window:Notify({
			Title = "BoogerLand",
			Description = "Finished collecting " .. clueCount .. " clues",
			Lifetime = 4
		})
	end
})

sections.WitchHuntsection2:Toggle({
	Name = "Knife ESP",
	Default = false,
	Callback = function(state)
		knifeESPToggle = state

		local Workspace = game:GetService("Workspace")
		local witchHuntFolder = Workspace:FindFirstChild("WitchHunt")
		if not witchHuntFolder then
			Window:Notify({
				Title = "BoogerLand",
				Description = "WitchHunt folder not found",
				Lifetime = 3
			})
			return
		end

		local knifeFolder = witchHuntFolder:FindFirstChild("SavedKnives")
		if not knifeFolder then
			Window:Notify({
				Title = "BoogerLand",
				Description = "SavedKnives folder not found",
				Lifetime = 3
			})
			return
		end

		local function addTextESP(part)
			if part:FindFirstChild("KnifeESP") then return end

			local billboard = Instance.new("BillboardGui")
			billboard.Name = "KnifeESP"
			billboard.Adornee = part
			billboard.Size = UDim2.new(0, 100, 0, 30)
			billboard.StudsOffset = Vector3.new(0, 2, 0)
			billboard.AlwaysOnTop = true
			billboard.Parent = part

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = "🔪 Knife"
			label.TextColor3 = knifeESPColor
			label.TextStrokeTransparency = 0.5
			label.TextScaled = true
			label.Font = Enum.Font.SourceSansBold
			label.Parent = billboard
		end

		if state then
			local knifeCount = 0
			for _, knife in ipairs(knifeFolder:GetChildren()) do
				if knife:IsA("Part") then
					local handle = knife:FindFirstChild("Handle")
					if handle and handle:IsA("BasePart") then
						addTextESP(handle)
						knifeCount = knifeCount + 1
					end
				end
			end

			table.insert(knifeESPConnections, knifeFolder.ChildAdded:Connect(function(knife)
				if knife:IsA("Part") then
					local conn = knife.ChildAdded:Connect(function(child)
						if child.Name == "Handle" and child:IsA("BasePart") then
							addTextESP(child)
						end
					end)
					table.insert(knifeESPConnections, conn)

					task.wait(0.1)
					local handle = knife:FindFirstChild("Handle")
					if handle then
						addTextESP(handle)
					end
				end
			end))

			Window:Notify({
				Title = "BoogerLand",
				Description = "Knife ESP Enabled (" .. knifeCount .. " knives found)",
				Lifetime = 3
			})
		else
			local removedCount = 0
			for _, knife in ipairs(knifeFolder:GetChildren()) do
				if knife:IsA("Part") then
					local handle = knife:FindFirstChild("Handle")
					if handle and handle:FindFirstChild("KnifeESP") then
						handle:FindFirstChild("KnifeESP"):Destroy()
						removedCount = removedCount + 1
					end
				end
			end

			for _, conn in ipairs(knifeESPConnections) do
				if typeof(conn) == "RBXScriptConnection" then
					conn:Disconnect()
				end
			end
			table.clear(knifeESPConnections)

			Window:Notify({
				Title = "BoogerLand",
				Description = "Knife ESP Disabled (" .. removedCount .. " labels removed)",
				Lifetime = 3
			})
		end
	end
})

sections.WitchHuntsection2:Colorpicker({
	Name = "Knife ESP Color",
	Default = Color3.fromRGB(255, 0, 0),
	Callback = function(color)
		knifeESPColor = color

		if knifeESPToggle then
			local Workspace = game:GetService("Workspace")
			local witchHuntFolder = Workspace:FindFirstChild("WitchHunt")
			if witchHuntFolder then
				local knifeFolder = witchHuntFolder:FindFirstChild("SavedKnives")
				if knifeFolder then
					for _, knife in ipairs(knifeFolder:GetChildren()) do
						if knife:IsA("Part") then
							local handle = knife:FindFirstChild("Handle")
							if handle then
								local billboard = handle:FindFirstChild("KnifeESP")
								if billboard then
									local label = billboard:FindFirstChild("TextLabel")
									if label then
										label.TextColor3 = color
									end
								end
							end
						end
					end
				end
			end
		end

		Window:Notify({
			Title = "BoogerLand",
			Description = "Knife ESP Color Updated",
			Lifetime = 2
		})
	end,
}, "KnifeESPColorPicker")

sections.Targetsection1:Button({
	Name = "Teleport to Safe Spot",
	Callback = function()
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:FindFirstChild("HumanoidRootPart")

		if HRP then
			local targetPosition = Vector3.new(1527.76, 95.29, 141.60)
			HRP.CFrame = CFrame.new(targetPosition + Vector3.new(0, 0.5, 0))

			Window:Notify({
				Title = "BoogerLand",
				Description = "Teleported successfully!",
				Lifetime = 3
			})
		else
			Window:Notify({
				Title = "BoogerLand",
				Description = "Character not found!",
				Lifetime = 3
			})
		end
	end,
}, "TargetTP")

sections.Labyrinthsection2:Button({
    Name = "Teleport to Random Player",
    Callback = function()
        local availablePlayers = {}

        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= player and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(availablePlayers, targetPlayer)
            end
        end

        if #availablePlayers == 0 then
            Window:Notify({
                Title = "BoogerLand",
                Description = "No players available to teleport to",
                Lifetime = 3
            })
            return
        end

        local randomIndex = math.random(1, #availablePlayers)
        local randomPlayer = availablePlayers[randomIndex]

        local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if myHRP then
            myHRP.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            Window:Notify({
                Title = "BoogerLand",
                Description = "Teleported to random player: " .. randomPlayer.DisplayName,
                Lifetime = 3
            })
        else
            Window:Notify({
                Title = "BoogerLand",
                Description = "Could not find your character",
                Lifetime = 3
            })
        end
    end,
}, "RandomTeleportButton")

sections.Checkmatesection1:Button({
	Name = "Teleport to Safe Zone",
	Callback = function()
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:FindFirstChild("HumanoidRootPart")

		if HRP then
			local safezonePosition = Vector3.new(2033.12, 193.84, -484.36)
			HRP.CFrame = CFrame.new(safezonePosition + Vector3.new(0, 0.5, 0))

			Window:Notify({
				Title = "BoogerLand",
				Description = "Teleported to Checkmate Safe Zone",
				Lifetime = 3
			})
		else
			Window:Notify({
				Title = "BoogerLand",
				Description = "Character not found!",
				Lifetime = 3
			})
		end
	end,
}, "CheckmateSafeZoneButton")

sections.WitchHuntsection2:Toggle({
	Name = "Clue ESP",
	Default = false,
	Callback = function(state)
		cluesESPToggle = state

		local Workspace = game:GetService("Workspace")
		local witchHuntFolder = Workspace:FindFirstChild("WitchHunt")
		if not witchHuntFolder then
			Window:Notify({
				Title = "BoogerLand",
				Description = "WitchHunt folder not found",
				Lifetime = 3
			})
			return
		end

		local cluesFolder = witchHuntFolder:FindFirstChild("Clues")
		if not cluesFolder then
			Window:Notify({
				Title = "BoogerLand",
				Description = "Clues folder not found",
				Lifetime = 3
			})
			return
		end

		local function addTextESP(part)
			if not part:IsA("BasePart") then return end
			if part:FindFirstChild("ClueESP") then return end 

			local billboard = Instance.new("BillboardGui")
			billboard.Name = "ClueESP"
			billboard.Adornee = part
			billboard.Size = UDim2.new(0, 120, 0, 30)
			billboard.StudsOffset = Vector3.new(0, 2, 0)
			billboard.AlwaysOnTop = true
			billboard.Parent = part

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = "🧩 " .. part.Name
			label.TextColor3 = cluesESPColor
			label.TextStrokeTransparency = 0.5
			label.TextScaled = true
			label.Font = Enum.Font.SourceSansBold
			label.Parent = billboard
		end

		if state then
			local clueCount = 0
			for _, clue in ipairs(cluesFolder:GetChildren()) do
				if clue:IsA("BasePart") then
					addTextESP(clue)
					clueCount = clueCount + 1
				end
			end

			table.insert(cluesESPConnections, cluesFolder.ChildAdded:Connect(function(clue)
				if clue:IsA("BasePart") then
					task.wait(0.1) 
					addTextESP(clue)
				end
			end))

			Window:Notify({
				Title = "BoogerLand",
				Description = "Clue ESP Enabled (" .. clueCount .. " clues found)",
				Lifetime = 3
			})
		else
			local removedCount = 0
			for _, clue in ipairs(cluesFolder:GetChildren()) do
				if clue:IsA("BasePart") and clue:FindFirstChild("ClueESP") then
					clue:FindFirstChild("ClueESP"):Destroy()
					removedCount = removedCount + 1
				end
			end

			for _, conn in ipairs(cluesESPConnections) do
				if typeof(conn) == "RBXScriptConnection" then
					conn:Disconnect()
				end
			end
			table.clear(cluesESPConnections)

			Window:Notify({
				Title = "BoogerLand",
				Description = "Clue ESP Disabled (" .. removedCount .. " labels removed)",
				Lifetime = 3
			})
		end
	end
})

sections.WitchHuntsection2:Colorpicker({
	Name = "Clue ESP Color",
	Default = Color3.fromRGB(255, 255, 0),
	Callback = function(color)
		cluesESPColor = color

		if cluesESPToggle then
			local Workspace = game:GetService("Workspace")
			local witchHuntFolder = Workspace:FindFirstChild("WitchHunt")
			if witchHuntFolder then
				local cluesFolder = witchHuntFolder:FindFirstChild("Clues")
				if cluesFolder then
					for _, clue in ipairs(cluesFolder:GetChildren()) do
						if clue:IsA("BasePart") then
							local billboard = clue:FindFirstChild("ClueESP")
							if billboard then
								local label = billboard:FindFirstChild("TextLabel")
								if label then
									label.TextColor3 = color
								end
							end
						end
					end
				end
			end
		end

		Window:Notify({
			Title = "BoogerLand",
			Description = "Clue ESP Color Updated",
			Lifetime = 2
		})
	end,
}, "ClueESPColorPicker")

sections.Mainsection3:Input({
    Name = "Spectate Player",
    Placeholder = "Enter player name",
    AcceptedCharacters = "All",
    Callback = function(input)
        local Players = game:GetService("Players")
        local Camera = workspace.CurrentCamera
        local LocalPlayer = Players.LocalPlayer

        local function stringSimilarity(a, b)
            a, b = a:lower(), b:lower()
            local score = 0
            for i = 1, math.min(#a, #b) do
                if a:sub(i, i) == b:sub(i, i) then
                    score = score + 1
                else
                    break
                end
            end
            return score
        end

        local function findClosestPlayer(partial)
            local bestMatch = nil
            local bestScore = -1
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                if targetPlayer ~= LocalPlayer then
                    local displayScore = stringSimilarity(partial, targetPlayer.DisplayName)
                    local usernameScore = stringSimilarity(partial, targetPlayer.Name)
                    local score = math.max(displayScore, usernameScore)
                    if score > bestScore then
                        bestScore = score
                        bestMatch = targetPlayer
                    end
                end
            end
            return bestMatch
        end

        local function spectatePlayer(targetPlayer)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = targetPlayer.Character.Humanoid
                Camera.CameraType = Enum.CameraType.Custom
                Window:Notify({
                    Title = "BoogerLand",
                    Description = "Now spectating: " .. targetPlayer.DisplayName,
                    Lifetime = 3
                })
                return true
            else
                Window:Notify({
                    Title = "BoogerLand",
                    Description = "Cannot spectate " .. (targetPlayer and targetPlayer.DisplayName or "player") .. " - No character found",
                    Lifetime = 3
                })
                return false
            end
        end

        if input == "" then 
            Window:Notify({
                Title = "BoogerLand",
                Description = "Please enter a player name",
                Lifetime = 3
            })
            return 
        end

        local targetPlayer = findClosestPlayer(input)
        if targetPlayer then
            spectatePlayer(targetPlayer)
        else
            Window:Notify({
                Title = "BoogerLand",
                Description = "Player '" .. input .. "' not found",
                Lifetime = 3
            })
        end
    end,
}, "SpectateInput")

local spectatedPlayers = {}
local currentSpectateIndex = 1

sections.Mainsection3:Button({
    Name = "Random Spectate",
    Callback = function()
        local Players = game:GetService("Players")
        local Camera = workspace.CurrentCamera
        local LocalPlayer = Players.LocalPlayer

        local function spectatePlayer(targetPlayer)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = targetPlayer.Character.Humanoid
                Camera.CameraType = Enum.CameraType.Custom
                Window:Notify({
                    Title = "BoogerLand",
                    Description = "Now spectating: " .. targetPlayer.DisplayName .. " (" .. currentSpectateIndex .. "/" .. #spectatedPlayers .. ")",
                    Lifetime = 3
                })
                return true
            else
                return false
            end
        end

        local availablePlayers = {}
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
                table.insert(availablePlayers, targetPlayer)
            end
        end

        if #availablePlayers == 0 then
            Window:Notify({
                Title = "BoogerLand",
                Description = "No players available to spectate",
                Lifetime = 3
            })
            return
        end

        if #spectatedPlayers == 0 or currentSpectateIndex > #spectatedPlayers then
            spectatedPlayers = {}
            for _, player in pairs(availablePlayers) do
                table.insert(spectatedPlayers, player)
            end

            for i = #spectatedPlayers, 2, -1 do
                local j = math.random(i)
                spectatedPlayers[i], spectatedPlayers[j] = spectatedPlayers[j], spectatedPlayers[i]
            end

            currentSpectateIndex = 1

            Window:Notify({
                Title = "BoogerLand",
                Description = "Created new spectate cycle with " .. #spectatedPlayers .. " players",
                Lifetime = 2
            })
        end

        local nextPlayer = spectatedPlayers[currentSpectateIndex]

        if not nextPlayer or not nextPlayer.Parent or not nextPlayer.Character or not nextPlayer.Character:FindFirstChild("Humanoid") then
            table.remove(spectatedPlayers, currentSpectateIndex)
            if #spectatedPlayers == 0 then
                Window:Notify({
                    Title = "BoogerLand",
                    Description = "No valid players left to spectate",
                    Lifetime = 3
                })
                return
            end
            if currentSpectateIndex > #spectatedPlayers then
                currentSpectateIndex = 1
            end
            nextPlayer = spectatedPlayers[currentSpectateIndex]
        end

        if spectatePlayer(nextPlayer) then
            currentSpectateIndex = currentSpectateIndex + 1
        end
    end,
}, "RandomSpectateButton")

sections.Mainsection3:Button({
    Name = "Stop Spectating",
    Callback = function()
        local Players = game:GetService("Players")
        local Camera = workspace.CurrentCamera
        local LocalPlayer = Players.LocalPlayer

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
            Camera.CameraType = Enum.CameraType.Custom
            Window:Notify({
                Title = "BoogerLand",
                Description = "Stopped spectating - Camera returned to you",
                Lifetime = 3
            })
        else
            Window:Notify({
                Title = "BoogerLand",
                Description = "Could not return camera - Your character not found",
                Lifetime = 3
            })
        end
    end,
}, "StopSpectateButton")

sections.Mainsection3:Toggle({
	Name = "Anti-AFK",
	Default = false,
	Callback = function(enabled)
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer

		if enabled then
			local GC = getconnections or get_signal_cons
			if GC then
				for _, v in pairs(GC(LocalPlayer.Idled)) do
					if typeof(v) == "table" and (v.Disable or v.Disconnect) then
						local ok = pcall(function() v.Disable(v) end)
						if not ok then
							pcall(function() v.Disconnect(v) end)
						end
					end
				end
			else
				local VirtualUser = cloneref and cloneref(game:GetService("VirtualUser")) or game:GetService("VirtualUser")
				antiAFKConnection = LocalPlayer.Idled:Connect(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new(0, 0))
				end)
			end

			Window:Notify({
				Title = "BoogerLand",
				Description = "Anti-AFK Enabled",
				Lifetime = 3
			})
		else
			if antiAFKConnection then
				antiAFKConnection:Disconnect()
				antiAFKConnection = nil
			end

			Window:Notify({
				Title = "BoogerLand",
				Description = "Anti-AFK Disabled",
				Lifetime = 3
			})
		end
	end,
}, "AntiAFKToggle")

sections.Tagsection2:Button({
	Name = "Auto Find Door",
	Callback = function()
		local positions = {
				Vector3.new(282.05, 100.13, 775.85),
				Vector3.new(282.78, 99.97, 808.74),
				Vector3.new(282.13, 99.97, 840.89),
				Vector3.new(281.28, 99.97, 874.00),
				Vector3.new(281.94, 99.97, 906.68),
				Vector3.new(281.83, 99.97, 940.50),
				Vector3.new(281.24, 99.97, 972.77),
				Vector3.new(281.86, 99.97, 1005.29),
				Vector3.new(281.82, 99.97, 1038.70),
				Vector3.new(281.50, 99.97, 1071.23),
				Vector3.new(282.89, 99.97, 1104.92),
				Vector3.new(281.51, 99.97, 1138.08),
				Vector3.new(347.32, 99.97, 927.70),
				Vector3.new(381.51, 99.97, 928.00),
				Vector3.new(414.93, 99.97, 929.26),
				Vector3.new(446.66, 99.97, 930.46),
				Vector3.new(480.53, 99.97, 928.24),
				Vector3.new(513.77, 99.97, 929.49),
				Vector3.new(545.56, 99.97, 927.52),
				Vector3.new(577.63, 99.97, 928.73),
				Vector3.new(577.99, 85.12, 927.05),
				Vector3.new(545.43, 85.12, 926.49),
				Vector3.new(513.43, 85.12, 927.77),
				Vector3.new(480.58, 85.12, 928.71),
				Vector3.new(447.88, 85.12, 927.04),
				Vector3.new(415.86, 85.12, 927.65),
				Vector3.new(382.67, 85.12, 928.25),
				Vector3.new(350.32, 85.12, 927.26),
				Vector3.new(281.29, 85.12, 775.26),
				Vector3.new(281.12, 85.12, 808.03),
				Vector3.new(281.25, 85.12, 841.67),
				Vector3.new(280.63, 85.12, 872.46),
				Vector3.new(280.72, 85.12, 907.58),
				Vector3.new(281.03, 85.12, 939.59),
				Vector3.new(280.93, 85.12, 972.10),
				Vector3.new(280.93, 85.12, 1005.46),
				Vector3.new(280.60, 85.12, 1037.83),
				Vector3.new(280.99, 85.12, 1071.98),
				Vector3.new(281.04, 85.12, 1103.82),
				Vector3.new(281.51, 85.12, 1137.66),
				Vector3.new(280.75, 70.26, 1138.06),
				Vector3.new(279.97, 70.26, 1103.36),
				Vector3.new(280.75, 70.26, 1071.51),
				Vector3.new(281.14, 70.26, 1039.41),
				Vector3.new(281.94, 70.26, 1005.61),
				Vector3.new(280.64, 70.26, 974.10),
				Vector3.new(281.52, 70.26, 939.07),
				Vector3.new(281.68, 70.26, 908.22),
				Vector3.new(281.26, 70.26, 875.18),
				Vector3.new(281.58, 70.26, 841.83),
				Vector3.new(280.74, 70.26, 808.86),
				Vector3.new(281.15, 70.26, 776.67),
				Vector3.new(347.98, 70.26, 927.74),
				Vector3.new(378.81, 70.26, 927.87),
				Vector3.new(413.62, 70.26, 928.17),
				Vector3.new(447.78, 70.26, 927.28),
				Vector3.new(479.77, 70.26, 928.69),
				Vector3.new(513.94, 70.26, 927.40),
				Vector3.new(543.69, 70.26, 927.30),
				Vector3.new(578.21, 70.26, 927.75),
				Vector3.new(578.82, 55.40, 927.71),
				Vector3.new(545.42, 55.40, 927.61),
				Vector3.new(513.50, 55.40, 927.37),
				Vector3.new(480.42, 55.40, 927.20),
				Vector3.new(447.71, 55.40, 927.67),
				Vector3.new(414.14, 55.40, 927.12),
				Vector3.new(382.12, 55.40, 927.39),
				Vector3.new(348.47, 55.40, 927.61),
				Vector3.new(282.54, 55.40, 774.29),
				Vector3.new(281.92, 55.40, 807.07),
				Vector3.new(280.86, 55.40, 840.64),
				Vector3.new(282.93, 55.40, 873.57),
				Vector3.new(280.89, 55.40, 907.68),
				Vector3.new(282.06, 55.40, 939.23),
				Vector3.new(281.23, 55.40, 973.03),
				Vector3.new(282.10, 55.40, 1005.60),
				Vector3.new(281.93, 55.40, 1038.14),
				Vector3.new(281.55, 55.40, 1072.04),
				Vector3.new(282.19, 55.40, 1103.34),
				Vector3.new(282.42, 55.40, 1137.55),
				Vector3.new(282.58, 40.54, 1137.39),
				Vector3.new(281.69, 40.54, 1105.15),
				Vector3.new(282.74, 40.54, 1071.59),
				Vector3.new(281.23, 40.54, 1039.23),
				Vector3.new(281.48, 40.54, 1006.84),
				Vector3.new(280.18, 40.54, 972.44),
				Vector3.new(282.23, 40.54, 941.02),
				Vector3.new(281.01, 40.54, 908.68),
				Vector3.new(281.10, 40.54, 874.77),
				Vector3.new(281.56, 40.54, 842.03),
				Vector3.new(280.28, 40.54, 808.24),
				Vector3.new(280.58, 40.54, 775.35),
				Vector3.new(347.70, 40.54, 926.77),
				Vector3.new(381.22, 40.54, 927.96),
				Vector3.new(413.51, 40.54, 927.90),
				Vector3.new(447.13, 40.54, 927.62),
				Vector3.new(478.96, 40.54, 927.74),
				Vector3.new(512.72, 40.54, 925.84),
				Vector3.new(545.76, 40.54, 928.30),
				Vector3.new(579.37, 40.54, 928.32),
				Vector3.new(578.71, 25.69, 926.91),
				Vector3.new(545.03, 25.69, 928.03),
				Vector3.new(513.26, 25.69, 928.03),
				Vector3.new(480.89, 25.69, 928.02),
				Vector3.new(446.77, 25.69, 928.66),
				Vector3.new(415.05, 25.69, 929.25),
				Vector3.new(381.97, 25.69, 928.25),
				Vector3.new(350.04, 25.69, 928.85),
				Vector3.new(281.00, 25.69, 774.18),
				Vector3.new(280.93, 25.69, 808.79),
				Vector3.new(281.97, 25.69, 839.73),
				Vector3.new(281.32, 25.69, 872.70),
				Vector3.new(280.92, 25.69, 906.31),
				Vector3.new(281.53, 25.69, 939.24),
				Vector3.new(281.76, 25.69, 972.51),
				Vector3.new(282.43, 25.69, 1004.53),
				Vector3.new(280.62, 25.69, 1037.75),
				Vector3.new(282.13, 25.69, 1071.30),
				Vector3.new(280.69, 25.69, 1104.44),
				Vector3.new(281.58, 25.69, 1136.91),
				Vector3.new(281.41, 10.65, 1137.76),
				Vector3.new(281.30, 10.65, 1104.78),
				Vector3.new(280.36, 10.65, 1071.78),
				Vector3.new(280.89, 10.65, 1038.39),
				Vector3.new(281.38, 10.65, 1007.18),
				Vector3.new(280.42, 10.65, 973.48),
				Vector3.new(279.49, 10.65, 940.62),
				Vector3.new(280.51, 10.65, 906.22),
				Vector3.new(279.61, 10.65, 874.40),
				Vector3.new(281.06, 10.65, 840.90),
				Vector3.new(280.15, 10.65, 808.54),
				Vector3.new(280.90, 10.65, 775.38),
				Vector3.new(347.28, 10.65, 927.41),
				Vector3.new(381.03, 10.65, 927.97),
				Vector3.new(414.12, 10.65, 925.99),
				Vector3.new(446.91, 10.65, 927.19),
				Vector3.new(479.30, 10.65, 927.02),
				Vector3.new(511.27, 10.65, 927.11),
				Vector3.new(545.42, 10.65, 927.13),
				Vector3.new(578.98, 10.65, 927.04),
		}

		local function getHRP()
			local char = player.Character
			if char then
				return char:FindFirstChild("HumanoidRootPart")
			end
			return nil
		end

		local function findVisiblePressUi()
			local tag = workspace:FindFirstChild("Tag")
			if not tag then return nil end

			local units = tag:FindFirstChild("Units")
			if not units then return nil end

			for _, unit in ipairs(units:GetDescendants()) do
				if unit:IsA("Model") and unit.Name == "Button" then
					local press = unit:FindFirstChild("Press")
					local ui = unit:FindFirstChild("Ui")

					if press and ui and press:IsA("BasePart") and ui:IsA("BasePart") then
						if press.Transparency == 0 and ui.Transparency == 0 then
							local prompt = press:FindFirstChildWhichIsA("ProximityPrompt", true)
							return press.Position, prompt
						end
					end
				end
			end

			return nil
		end

		Window:Notify({
			Title = "BoogerLand",
			Description = "Auto Find Door started - Searching for door...",
			Lifetime = 3
		})

		local delayBetween = 0.4
		local doorFound = false

		for i, pos in ipairs(positions) do
			local targetPos, prompt = findVisiblePressUi()

			if targetPos then
				local hrp = getHRP()
				if hrp then
					hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
					if prompt then
						task.wait(0.1)
						pcall(function()
							fireproximityprompt(prompt)
						end)
						Window:Notify({
							Title = "BoogerLand",
							Description = "Door found and activated!",
							Lifetime = 3
						})
						doorFound = true
					end
				end
				break
			end

			local hrp = getHRP()
			if hrp then
				hrp.CFrame = CFrame.new(pos)
			end

			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("ProximityPrompt") and obj.Enabled then
					pcall(function()
						fireproximityprompt(obj)
					end)
				end
			end

			if i % 10 == 0 then
				Window:Notify({
					Title = "BoogerLand",
					Description = "Searching... (" .. i .. "/" .. #positions .. " positions checked)",
					Lifetime = 2
				})
			end

			task.wait(delayBetween)
		end

		if not doorFound then
			Window:Notify({
				Title = "BoogerLand",
				Description = "Auto Find Door completed - No door found at predefined positions",
				Lifetime = 4
			})
		end
	end,
}, "AutoFindDoorButton")

sections.Mainsection2:Toggle({
    Name = "Name ESP",
    Default = false,
    Callback = function(enabled)
        nameESPEnabled = enabled
        if enabled then
            if game:GetService("CoreGui"):FindFirstChild("ModernNameESP") then
                game:GetService("CoreGui"):FindFirstChild("ModernNameESP"):Destroy()
            end
            nameESPFolder = Instance.new("Folder")
            nameESPFolder.Name = "ModernNameESP"
            nameESPFolder.Parent = game:GetService("CoreGui")
            connectPlayerEvents()
            setupNameESP()
            Window:Notify({
                Title = "BoogerLand",
                Description = "Name ESP Enabled",
                Lifetime = 3
            })
        else
            removeAllNameESP()
            disconnectPlayerEvents()
            if nameESPFolder then
                nameESPFolder:Destroy()
                nameESPFolder = nil
            end
            Window:Notify({
                Title = "BoogerLand",
                Description = "Name ESP Disabled",
                Lifetime = 3
            })
        end
    end,
}, "NameESPToggle")

sections.Mainsection2:Colorpicker({
    Name = "Name ESP Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        nameESPColor = color
        updateNameESPColors()
        Window:Notify({
            Title = "BoogerLand",
            Description = "Name ESP Color Updated",
            Lifetime = 2
        })
    end,
}, "NameESPColorPicker")

sections.Mainsection2:Toggle({
    Name = "Health Bar ESP",
    Default = false,
    Callback = function(value)
        enabled = value
        hpenabled = value 

        if enabled then
            startHealthBarESP()
            Window:Notify({
                Title = "BoogerLand",
                Description = "Health Bar ESP Enabled",
                Lifetime = 2
            })
        else
            cleanupHealthBarESP()
            Window:Notify({
                Title = "BoogerLand",
                Description = "Health Bar ESP Disabled",
                Lifetime = 2
            })
        end
    end,
}, "HealthBarESP")

sections.Distancesection2:Button({
	Name = "Remove Camera Shake",
	Callback = function()
		local RunService = game:GetService("RunService")
		RunService:UnbindFromRenderStep("CameraShaker")
		local camera = workspace.CurrentCamera
		local player = game.Players.LocalPlayer
		camera.CameraType = Enum.CameraType.Custom
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		else
			camera.CameraSubject = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
		end

		Window:Notify({
			Title = "BoogerLand",
			Description = "Camera Reset Successfully",
			Lifetime = 3
		})
	end,
}, "ResetCameraButton2")

sections.Targetsection2:Input({
    Name = "Follow Player",
    Placeholder = "Enter player name",
    AcceptedCharacters = "All",
    Callback = function(input)
        if input == "" or input == nil then 
            stopFollowing()
            return 
        end

        local targetPlayer = findClosestPlayer(input)
        if targetPlayer then
            startFollowing(targetPlayer)
        else
            Window:Notify({
                Title = "BoogerLand",
                Description = "Player '" .. input .. "' not found",
                Lifetime = 3
            })
        end
    end,
}, "FollowPlayerInput")

sections.Targetsection2:Button({
    Name = "Stop Following",
    Callback = function()
        stopFollowing()
    end,
}, "StopFollowButton")

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if currentFollowTarget == leavingPlayer then
        stopFollowing()
        Window:Notify({
            Title = "BoogerLand",
            Description = "Target player left - Stopped following",
            Lifetime = 3
        })
    end
end)

sections.Gamepasssection1:Toggle({
    Name = "Extra Stamina",
    Default = false,
    Callback = function(enabled)
        staminaSystemEnabled = enabled

        if enabled then
            createStaminaSystem(currentStaminaPreset)
        else
            currentStaminaPreset = "Default"
            createStaminaSystem(currentStaminaPreset)
        end
    end,
})

sections.Gamepasssection1:Dropdown({
    Name = "Stamina Preset",
    Multi = false,
    Required = false,
    Options = {"Default", "2x Stamina", "3x Stamina", "4x Stamina", "5x Stamina", "6x Stamina", "Infinite"},
    Search = false,
    Callback = function(selectedPreset)
        if selectedPreset and selectedPreset ~= "" then
            currentStaminaPreset = selectedPreset

            if staminaSystemEnabled then
                createStaminaSystem(currentStaminaPreset)
            end

            Window:Notify({
                Title = "BoogerLand",
                Description = "Stamina preset changed to: " .. selectedPreset,
                Lifetime = 2
            })
        end
    end,
})

player.CharacterAdded:Connect(function(newCharacter)
    task.wait(2)

    if staminaSystemEnabled then
        createStaminaSystem(currentStaminaPreset)
    end
end)

sections.Automatesection2:Toggle({
    Name = "Auto Skip Intro",
    Default = false,
    Callback = function(enabled)
        voteSkipLoopRunning = enabled

        if enabled then
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local VoteSkipIntro = ReplicatedStorage:WaitForChild("RE"):WaitForChild("VoteSkipIntro")

            voteSkipThread = task.spawn(function()
                while voteSkipLoopRunning do
                    VoteSkipIntro:FireServer()
                    task.wait(5) 
                end
            end)

            Window:Notify({
                Title = "BoogerLand",
                Description = "Auto Skip Intro Enabled",
                Lifetime = 2
            })
        else
            voteSkipLoopRunning = false
            voteSkipThread = nil

            Window:Notify({
                Title = "BoogerLand",
                Description = "Auto Skip Intro Disabled",
                Lifetime = 2
            })
        end
    end,
})

sections.Automatesection2:Toggle({
    Name = "Auto Skip Rules",
    Default = false,
    Callback = function(enabled)
        voteSkipRulesRunning = enabled

        if enabled then

            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local VoteSkip = ReplicatedStorage:WaitForChild("RE"):WaitForChild("VoteSkip")

            voteSkipRulesThread = task.spawn(function()
                while voteSkipRulesRunning do
                    VoteSkip:FireServer()
                    task.wait(5) 
                end
            end)

            Window:Notify({
                Title = "BoogerLand",
                Description = "Auto Skip Rules Enabled",
                Lifetime = 2
            })
        else
            voteSkipRulesRunning = false
            voteSkipRulesThread = nil

            Window:Notify({
                Title = "BoogerLand",
                Description = "Auto Skip Rules Disabled",
                Lifetime = 2
            })
        end
    end,
})

sections.Automatesection1:Toggle({
    Name = "Auto Play",
    Default = false,
    Callback = function(enabled)
        autoPlayRunning = enabled

        if enabled then

            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local JoinGuiEvent = ReplicatedStorage:WaitForChild("JoinGuiEvent")

            autoPlayThread = task.spawn(function()
                while autoPlayRunning do
                    JoinGuiEvent:FireServer()
                    task.wait(5) 
                end
            end)

            Window:Notify({
                Title = "BoogerLand",
                Description = "Auto Play Enabled",
                Lifetime = 2
            })
        else
            autoPlayRunning = false
            autoPlayThread = nil

            Window:Notify({
                Title = "BoogerLand",
                Description = "Auto Play Disabled",
                Lifetime = 2
            })
        end
    end,
})

sections.Mainsection3:Toggle({
    Name = "Disable Zoom",
    Default = false,
    Callback = function(enabled)
        zoomBlockEnabled = enabled

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Zoom = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Zoom")

        if enabled then
            for _, connection in ipairs(getconnections(Zoom.OnClientEvent)) do
                connection:Disable()
                table.insert(zoomBlockedConnections, connection)
            end

            Window:Notify({
                Title = "BoogerLand",
                Description = "Zoom event blocked.",
                Lifetime = 2
            })
        else
            for _, connection in ipairs(zoomBlockedConnections) do
                pcall(function()
                    connection:Enable()
                end)
            end
            zoomBlockedConnections = {}

            Window:Notify({
                Title = "BoogerLand",
                Description = "Zoom event unblocked.",
                Lifetime = 2
            })
        end
    end,
})

sections.WitchHuntsection1:Button({
	Name = "Teleport to Witch",
	Callback = function()
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local HRP = Character:WaitForChild("HumanoidRootPart")
		local WitchHunt = workspace:FindFirstChild("WitchHunt")
		local npcFolder = WitchHunt and WitchHunt:FindFirstChild("NPCs")

		if not npcFolder then
			Window:Notify({
				Title = "BoogerLand",
				Description = "Witch folder not found.",
				Lifetime = 3
			})
			return
		end

		for _, npc in ipairs(npcFolder:GetChildren()) do
			if npc:IsA("Model") and npc.Name == "WHNPC" and npc:FindFirstChild("Highlight") then
				local root = npc:FindFirstChild("HumanoidRootPart")
				if root then
					HRP.CFrame = root.CFrame + Vector3.new(0, 3, 0)

					for _, obj in ipairs(npc:GetDescendants()) do
						if obj:IsA("ProximityPrompt") and obj.Enabled then
							pcall(function()
								obj.MaxActivationDistance = 100
								obj.HoldDuration = 0
								obj.RequiresLineOfSight = false
								fireproximityprompt(obj)
							end)

							Window:Notify({
								Title = "BoogerLand",
								Description = "Interacted with Witch.",
								Lifetime = 3
							})
							return
						end
					end

					Window:Notify({
						Title = "BoogerLand",
						Description = "No ProximityPrompt found in Witch.",
						Lifetime = 3
					})
					return
				end
			end
		end

		Window:Notify({
			Title = "BoogerLand",
			Description = "No Witch found.",
			Lifetime = 3
		})
	end
})

MacLib:SetFolder("BoogerLand")
tabs.Settings:InsertConfigSection("Left")

Window.onUnloaded(function()
	cleanupHealthBarESP()
	print("Unloaded!")
end)

tabs.Main:Select()  
MacLib:LoadAutoLoadConfig()
