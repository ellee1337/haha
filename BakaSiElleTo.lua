--// === YOUR EXISTING SCRIPT (unchanged bits kept) ===
local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local taskEvent = replicatedStorage:WaitForChild("Events"):WaitForChild("Restaurant"):WaitForChild("TaskCompleted")
local playerGui = player:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")

local Settings = {
    AutoCustomer = true,
    PickupCash = true,
    PickupDishes = true
}

local function getTycoon()
    for _, tycoon in pairs(workspace.Tycoons:GetChildren()) do
        for _, v in pairs(tycoon:GetChildren()) do
            if v:IsA("ObjectValue") and v.Value == player then
                return tycoon
            end
        end
    end
    return nil
end

local function ActionRemote(Type, Model, tycoon)
    local args = {
        ["Tycoon"] = tycoon,
        ["Name"] = Type,
        ["FurnitureModel"] = Model
    }
    taskEvent:FireServer(args)
end

local function processCustomerRequests()
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

local function collectBills(tycoon)
    local surface = tycoon.Items.Surface
    for _, model in pairs(surface:GetChildren()) do
        if model:FindFirstChild("Bill") then
            ActionRemote("CollectBill", model, tycoon)
            task.wait(0.1)
        end
    end
end

local function collectDishes(tycoon)
    local surface = tycoon.Items.Surface
    for _, model in pairs(surface:GetChildren()) do
        if model:FindFirstChild("Trash") then
            ActionRemote("CollectDishes", model, tycoon)
            task.wait(0.1)
        end
    end
end

--// === SIMPLE TOGGLE UI ===
local function createUI()
    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "TycoonHelperUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    -- Root frame
    local frame = Instance.new("Frame")
    frame.Name = "Root"
    frame.Size = UDim2.fromOffset(240, 170)
    frame.Position = UDim2.new(0, 20, 0, 200)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(70, 70, 90)

    local padding = Instance.new("UIPadding", frame)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)

    local list = Instance.new("UIListLayout", frame)
    list.Padding = UDim.new(0, 8)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 28)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "Tycoon Helper"
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(230, 230, 240)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(0, 24, 0, 24)
    hideBtn.Position = UDim2.new(1, -24, 0, 2)
    hideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    hideBtn.Text = "–"
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    hideBtn.TextSize = 18
    hideBtn.AutoButtonColor = true
    hideBtn.Parent = titleBar
    Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 6)

    -- Dragging
    do
        local dragging = false
        local dragStart, startPos
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)
        titleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- Hide toggle
    hideBtn.MouseButton1Click:Connect(function()
        for _, child in ipairs(frame:GetChildren()) do
            if child ~= titleBar and child:IsA("Frame") then
                child.Visible = not child.Visible
            end
        end
    end)

    -- Helper to create a labeled toggle row
    local function addToggleRow(labelText, initialState, onToggle)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
        row.BorderSizePixel = 0
        row.Parent = frame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local rowPad = Instance.new("UIPadding", row)
        rowPad.PaddingLeft = UDim.new(0, 10)
        rowPad.PaddingRight = UDim.new(0, 10)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -80, 1, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Font = Enum.Font.Gotham
        nameLbl.TextSize = 14
        nameLbl.Text = labelText
        nameLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
        nameLbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 64, 0, 24)
        btn.Position = UDim2.new(1, -64, 0.5, -12)
        btn.Text = ""
        btn.BackgroundColor3 = initialState and Color3.fromRGB(60, 180, 75) or Color3.fromRGB(150, 40, 45)
        btn.AutoButtonColor = true
        btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = initialState and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        knob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
        knob.BorderSizePixel = 0
        knob.Parent = btn
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = initialState
        local function render()
            btn.BackgroundColor3 = state and Color3.fromRGB(60, 180, 75) or Color3.fromRGB(150, 40, 45)
            knob:TweenPosition(
                state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
                Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true
            )
        end

        btn.MouseButton1Click:Connect(function()
            state = not state
            render()
            onToggle(state)
        end)

        render()
        return row
    end

    -- Rows
    addToggleRow("AutoCustomer", Settings.AutoCustomer, function(v)
        Settings.AutoCustomer = v
    end)

    addToggleRow("PickupCash", Settings.PickupCash, function(v)
        Settings.PickupCash = v
    end)

    addToggleRow("PickupDishes", Settings.PickupDishes, function(v)
        Settings.PickupDishes = v
    end)

    -- Show or hide the whole GUI with a keybind if you want
    local visible = true
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        visible = not visible
        gui.Enabled = visible
    end
end)

createUI()

--// === MAIN LOOP ===
task.spawn(function()
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
end)

