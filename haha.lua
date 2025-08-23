local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local taskEvent = replicatedStorage:WaitForChild("Events"):WaitForChild("Restaurant"):WaitForChild("TaskCompleted")
local playerGui = player:WaitForChild("PlayerGui")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

Players.LocalPlayer.Idled:Connect(function()
    -- This prevents Roblox from auto-kicking your own players for idling
    -- Useful if you want to manage AFK behavior yourself
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)


local Settings = {
    AutoCustomer = true,
    PickupCash = true,
    PickupDishes = true
}

local getTycoon = function()
    for _, tycoon in pairs(workspace.Tycoons:GetChildren()) do
        for _, v in pairs(tycoon:GetChildren()) do
            if v:IsA("ObjectValue") and v.Value == player then
                return tycoon
            end
        end
    end
    return nil
end

local ActionRemote = function(Type, Model, tycoon)
    local args = {
        ["Tycoon"] = tycoon,
        ["Name"] = Type,
        ["FurnitureModel"] = Model
    }
    taskEvent:FireServer(args)
end

local processCustomerRequests = function()
    local tycoon = getTycoon()
    if not tycoon then return end

    local surface = tycoon.Items.Surface
    local tables = {}
    for _, model in pairs(surface:GetChildren()) do
        if model.Name:match("^T%d+$") then
            table.insert(tables, model)
        end
    end

    for _, ui in pairs(playerGui:GetChildren()) do
        if ui.Name == "CustomerSpeechUI" and ui.Adornee then
            for _, desc in pairs(ui:GetDescendants()) do
                if desc.Name == "Header" and desc:IsA("TextLabel") then
                    local groupSize = tonumber(string.match(desc.Text, "A table for (%d+), please%."))
                    if groupSize then
                        local customerModel = ui.Adornee:FindFirstAncestorOfClass("Model")
                        if customerModel then
                            for _, tableModel in pairs(tables) do
                                taskEvent:FireServer({
                                    ["FurnitureModel"] = tableModel,
                                    ["Tycoon"] = tycoon,
                                    ["Name"] = "SendToTable",
                                    ["GroupId"] = customerModel.Parent.Name
                                })
                            end
                        end
                    end
                end
            end
        end
    end
end

local collectBills = function(tycoon)
    local surface = tycoon.Items.Surface
    for _, model in pairs(surface:GetChildren()) do
        if model:FindFirstChild("Bill") then
            ActionRemote("CollectBill", model, tycoon)
            task.wait(0.1)
        end
    end
end

local collectDishes = function(tycoon)
    local surface = tycoon.Items.Surface
    for _, model in pairs(surface:GetChildren()) do
        if model:FindFirstChild("Trash") then
            ActionRemote("CollectDishes", model, tycoon)
            task.wait(0.1)
        end
    end
end

coroutine.wrap(function()
    while true do
        local tycoon = getTycoon()
        if tycoon then
            if Settings.AutoCustomer then
                processCustomerRequests()
            end
            if Settings.PickupCash then
                collectBills(tycoon)
            end
            if Settings.PickupDishes then
                collectDishes(tycoon)
            end
        else
            warn("Could not find your tycoon")
        end
        task.wait(1)
    end
end)()
