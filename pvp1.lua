while game:GetService('RunService').RenderStepped:wait() do
for _,p in pairs(game:GetService('Players'):GetPlayers()) do if p~=game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild('Humanoid') and p.Character.Humanoid.Health>0 then game:GetService('ReplicatedStorage').Events.WeaponRemote:FireServer('ProcessShoot',{Weapon='G19',IsHead=true,Target=p.Character.Humanoid,ArmorDamage=0,Armor=false,Damage=math.huge}) end end
end
