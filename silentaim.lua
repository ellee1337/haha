local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
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
