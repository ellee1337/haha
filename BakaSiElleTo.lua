-- Carrega a Ghost GUI
loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/UI-Library/refs/heads/main/Ghost%20Gui'))()

-- Espera a interface carregar e altera o título
local gui = game.CoreGui:WaitForChild("GhostGui")
gui.MainFrame.Title.Text = "Mini City Tycoon"

-- Botão: Max Level
AddContent("TextButton", "Max Level", [[
    local currentFileValue = game:GetService("Players").LocalPlayer.CurrentFile.Value
    game:GetService("Players").LocalPlayer.Data.Files[tostring(currentFileValue)].Level.Value = 20
]])

-- Botão: Free VIP
AddContent("TextButton", "Free VIP", [[
    game:GetService("Players").LocalPlayer.Data.Passes.Pass_VIP.Value = true
]])

-- Botão: Get All Passes
AddContent("TextButton", "Get Passes", [[
    local passes = game:GetService("Players").LocalPlayer.Data.Passes
    passes.Pass_X2Level.Value = true
    passes.Pass_X2Cash.Value = true
    passes.Pass_Paint.Value = true
    passes.Pass_MoreHeight.Value = true
    passes.Pass_DisableGrid.Value = true
    passes.Pass_DisableCollision.Value = true
]])

-- Toggle: Sempre Dia
AddContent("Toogle", "Sempre Dia", [[
    getgenv().SempreDia = true
    while getgenv().SempreDia do
        game.Lighting.ClockTime = 6
        task.wait(1)
    end
]], [[
    getgenv().SempreDia = false
    game.Lighting.ClockTime = 20
]])

-- Botão: +100 Money
AddContent("TextButton", "+999999999 Money", [[
    local player = game:GetService("Players").LocalPlayer
    local data = player.Data.Files[tostring(player.CurrentFile.Value)]
    data.Cash.Value = data.Cash.Value + (999999999 * 1) -- multiplica o valor normal por 100
]])

-- Texto fixo embaixo
local TextLabel = AddContent("TextLabel")
TextLabel.Text = "ELLE"
